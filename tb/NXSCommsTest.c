#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <stdbool.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/select.h>

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

#define ROL64(x, y)		(((x) << (y)) | ((x) >> (64 - (y))))

static void Round1024_host(uint64_t *p0, uint64_t *p1, uint64_t *p2, uint64_t *p3, uint64_t *p4, uint64_t *p5, uint64_t *p6, uint64_t *p7,
	uint64_t *p8, uint64_t *p9, uint64_t *pA, uint64_t *pB, uint64_t *pC, uint64_t *pD, uint64_t *pE, uint64_t *pF, int ROT)
{

	static const int cpu_ROT1024[8][8] =
	{
		{ 55, 43, 37, 40, 16, 22, 38, 12 },
		{ 25, 25, 46, 13, 14, 13, 52, 57 },
		{ 33, 8, 18, 57, 21, 12, 32, 54 },
		{ 34, 43, 25, 60, 44, 9, 59, 34 },
		{ 28, 7, 47, 48, 51, 9, 35, 41 },
		{ 17, 6, 18, 25, 43, 42, 40, 15 },
		{ 58, 7, 32, 45, 19, 18, 2, 56 },
		{ 47, 49, 27, 58, 37, 48, 53, 56 }
	};



	*p0 += *p1;
	*p1 = ROL64(*p1, cpu_ROT1024[ROT][0]);
	*p1 ^= *p0;
	*p2 += *p3;
	*p3 = ROL64(*p3, cpu_ROT1024[ROT][1]);
	*p3 ^= *p2;
	*p4 += *p5;
	*p5 = ROL64(*p5, cpu_ROT1024[ROT][2]);
	*p5 ^= *p4;
	*p6 += *p7;
	*p7 = ROL64(*p7, cpu_ROT1024[ROT][3]);
	*p7 ^= *p6;
	*p8 += *p9;
	*p9 = ROL64(*p9, cpu_ROT1024[ROT][4]);
	*p9 ^= *p8;
	*pA += *pB;
	*pB = ROL64(*pB, cpu_ROT1024[ROT][5]);
	*pB ^= *pA;
	*pC += *pD;
	*pD = ROL64(*pD, cpu_ROT1024[ROT][6]);
	*pD ^= *pC;
	*pE += *pF;
	*pF = ROL64(*pF, cpu_ROT1024[ROT][7]);
	*pF ^= *pE;
}

void SkeinFirstRound(unsigned int *pData, unsigned long long* skeinC)
{
/// first round of skein performed on cpu ==> constant on gpu

	static const uint64_t cpu_SKEIN1024_IV_1024[16] =
	{
		//     lo           hi
		0x5A4352BE62092156,
		0x5F6E8B1A72F001CA,
		0xFFCBFE9CA1A2CE26,
		0x6C23C39667038BCA,
		0x583A8BFCCE34EB6C,
		0x3FDBFB11D4A46A3E,
		0x3304ACFCA8300998,
		0xB2F6675FA17F0FD2,
		0x9D2599730EF7AB6B,
		0x0914A20D3DFEA9E4,
		0xCC1A9CAFA494DBD3,
		0x9828030DA0A6388C,
		0x0D339D5DAADEE3DC,
		0xFC46DE35C4E2A086,
		0x53D6E4F52E19A6D1,
		0x5663952F715D1DDD,
	};
	
	uint64_t t[3];
	uint64_t h[17];
	uint64_t p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15;

	uint64_t cpu_skein_ks_parity = 0x5555555555555555;
	h[16] = cpu_skein_ks_parity;
	for (int i = 0; i<16; i++) {
		h[i] = cpu_SKEIN1024_IV_1024[i];
		h[16] ^= h[i];
	}
	uint64_t* alt_data = (uint64_t*)pData;
	/////////////////////// round 1 //////////////////////////// should be on cpu => constant on gpu
	p0 = alt_data[0];
	p1 = alt_data[1];
	p2 = alt_data[2];
	p3 = alt_data[3];
	p4 = alt_data[4];
	p5 = alt_data[5];
	p6 = alt_data[6];
	p7 = alt_data[7];
	p8 = alt_data[8];
	p9 = alt_data[9];
	p10 = alt_data[10];
	p11 = alt_data[11];
	p12 = alt_data[12];
	p13 = alt_data[13];
	p14 = alt_data[14];
	p15 = alt_data[15];
	t[0] = 0x80; // ptr  
	t[1] = 0x7000000000000000; // etype
	t[2] = 0x7000000000000080;

	p0 += h[0];
	p1 += h[1];
	p2 += h[2];
	p3 += h[3];
	p4 += h[4];
	p5 += h[5];
	p6 += h[6];
	p7 += h[7];
	p8 += h[8];
	p9 += h[9];
	p10 += h[10];
	p11 += h[11];
	p12 += h[12];
	p13 += h[13] + t[0];
	p14 += h[14] + t[1];
	p15 += h[15];

	for (int i = 1; i < 21; i += 2)
	{

		Round1024_host(&p0, &p1, &p2, &p3, &p4, &p5, &p6, &p7, &p8, &p9, &p10, &p11, &p12, &p13, &p14, &p15, 0);
		Round1024_host(&p0, &p9, &p2, &p13, &p6, &p11, &p4, &p15, &p10, &p7, &p12, &p3, &p14, &p5, &p8, &p1, 1);
		Round1024_host(&p0, &p7, &p2, &p5, &p4, &p3, &p6, &p1, &p12, &p15, &p14, &p13, &p8, &p11, &p10, &p9, 2);
		Round1024_host(&p0, &p15, &p2, &p11, &p6, &p13, &p4, &p9, &p14, &p1, &p8, &p5, &p10, &p3, &p12, &p7, 3);

		p0 += h[(i + 0) % 17];
		p1 += h[(i + 1) % 17];
		p2 += h[(i + 2) % 17];
		p3 += h[(i + 3) % 17];
		p4 += h[(i + 4) % 17];
		p5 += h[(i + 5) % 17];
		p6 += h[(i + 6) % 17];
		p7 += h[(i + 7) % 17];
		p8 += h[(i + 8) % 17];
		p9 += h[(i + 9) % 17];
		p10 += h[(i + 10) % 17];
		p11 += h[(i + 11) % 17];
		p12 += h[(i + 12) % 17];
		p13 += h[(i + 13) % 17] + t[(i + 0) % 3];
		p14 += h[(i + 14) % 17] + t[(i + 1) % 3];
		p15 += h[(i + 15) % 17] + (uint64_t)i;

		Round1024_host(&p0, &p1, &p2, &p3, &p4, &p5, &p6, &p7, &p8, &p9, &p10, &p11, &p12, &p13, &p14, &p15, 4);
		Round1024_host(&p0, &p9, &p2, &p13, &p6, &p11, &p4, &p15, &p10, &p7, &p12, &p3, &p14, &p5, &p8, &p1, 5);
		Round1024_host(&p0, &p7, &p2, &p5, &p4, &p3, &p6, &p1, &p12, &p15, &p14, &p13, &p8, &p11, &p10, &p9, 6);
		Round1024_host(&p0, &p15, &p2, &p11, &p6, &p13, &p4, &p9, &p14, &p1, &p8, &p5, &p10, &p3, &p12, &p7, 7);

		p0 += h[(i + 1) % 17];
		p1 += h[(i + 2) % 17];
		p2 += h[(i + 3) % 17];
		p3 += h[(i + 4) % 17];
		p4 += h[(i + 5) % 17];
		p5 += h[(i + 6) % 17];
		p6 += h[(i + 7) % 17];
		p7 += h[(i + 8) % 17];
		p8 += h[(i + 9) % 17];
		p9 += h[(i + 10) % 17];
		p10 += h[(i + 11) % 17];
		p11 += h[(i + 12) % 17];
		p12 += h[(i + 13) % 17];
		p13 += h[(i + 14) % 17] + t[(i + 1) % 3];
		p14 += h[(i + 15) % 17] + t[(i + 2) % 3];
		p15 += h[(i + 16) % 17] + (uint64_t)(i + 1);


	}

	h[0] = p0^alt_data[0];
	h[1] = p1^alt_data[1];
	h[2] = p2^alt_data[2];
	h[3] = p3^alt_data[3];
	h[4] = p4^alt_data[4];
	h[5] = p5^alt_data[5];
	h[6] = p6^alt_data[6];
	h[7] = p7^alt_data[7];
	h[8] = p8^alt_data[8];
	h[9] = p9^alt_data[9];
	h[10] = p10^alt_data[10];
	h[11] = p11^alt_data[11];
	h[12] = p12^alt_data[12];
	h[13] = p13^alt_data[13];
	h[14] = p14^alt_data[14];
	h[15] = p15^alt_data[15];
	h[16] = cpu_skein_ks_parity;
	for (int i = 0; i<16; i++) { h[16] ^= h[i]; }


	memcpy(skeinC, h, sizeof(unsigned long long) * 17);
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
	
	//printf("Key output (after midstate, the feed-forward data for Skein-1024):\n");
	//DumpQwords(h, 17);
	//DumpVerilogStyle(h, 136);
	
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

#define GOLDEN_NONCE	(0x000000009A453A32)

// Nonce: 0x000000003488F48D
uint64_t NXSTestHeader[27] =
{
	0x8AB26AC400000008, 0x44103A011E17EDFE, 0x086E76FD8F7B32C0, 0x9E0D64A4A5005145, 0xE2D3B5048A296FB2, 0x154131894039D72F, 0xF9343D6E2B9FE41D, 0xAFB0F705493898BB, 
	0xEABE6EAF07194548, 0x35D863BBB12F70C1, 0xF34A84B9D0404F94, 0x5D012A827A4C85C5, 0x731C408FFB70927B, 0x4BC05BF9F9A0D659, 0xDCF2FEC8CC49CBB9, 0xD028E35A0037ABB0, 
	0x15F30CA5A3F8610A, 0xF0B09EFC984292FD, 0xDCE99E7E4307DF39, 0x668C980D6D3534D9, 0x16D5BC6C353A7788, 0x0FE3DF6767FCD6F6, 0x2E4F8C75FE9BDF1C, 0x40DD78B9B9B948C6, 
	0x00000002DE62A301, 0x7B019A020039B1F6
};

#elif TEST_VECTOR_3

#define GOLDEN_NONCE	0x000000000DC80000

uint64_t NXSTestHeader[27] = 
{
	0x6CD35A2E00000008, 0x93CFDB34AB23022D, 0x1BCBCCC72B278C5A, 0xFA04C3180A7EF845, 0xD52455AB2A3E9559, 0x94177740896FB361, 0x69D20E78235ECA4F, 0x68DBB8E61FCA0DD5,
	0x06337B10EC8308AC, 0x12CBDFBDF13F0AAB, 0x7B973E2EB90CF39E, 0x0C4DDBE7C3417582, 0xCE9F1470108526A6, 0x410A3FEC852F0F1F, 0x1AD4AE5CF74E8847, 0x514B49F2442C1A7E,
	0x4DCAFD097166B36D, 0xEE0F207850A44C2E, 0x3C7B66C8C1AC99CE, 0x7F8186762BD85BA9, 0x82092882C4B3F064, 0x6D1864D0D0D20800, 0x4FE4F94FFEA77FC2, 0x270BAE3A2C9A60BD,
	0x00000002018AEAC0, 0x7B01B6E9003A9AB0, 0x02E800000DC80000
};

#else

#define GOLDEN_NONCE	21155560019

uint8_t NXSTestHdr[] = {
0x04, 0x00, 0x00, 0x00, 0xA7, 0x93, 0xE4, 0x31, 0x0D, 0x69, 0x57, 0xC7, 0x58, 0xF2, 0x87, 0xF4, 0x62, 0xBE, 0xBF, 0xBB, 0x56, 0x2D, 0x25, 0xD3, 0xD8, 0xD7, 0x97, 0x16, 0xA5, 0x33, 0x04, 0x27, 0x2D, 0x76, 0xFA, 0xA6, 0x8A, 0x09, 0xFC, 0x5E, 0x3A, 0x2D, 0x00, 0x05, 0xD5, 0x5B, 0x1B, 0x65, 0x1F, 0x40, 0x1B, 0x9F, 0x48, 0x24, 0x56, 0xF6, 0xC4, 0x21, 0x51, 0x2D, 0xAF, 0x55, 0xF2, 0xF6, 0x70, 0x13, 0x5D, 0x02, 0xA5, 0x44, 0xFA, 0xD7, 0x63, 0x1E, 0x4B, 0x71, 0x5B, 0x00, 0x13, 0xDF, 0xC8, 0x96, 0x8E, 0xE6, 0x08, 0x98, 0xE8, 0xB5, 0x0D, 0x8D, 0xDA, 0x81, 0x3E, 0x45, 0xE5, 0xE0, 0x18, 0x6A, 0x3A, 0xED, 0x9E, 0x6F, 0x1D, 0x11, 0x62, 0x67, 0x3E, 0x62, 0xFE, 0x39, 0x3F, 0x0E, 0x9B, 0x46, 0x98, 0xC7, 0x05, 0xCF, 0x93, 0xD5, 0xCA, 0x00, 0x9B, 0xA2, 0xD2, 0x01, 0x63, 0x54, 0x02, 0x09, 0x00, 0x00, 0x25, 0x30, 0x3A, 0x6D, 0x34, 0xA2, 0xA8, 0x9E, 0x91, 0xEC, 0xB8, 0x14, 0xF5, 0x0D, 0x16, 0xA6, 0x29, 0x44, 0x41, 0x7C, 0x43, 0x22, 0xB4, 0x50, 0x38, 0xC7, 0x94, 0x22, 0x41, 0x9A, 0xD4, 0x5F, 0x90, 0xBE, 0xF6, 0xEB, 0xBE, 0x07, 0x5B, 0xAA, 0x04, 0x50, 0xF7, 0x88, 0xD0, 0x3E, 0x19, 0x40, 0x31, 0x6A, 0xC2, 0x43, 0x4F, 0x1C, 0xFD, 0x30, 0xCD, 0x07, 0x42, 0xFC, 0x58, 0xA4, 0xF5, 0x31, 0x02, 0x00, 0x00, 0x00, 0x6C, 0xDF, 0x1E, 0x00, 0xD8, 0x2E, 0x03, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

uint64_t *NXSTestHeader = (uint64_t *)NXSTestHdr;

#endif

////////////////////////
// Serial comms shit
////////////////////////

int set_interface_attribs(int fd, int speed, bool block, int timeoutsecs)
{
	struct termios tty;
	memset(&tty, 0, sizeof tty);
	
	if(tcgetattr(fd, &tty))
	{
		printf("Error %d from tcgetattr.\n", errno);
		return(-1);
	}
	
	cfsetospeed(&tty, speed);
	cfsetispeed(&tty, speed);
	
	// 8-bit chars
	tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
	
	// No signaling chars, no echo, no canonical processing
	tty.c_lflag = 0;
	
	// No remapping nor delays
	tty.c_oflag = 0;
	
	// Shut off xon/xoff ctrl; disable break processing
	tty.c_iflag &= ~(IXON | IXOFF | IXANY | IGNBRK);
	
	// Enable reading, and ignore modem controls
	tty.c_cflag |= (CLOCAL | CREAD);
	
	// Set no parity, one stop, no HW flow control
	tty.c_cflag &= ~(PARENB | PARODD | CSTOPB | CRTSCTS);
	
	// Set blocking/nonblocking and timeout accordingly
	// Timeout is expressed in tenths of a second
	tty.c_cc[VMIN]  = ((block) ? 1 : 0);
	tty.c_cc[VTIME] = ((block) ? (timeoutsecs * 10) : 3);
	
	if(tcsetattr(fd, TCSANOW, &tty))
	{
		printf("Error %d from tcsetattr.\n", errno);
		return(-1);
	}
	
	return(0);
}

int OpenSerial(const char *DeviceName)
{
	int fd = open(DeviceName, O_RDWR | O_NOCTTY | O_SYNC);
	
	if(fd < 0)
	{
		printf("Error %d opening %s: %s\n", errno, DeviceName, strerror(errno));
		return(-1);
	}
	
	if(set_interface_attribs(fd, B230400, true, 30))
	{
		printf("Failed setting interface attributes.\n");
		return(-1);
	}
	
	return(fd);
}

// Parameter len is bytes in rawstr, therefore, asciistr must have
// at least (len << 1) + 1 bytes allocated, the last for the NULL
void BinaryToASCIIHex(char *restrict asciistr, const void *restrict rawstr, size_t len)
{
	for(int i = 0, j = 0; i < len; ++i)
	{
		asciistr[j++] = "0123456789abcdef"[((uint8_t *)rawstr)[i] >> 4];
		asciistr[j++] = "0123456789abcdef"[((uint8_t *)rawstr)[i] & 0x0F];
	}
		
	asciistr[len << 1] = 0x00;
}

// Parameter len is the size in bytes of asciistr, meaning rawstr
// must have (len >> 1) bytes allocated
// Maybe asciistr just NULL terminated?
// Returns length of rawstr in bytes
int ASCIIHexToBinary(void *restrict rawstr, const char *restrict asciistr, size_t len)
{
	for(int i = 0, j = 0; i < len; ++i)
	{
		char tmp = asciistr[i];
		if(tmp < 'A') tmp -= '0';
		else if(tmp < 'a') tmp = (tmp - 'A') + 10;
		else tmp = (tmp - 'a') + 10;
		
		if(i & 1) ((uint8_t *)rawstr)[j++] |= tmp & 0x0F;
		else ((uint8_t *)rawstr)[j] = tmp << 4;
	}
	
	return(len >> 1);
}


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
	
	//printf("State before Skein block:\n");
	//DumpQwords(P, 16);
	//DumpVerilogStyle(P, 128);
	
	//printf("Key before Skein block:\n");
	//DumpQwords(Key, 17);
	//DumpVerilogStyle(Key, 136);
	
	SkeinRoundTest(P, Key, Type);
	
	//printf("\nResult after full Skein block process #2:\n");
	//DumpQwords(P, 16);
	//DumpVerilogStyle(P, 128);
	
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
	
	//printf("\nResult after full Skein block process #3:\n");
	//DumpQwords(P, 16);
	//DumpVerilogStyle(P, 128);
	
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
	
	printf("Keccak:\n");
	DumpQwords(KeccakState, 16);
	
	return(KeccakState[6]);
}

#pragma pack(push, 1)
typedef struct FPGAWorkPacket_s
{
	uint64_t Midstate[17];
	uint64_t BlkHdrTail[11];
} FPGAWorkPacket;
#pragma pack(pop)

uint64_t GetNonceResult(int fd)
{
	uint64_t OutputVal;
	uint8_t *BufPtr = (uint8_t *)&OutputVal;
	
	for(int BytesRead = 0; BytesRead < 8; ++BytesRead)
	{
		ssize_t ReadResult = read(fd, BufPtr + BytesRead, 8 - BytesRead);
		
		if(ReadResult < 0)
		{
			printf("read() failed with %d.\n", errno);
			close(fd);
			exit(1);
		}
		
		if(!ReadResult)
		{
			printf("Read timed out.\n");
			close(fd);
			exit(2);
		}
		
		BytesRead += ReadResult;
		printf("Received %d bytes.\n", ReadResult);
	}
	
	return(OutputVal);
}


int main(int argc, char **argv)
{
	uint8_t State[216], Key[136], Type[24], TestResponse[8];
	
	int fd, bytes;
	
	if(argc < 2)
	{
		printf("Usage: %s <device>\n", argv[0]);
		return(-1);
	}
	
	fd = OpenSerial(argv[1]);
	
	if(fd == -1)
	{
		printf("Failed to open file descriptor.\n");
		return(-1);
	}
	
	memcpy(State, NXSTestHeader, 216);
	printf("sizeof(FPGAWorkPacket) == %d\n", sizeof(FPGAWorkPacket));
	printf("Block:\n");
	DumpQwords(NXSTestHeader, 216 / 8);
	
	printf("Block input (after midstate, the remainder of the data to be hashed):\n");
	DumpQwords(State + 128, 10);
	DumpVerilogStyle(State + 128, 80);
	
	NXSMidstate(Key, State);
	
	// Post-midstate, create FPGA work packet and yeet it
	FPGAWorkPacket Pkt;
	
	// Only 10 qwords because no nonce, remember.
	for(int i = 16; i < 26; ++i)
		Pkt.BlkHdrTail[i - 16] = ((uint64_t *)State)[i];
	
	// Nonce
	//Pkt.BlkHdrTail[10] = 0x00ULL;
	Pkt.BlkHdrTail[10] = 0x48494E4450415753ULL;
	//Pkt.BlkHdrTail[10] = 0x012345678ABCDEFULL;
	printf("BlkHdrTail:\n");
	DumpVerilogStyle(Pkt.BlkHdrTail, 88);
	
	for(int i = 0; i < 17; ++i)
		Pkt.Midstate[i] = ((uint64_t *)Key)[i];
	
	printf("\nMidstate:\n");
	DumpVerilogStyle(Pkt.Midstate, 17 * 8);
	
	bytes = write(fd, &Pkt, sizeof(Pkt));
	
	printf("Wrote %d bytes to FPGA...\n", bytes);
	
	printf("Packet contents:\n");
	DumpQwords(&Pkt, sizeof(Pkt) >> 3);
	DumpVerilogStyle(&Pkt, sizeof(Pkt));
	usleep(50);
	
	for(;;)
	{
		bytes = read(fd, TestResponse, 8);
		
		if(bytes < 0)
		{
			printf("read() failed with %d.\n", errno);
			close(fd);
			continue;
			return(-1);
		}
		
		if(!bytes)
		{
			printf("Read timed out.\n");
			close(fd);
			return(-2);
		}
		
		printf("Received %d bytes.\n", bytes);
		printf("Value received: 0x%016llX.\n", ((uint64_t *)TestResponse)[0]);
	
		uint64_t RetQword = (((uint64_t *)TestResponse)[0]);
		
		/*
		printf("Key output:\n");
		DumpQwords(Key, 17);
		DumpVerilogStyle(Key, 136);
		
		printf("Test vector input:\n");
		DumpQwords(State + 16, 16);
		DumpVerilogStyle(State, 128);

		printf("Test key input:\n");
		DumpQwords(Key, 17);
		DumpVerilogStyle(Key, 136);
		*/
		
		//0x00000000F47E50BBULL
		uint64_t res = DoNXSTest(State, Key, RetQword);
		
		printf("NXS hash result for nonce 0x%016llX: 0x%016llX\n", RetQword, res);
	}
	
	return(0);
}
