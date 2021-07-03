#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define ROTL64(x, y)			(((x) << (y)) | ((x) >> (64 - (y))))

#define SKEIN_KS_PARITY			0x5555555555555555ULL

const uint64_t SKEIN1024_IV[16] =
{
	0x5A4352BE62092156ULL, 0x5F6E8B1A72F001CAULL, 0xFFCBFE9CA1A2CE26ULL, 0x6C23C39667038BCAULL,
	0x583A8BFCCE34EB6CULL, 0x3FDBFB11D4A46A3EULL, 0x3304ACFCA8300998ULL, 0xB2F6675FA17F0FD2ULL,
	0x9D2599730EF7AB6BULL, 0x0914A20D3DFEA9E4ULL, 0xCC1A9CAFA494DBD3ULL, 0x9828030DA0A6388CULL,
	0x0D339D5DAADEE3DCULL, 0xFC46DE35C4E2A086ULL, 0x53D6E4F52E19A6D1ULL, 0x5663952F715D1DDDULL
};

const uint64_t keccakf_rnd_consts[24] = 
{
    0x0000000000000001ULL, 0x0000000000008082ULL, 0x800000000000808AULL,
    0x8000000080008000ULL, 0x000000000000808BULL, 0x0000000080000001ULL,
    0x8000000080008081ULL, 0x8000000000008009ULL, 0x000000000000008AULL,
    0x0000000000000088ULL, 0x0000000080008009ULL, 0x000000008000000AULL,
    0x000000008000808BULL, 0x800000000000008BULL, 0x8000000000008089ULL,
    0x8000000000008003ULL, 0x8000000000008002ULL, 0x8000000000000080ULL, 
    0x000000000000800AULL, 0x800000008000000AULL, 0x8000000080008081ULL,
    0x8000000000008080ULL, 0x0000000080000001ULL, 0x8000000080008008ULL
};

//#define SKEIN_INJECT_KEY(p, s)	do { \
	p += h; \
	p.sd += t[(s) % 3]; \
	p.se += t[((s) + 1) % 3]; \
	p.sf += (s); \
} while(0)

void DumpQwords(void *data, int len)
{
	putchar('\n');
	for(int i = 0; i < len; ++i)
	{
		if(!(i & 3) && i) printf("0x%016llX,\n", ((uint64_t *)data)[i]);
		else if(i == (len - 1)) printf("0x%016llX\n\n", ((uint64_t *)data)[i]);
		else printf("0x%016llX, ", ((uint64_t *)data)[i]);
	}
}

void DumpVerilogStyle(void *data, int len)
{
	printf("%d'h", len << 3);
	
	for(int i = len - 1; i >= 0; --i) printf("%02X", ((uint8_t *)data)[i]);
	printf("\n");
}

static void RotateSkeinKey(uint64_t *h)
{
	uint64_t tmp = h[0];

	for(int i = 0; i < 16; ++i) h[i] = h[i + 1];

	h[16] = tmp;
}

void SkeinInjectKey(uint64_t *p, const uint64_t *h, const uint64_t *t, int s)
{
	for(int i = 0; i < 16; ++i) p[i] += h[i];

	p[13] += t[s % 3];
	p[14] += t[(s + 1) % 3];
	p[15] += s;
}

void SkeinMix8(uint64_t *pv0, uint64_t *pv1, const uint32_t rc0, const uint32_t rc1, const uint32_t rc2, const uint32_t rc3, const uint32_t rc4, const uint32_t rc5, const uint32_t rc6, const uint32_t rc7)
{
	uint64_t Temp[8];
	
	for(int i = 0; i < 8; ++i) pv0[i] += pv1[i];
		
	pv1[0] = ROTL64(pv1[0], rc0);
	pv1[1] = ROTL64(pv1[1], rc1);
	pv1[2] = ROTL64(pv1[2], rc2);
	pv1[3] = ROTL64(pv1[3], rc3);
	pv1[4] = ROTL64(pv1[4], rc4);
	pv1[5] = ROTL64(pv1[5], rc5);
	pv1[6] = ROTL64(pv1[6], rc6);
	pv1[7] = ROTL64(pv1[7], rc7);
	
	for(int i = 0; i < 8; ++i) pv1[i] ^= pv0[i];
	
	memcpy(Temp, pv0, 64);
	
	pv0[0] = Temp[0];
	pv0[1] = Temp[1];
	pv0[2] = Temp[3];
	pv0[3] = Temp[2];
	pv0[4] = Temp[5];
	pv0[5] = Temp[6];
	pv0[6] = Temp[7];
	pv0[7] = Temp[4];
	
	memcpy(Temp, pv1, 64);

	pv1[0] = Temp[4];
	pv1[1] = Temp[6];
	pv1[2] = Temp[5];
	pv1[3] = Temp[7];
	pv1[4] = Temp[3];
	pv1[5] = Temp[1];
	pv1[6] = Temp[2];
	pv1[7] = Temp[0];
}

void SkeinEvenRound(uint64_t *p)
{
	uint64_t pv0[8], pv1[8];

	for(int i = 0; i < 16; i++)
	{
		if(i & 1) pv1[i >> 1] = p[i];
		else pv0[i >> 1] = p[i];
	}	
	
	SkeinMix8(pv0, pv1, 55, 43, 37, 40, 16, 22, 38, 12);
	
	SkeinMix8(pv0, pv1, 25, 25, 46, 13, 14, 13, 52, 57);
	
	SkeinMix8(pv0, pv1, 33, 8, 18, 57, 21, 12, 32, 54);
	
	SkeinMix8(pv0, pv1, 34, 43, 25, 60, 44, 9, 59, 34);
	
	for(int i = 0; i < 16; ++i)
	{
		if(i & 1) p[i] = pv1[i >> 1];
		else p[i] = pv0[i >> 1];
	}
}

void SkeinOddRound(uint64_t *p)
{
	uint64_t pv0[8], pv1[8];

	for(int i = 0; i < 16; i++)
	{
		if(i & 1) pv1[i >> 1] = p[i];
		else pv0[i >> 1] = p[i];
	}
	
	SkeinMix8(pv0, pv1, 28, 7, 47, 48, 51, 9, 35, 41);
	
	SkeinMix8(pv0, pv1, 17, 6, 18, 25, 43, 42, 40, 15);
	
	SkeinMix8(pv0, pv1, 58, 7, 32, 45, 19, 18, 2, 56);
	
	SkeinMix8(pv0, pv1, 47, 49, 27, 58, 37, 48, 53, 56);
	
	for(int i = 0; i < 16; ++i)
	{
		if(i & 1) p[i] = pv1[i >> 1];
		else p[i] = pv0[i >> 1];
	}
}

void SkeinRoundTest(uint64_t *State, uint64_t *Key, uint64_t *Type)
{
	//uint64_t StateBak[16];

	//memcpy(StateBak, State, 128);
	
	for(int i = 0; i < 20; i += 2)
	{
		SkeinInjectKey(State, Key, Type, i);
		
		//printf("\nState after key injection %d:\n", i);
		//DumpVerilogStyle(State, 128);
		
		SkeinEvenRound(State);
		RotateSkeinKey(Key);

		//printf("\nState after round %d:\n", i);
		//DumpVerilogStyle(State, 128);

		//printf("\nKey after rotation:\n");
		//DumpVerilogStyle(Key, 136);
		
		SkeinInjectKey(State, Key, Type, i + 1);
		
		//printf("\nState after key injection %d:\n", i + 1);
		//DumpVerilogStyle(State, 128);
		
		SkeinOddRound(State);
		RotateSkeinKey(Key);

		//printf("\nState after round %d:\n", i + 1);
		//DumpVerilogStyle(State, 128);

		//printf("\nKey after rotation:\n");
		//DumpVerilogStyle(Key, 136);
	}

	SkeinInjectKey(State, Key, Type, 20);

	//for(int i = 0; i < 16; ++i) State[i] ^= StateBak[i];
	
	// I am cheap and dirty. x.x
	RotateSkeinKey(Key);
	RotateSkeinKey(Key);
	RotateSkeinKey(Key);
	RotateSkeinKey(Key);
	RotateSkeinKey(Key);
}

void NXSMidstate(uint64_t *OutputKey, uint64_t *Input)
{
	uint64_t h[17], p[16], t[3];

	memcpy(p, Input, 128);
	memcpy(h, SKEIN1024_IV, 128);
	
	h[16] = SKEIN_KS_PARITY;
	for(int i = 0; i < 16; ++i) h[16] ^= h[i];
		
	t[0] = 0x80ULL;
	t[1] = 0x7000000000000000ULL;
	t[2] = 0x7000000000000080ULL;

	SkeinRoundTest(p, h, t);

	h[16] = SKEIN_KS_PARITY;
	for(int i = 0; i < 16; ++i)
	{
		h[i] = Input[i] ^ p[i];
		h[16] ^= h[i];
	}
	
	printf("Key output (after midstate, the feed-forward data for Skein-1024):\n");
	DumpQwords(h, 17);
	DumpVerilogStyle(h, 136);
	
	memcpy(OutputKey, h, 136);
}

void keccakf(uint64_t *st)
{
    for(int i = 0; i < 24; ++i) 
    {
		uint64_t bc[5], tmp;
		
		bc[0] = st[4] ^ st[9] ^ st[14] ^ st[19] ^ st[24] ^ ROTL64(st[1] ^ st[6] ^ st[11] ^ st[16] ^ st[21], 1); 
		bc[1] = st[0] ^ st[5] ^ st[10] ^ st[15] ^ st[20] ^ ROTL64(st[2] ^ st[7] ^ st[12] ^ st[17] ^ st[22], 1); 
		bc[2] = st[1] ^ st[6] ^ st[11] ^ st[16] ^ st[21] ^ ROTL64(st[3] ^ st[8] ^ st[13] ^ st[18] ^ st[23], 1); 
		bc[3] = st[2] ^ st[7] ^ st[12] ^ st[17] ^ st[22] ^ ROTL64(st[4] ^ st[9] ^ st[14] ^ st[19] ^ st[24], 1); 
		bc[4] = st[3] ^ st[8] ^ st[13] ^ st[18] ^ st[23] ^ ROTL64(st[0] ^ st[5] ^ st[10] ^ st[15] ^ st[20], 1); 
		st[0] ^= bc[0]; 
		
		tmp = ROTL64(st[ 1] ^ bc[1], 1); 
		st[ 1] = ROTL64(st[ 6] ^ bc[1], 44); 
		st[ 6] = ROTL64(st[ 9] ^ bc[4], 20); 
		st[ 9] = ROTL64(st[22] ^ bc[2], 61); 
		st[22] = ROTL64(st[14] ^ bc[4], 39); 
		st[14] = ROTL64(st[20] ^ bc[0], 18); 
		st[20] = ROTL64(st[ 2] ^ bc[2], 62); 
		st[ 2] = ROTL64(st[12] ^ bc[2], 43); 
		st[12] = ROTL64(st[13] ^ bc[3], 25); 
		st[13] = ROTL64(st[19] ^ bc[4],  8); 
		st[19] = ROTL64(st[23] ^ bc[3], 56); 
		st[23] = ROTL64(st[15] ^ bc[0], 41); 
		st[15] = ROTL64(st[ 4] ^ bc[4], 27); 
		st[ 4] = ROTL64(st[24] ^ bc[4], 14); 
		st[24] = ROTL64(st[21] ^ bc[1],  2); 
		st[21] = ROTL64(st[ 8] ^ bc[3], 55); 
		st[ 8] = ROTL64(st[16] ^ bc[1], 45); 
		st[16] = ROTL64(st[ 5] ^ bc[0], 36); 
		st[ 5] = ROTL64(st[ 3] ^ bc[3], 28); 
		st[ 3] = ROTL64(st[18] ^ bc[3], 21); 
		st[18] = ROTL64(st[17] ^ bc[2], 15); 
		st[17] = ROTL64(st[11] ^ bc[1], 10); 
		st[11] = ROTL64(st[ 7] ^ bc[2],  6); 
		st[ 7] = ROTL64(st[10] ^ bc[0],  3); 
		st[10] = tmp; 
		
		bc[0] = st[ 0]; bc[1] = st[ 1]; st[ 0] ^= (~bc[1]) & st[ 2]; st[ 1] ^= (~st[ 2]) & st[ 3]; st[ 2] ^= (~st[ 3]) & st[ 4]; st[ 3] ^= (~st[ 4]) & bc[0]; st[ 4] ^= (~bc[0]) & bc[1]; 
		bc[0] = st[ 5]; bc[1] = st[ 6]; st[ 5] ^= (~bc[1]) & st[ 7]; st[ 6] ^= (~st[ 7]) & st[ 8]; st[ 7] ^= (~st[ 8]) & st[ 9]; st[ 8] ^= (~st[ 9]) & bc[0]; st[ 9] ^= (~bc[0]) & bc[1]; 
		bc[0] = st[10]; bc[1] = st[11]; st[10] ^= (~bc[1]) & st[12]; st[11] ^= (~st[12]) & st[13]; st[12] ^= (~st[13]) & st[14]; st[13] ^= (~st[14]) & bc[0]; st[14] ^= (~bc[0]) & bc[1]; 
		bc[0] = st[15]; bc[1] = st[16]; st[15] ^= (~bc[1]) & st[17]; st[16] ^= (~st[17]) & st[18]; st[17] ^= (~st[18]) & st[19]; st[18] ^= (~st[19]) & bc[0]; st[19] ^= (~bc[0]) & bc[1]; 
		bc[0] = st[20]; bc[1] = st[21]; st[20] ^= (~bc[1]) & st[22]; st[21] ^= (~st[22]) & st[23]; st[22] ^= (~st[23]) & st[24]; st[23] ^= (~st[24]) & bc[0]; st[24] ^= (~bc[0]) & bc[1]; 
		
		st[0] ^= keccakf_rnd_consts[i];

		//printf("\nState after round %d:\n", i);
		//DumpVerilogStyle(st, 200);
    }
}

#if TEST_VECTOR_0

#define GOLDEN_NONCE	0x00000001FCAFC045ULL

// Nonce: 0x00000001FCAFC045ULL
uint64_t NXSTestHeader[27] =
{
	0x27B654ED00000008, 0xEE1D76908B505DD8, 0x9C802A52F6DF8AE4, 0xBE8C37115DD10DC7, 0xA79AB7E9CE491C06, 0x7C3CDDB70ABBC413, 0x9803FEB0767BD078, 0x55B423CB6D5631C8, 
	0x4696F99671448C1D, 0xC5189959FCA6F28D, 0xE6DC9BA87FDF6999, 0x1C30A6B7908A2A56, 0xBF2B59262FA90644, 0xF50E8C60F82604BC, 0x9516C15DABF27CF5, 0x7E2AF50CCE5C74DD, 
	0xDBCD6FE21B65A290, 0x06DF1973D1E4438E, 0x5BBED36C31570239, 0xE4A0A20A3C343BA8, 0x159BF93BBD8FDE57, 0xC63E601430361FFA, 0x0F3F29B6F456862D, 0xDB09CB623352A916, 
	0x00000002BD97BE01, 0x7B01B1D000396D8D,
};

#elif TEST_VECTOR_1

#define GOLDEN_NONCE	0x00000000F47E50BBULL

// Nonce: 0x00000000F47E50BBULL
uint64_t NXSTestHeader[27] = 
{
	0xD18BD55600000008, 0x23AB36A91E04F3A0, 0x308629D33FD47B4A, 0x1EEFAE6B94D2A54F, 0x3344F9271BCEFB8A, 0x574728BB67B1F6BC, 0xBF5304FF7FC3C1A4, 0xB33B017BFA70662A, 
	0x84E03BE35000DD1D, 0x6E06C1906D0E607D, 0xE2929BA3434B7D55, 0x1CDCBCAA9C0AB6B0, 0x1ED50C0CE9F8D5BA, 0xBF8206D84A3C2463, 0x14D8330913D3714C, 0xBCACDC96E4E7CF76, 
	0x7224C9DB9962DE4A, 0xC2B6932362B2DEC3, 0x4FAB9ED74B6F88BA, 0xD2DB7DBCFE48C9B5, 0x7FD20095605328DF, 0x59CE252AAE4C27C7, 0x5875ACE967E201DC, 0x330C69BF1B3622EB, 
	0x00000002BE8DBF01, 0x7B0185E20039AB81
};

#elif TEST_VECTOR_2

#define GOLDEN_NONCE	(0x00000000BF4BFC8D)

// Nonce: 0x00000000BF4BFC8D
uint64_t NXSTestHeader[27] =
{
0x6335AEBC00000008, 0x0E97CD887835D1E1, 0xCFF37637F74890D9, 0x07EC3DE882904C19, 0xF5619A30A6871911,
0x1BF566FEBB8D8FA4, 0x67B215B0BC43A1AD, 0x800AC235C1517A66, 0x1F1DE6E7E0F26AAC,
0x4F1BF7AC5FDB3C5F, 0x49FB7D47ABE36062, 0x8A5906F7338700D6, 0x185924760EB28AF2,
0x0FD5B9EC3E6F8167, 0x2DCE86EF76441038, 0xBE23CF655F6C8ABC, 0x8E5DD3BCAB6C29B1,
0xD1DFEF9B893F6475, 0x3FDF6A79D00C9716, 0x842E4F79D5E3B64E, 0xFA2C970BFE862F23,
0xC3CA4AF73091AD4A, 0x1A5610EFAD835952, 0x971D06C682CAA3BE, 0x000000027F4E4F63,
0x7B021F660039B10E
};

#else

#define GOLDEN_NONCE	0x0000000

uint64_t NXSTestHeader[27] =
{
	0x731931AA00000008, 0xE3347838B2DBEA77, 0xBE0E0EE6337598CB, 0x3315588381980036, 0xD5843C4C57A3D9F3,
	0xD7AF26349C6FAA84, 0x4FB26D7020E949AC, 0xF282A94CB59DFA3D, 0x4F4E481B97ACAF18,
	0x1074FE382FF19776, 0xA19343E4DDED3DAC, 0xA9B155EB50322806, 0xA96A02FD4D8DAA9E,
	0x48FF844AD189F0EA, 0xE5E6E0E0DA66CCD0, 0xCC700BFF075B770E, 0x0806F54DDC30368C,
	0x2A4CC92C24179BD1, 0x9E794B9D07D4B5C2, 0x13CC229EAD95482D, 0xC1C13655F218E219,
	0xF441802DF0B7C25B, 0x772FFCCCF78CDCED, 0x80879DB9BA67BCC6, 0x0000000201D4A3AA,
	0x7B01E8A3003A9D9B
};
	

#endif

uint64_t DoNXSTest(const uint64_t *State, const uint64_t *InKey, uint64_t Nonce)
{
	uint64_t Type[3], P[16], Key[17];
	
	((uint64_t *)Type)[0] = 0xD8ULL;
	((uint64_t *)Type)[1] = 0xB000000000000000ULL;
	((uint64_t *)Type)[2] = 0xB0000000000000D8ULL;
	
	// loads low 8 qwords
	// remember that we skip past the old data already processed
	// during the midstate - see vload8(2, uMessage) in ref OCL.
	memcpy(P, State + 16, 64);
	
	// Copy key, it must be const!
	for(int i = 0; i < 17; ++i)
		Key[i] = InKey[i];
	
	P[8] = State[24];
	P[9] = State[25];
	P[10] = Nonce;
	
	for(int i = 11; i < 16; ++i) P[i] = 0ULL;
	
	printf("State before Skein block:\n");
	DumpQwords(P, 16);
	DumpVerilogStyle(P, 128);
	
	printf("Key before Skein block:\n");
	DumpQwords(Key, 16);
	DumpVerilogStyle(P, 128);
	
	SkeinRoundTest(P, Key, Type);
	
	printf("\nResult after full Skein block process #2:\n");
	DumpQwords(P, 16);
	DumpVerilogStyle(P, 128);
	
	for(int i = 0; i < 8; ++i) Key[i] = P[i] ^ State[16 + i];
	
	Key[8] = P[8] ^ State[24];
	Key[9] = P[9] ^ State[25];
	Key[10] = P[10] ^ Nonce;
	
	for(int i = 11; i < 16; ++i) Key[i] = P[i];
	
	// Clear P, the state argument to the final block is zero.
	memset(P, 0x00, 128);
	((uint64_t *)Key)[16] = SKEIN_KS_PARITY;
	for(int i = 0; i < 16; ++i) ((uint64_t *)Key)[16] ^= ((uint64_t *)Key)[i];
	
	((uint64_t *)Type)[0] = 0x08ULL;
	((uint64_t *)Type)[1] = 0xFF00000000000000ULL;
	((uint64_t *)Type)[2] = 0xFF00000000000008ULL;

	SkeinRoundTest(P, Key, Type);
	
	printf("\nResult after full Skein block process #3:\n");
	DumpQwords(P, 16);
	DumpVerilogStyle(P, 128);
	
	uint64_t KeccakState[25];

	memset(KeccakState, 0x00, 200);
	
	// Copying qwords 0 - 8 (inclusive, so 9 qwords).
	// Note this is technically an XOR operation, just
	// with zero in this instance.
	memcpy(KeccakState, P, 72);
	
	keccakf(KeccakState);
	
	for(int i = 0; i < 7; ++i)	KeccakState[i] ^= ((uint64_t *)P)[i + 9];

	KeccakState[7] ^= 0x0000000000000005ULL;
	KeccakState[8] ^= 0x8000000000000000ULL;
	
	keccakf(KeccakState);

	keccakf(KeccakState);
	
	return(KeccakState[6]);
}

int main()
{
	uint64_t State[27], Key[17];
	
	memcpy(State, NXSTestHeader, 216);
	
	printf("Block input (after midstate, the remainder of the data to be hashed):\n");
	DumpQwords(State + 16, 10);
	DumpVerilogStyle(State + 16, 80);
	
	NXSMidstate(Key, State);
	
	printf("Key output:\n");
	DumpQwords(Key, 17);
	DumpVerilogStyle(Key, 136);
	
	printf("Test vector input:\n");
	DumpQwords(State + 16, 16);
	DumpVerilogStyle(State, 128);

	printf("Test key input:\n");
	DumpQwords(Key, 17);
	DumpVerilogStyle(Key, 136);
	
	uint64_t res = DoNXSTest(State, Key, GOLDEN_NONCE);
	
	printf("Output qword: 0x%016llX\n", res);
	
	return(0);
}
