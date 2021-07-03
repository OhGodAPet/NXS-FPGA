#ifndef SK1024_CL
#define SK1024_CL

__constant static const ulong keccakf_1600_rc[24] = 
{
    0x0000000000000001UL, 0x0000000000008082UL,
    0x800000000000808AUL, 0x8000000080008000UL,
    0x000000000000808BUL, 0x0000000080000001UL,
    0x8000000080008081UL, 0x8000000000008009UL,
    0x000000000000008AUL, 0x0000000000000088UL,
    0x0000000080008009UL, 0x000000008000000AUL,
    0x000000008000808BUL, 0x800000000000008BUL,
    0x8000000000008089UL, 0x8000000000008003UL,
    0x8000000000008002UL, 0x8000000000000080UL,
    0x000000000000800AUL, 0x800000008000000AUL,
    0x8000000080008081UL, 0x8000000000008080UL,
    0x0000000080000001UL, 0x8000000080008008UL
};

#define ROTL64_1(x, y) (amd_bitalign((x), (x).s10, 32 - (y)))
#define ROTL64_2(x, y) (amd_bitalign((x).s10, (x), 32 - (y)))

void keccak_block(uint2 *s, const uint isolate)
{
	#pragma unroll 1
	for(int i = 0; i < 24; ++i)
	{
		uint2 m[5], v, w;
		m[0] = s[0] ^ s[5] ^ s[10] ^ s[15] ^ s[20] ^ ROTL64_1(s[2] ^ s[7] ^ s[12] ^ s[17] ^ s[22], 1);
		m[1] = s[1] ^ s[6] ^ s[11] ^ s[16] ^ s[21] ^ ROTL64_1(s[3] ^ s[8] ^ s[13] ^ s[18] ^ s[23], 1);
		m[2] = s[2] ^ s[7] ^ s[12] ^ s[17] ^ s[22] ^ ROTL64_1(s[4] ^ s[9] ^ s[14] ^ s[19] ^ s[24], 1);
		m[3] = s[3] ^ s[8] ^ s[13] ^ s[18] ^ s[23] ^ ROTL64_1(s[0] ^ s[5] ^ s[10] ^ s[15] ^ s[20], 1);
		m[4] = s[4] ^ s[9] ^ s[14] ^ s[19] ^ s[24] ^ ROTL64_1(s[1] ^ s[6] ^ s[11] ^ s[16] ^ s[21], 1);
		
		const uint2 tmp = s[1]^m[0];
		
		/*
		s[0] ^= m[4];
		s[5] ^= m[4]; 
		s[10] ^= m[4]; 
		s[15] ^= m[4]; 
		s[20] ^= m[4]; 
		
		s[6] ^= m[0]; 
		s[11] ^= m[0]; 
		s[16] ^= m[0]; 
		s[21] ^= m[0]; 
		
		s[2] ^= m[1]; 
		s[7] ^= m[1]; 
		s[12] ^= m[1]; 
		s[17] ^= m[1]; 
		s[22] ^= m[1]; 
		
		s[3] ^= m[2]; 
		s[8] ^= m[2]; 
		s[13] ^= m[2]; 
		s[18] ^= m[2]; 
		s[23] ^= m[2]; 
		
		s[4] ^= m[3]; 
		s[9] ^= m[3]; 
		s[14] ^= m[3]; 
		s[19] ^= m[3]; 
		s[24] ^= m[3]; 
		*/
		
		s[0] ^= m[4];
		s[1] = ROTL64_2(s[6] ^ m[0], 12);
		s[6] = ROTL64_1(s[9] ^ m[3], 20);
		s[9] = ROTL64_2(s[22] ^ m[1], 29);
		s[22] = ROTL64_2(s[14] ^ m[3], 7);
		s[14] = ROTL64_1(s[20] ^ m[4], 18);
		s[20] = ROTL64_2(s[2] ^ m[1], 30);
		s[2] = ROTL64_2(s[12] ^ m[1], 11);
		s[12] = ROTL64_1(s[13] ^ m[2], 25);
		s[13] = ROTL64_1(s[19] ^ m[3],  8);
		s[19] = ROTL64_2(s[23] ^ m[2], 24);
		s[23] = ROTL64_2(s[15] ^ m[4], 9);
		s[15] = ROTL64_1(s[4] ^ m[3], 27);
		s[4] = ROTL64_1(s[24] ^ m[3], 14);
		s[24] = ROTL64_1(s[21] ^ m[0],  2);
		s[21] = ROTL64_2(s[8] ^ m[2], 23);
		s[8] = ROTL64_2(s[16] ^ m[0], 13);
		s[16] = ROTL64_2(s[5] ^ m[4], 4);
		s[5] = ROTL64_1(s[3] ^ m[2], 28);
		s[3] = ROTL64_1(s[18] ^ m[2], 21);
		s[18] = ROTL64_1(s[17] ^ m[1], 15);
		s[17] = ROTL64_1(s[11] ^ m[0], 10);
		s[11] = ROTL64_1(s[7] ^ m[1],  6);
		s[7] = ROTL64_1(s[10] ^ m[4],  3);
		s[10] = ROTL64_1(tmp,  1);
		
		v = s[0]; w = s[1]; s[0] = bitselect(s[0] ^ s[2], s[0], s[1]); s[1] = bitselect(s[1] ^ s[3], s[1], s[2]); s[2] = bitselect(s[2] ^ s[4], s[2], s[3]); s[3] = bitselect(s[3] ^ v, s[3], s[4]); s[4] = bitselect(s[4] ^ w, s[4], v);
		v = s[5]; w = s[6]; s[5] = bitselect(s[5] ^ s[7], s[5], s[6]); s[6] = bitselect(s[6] ^ s[8], s[6], s[7]); s[7] = bitselect(s[7] ^ s[9], s[7], s[8]); s[8] = bitselect(s[8] ^ v, s[8], s[9]); s[9] = bitselect(s[9] ^ w, s[9], v);
		v = s[10]; w = s[11]; s[10] = bitselect(s[10] ^ s[12], s[10], s[11]); s[11] = bitselect(s[11] ^ s[13], s[11], s[12]); s[12] = bitselect(s[12] ^ s[14], s[12], s[13]); s[13] = bitselect(s[13] ^ v, s[13], s[14]); s[14] = bitselect(s[14] ^ w, s[14], v);
		v = s[15]; w = s[16]; s[15] = bitselect(s[15] ^ s[17], s[15], s[16]); s[16] = bitselect(s[16] ^ s[18], s[16], s[17]); s[17] = bitselect(s[17] ^ s[19], s[17], s[18]); s[18] = bitselect(s[18] ^ v, s[18], s[19]); s[19] = bitselect(s[19] ^ w, s[19], v);
		v = s[20]; w = s[21]; s[20] = bitselect(s[20] ^ s[22], s[20], s[21]); s[21] = bitselect(s[21] ^ s[23], s[21], s[22]); s[22] = bitselect(s[22] ^ s[24], s[22], s[23]); s[23] = bitselect(s[23] ^ v, s[23], s[24]); s[24] = bitselect(s[24] ^ w, s[24], v);
		
		s[0] ^= as_uint2(keccakf_1600_rc[i]);
	}
}

ulong SKEIN_ROT(const uint2 x, const uint y)
{
	//if(y < 32) return(as_ulong(amd_bitalign(x, x.s10, 32 - y)));
	//else if(y > 32) return(as_ulong(amd_bitalign(x.s10, x, 32 - (y - 32))));
	
	//return(as_ulong(x.s10));
	
	uint2 xx = (y < 32) ? amd_bitalign(x, x.s10, 32 - y) : amd_bitalign(x.s10, x, 32 - (y - 32));
	return(((y == 32) ? as_ulong(x.s10) : as_ulong(xx)));
	
}

void SkeinMix8(ulong8 *pv0, ulong8 *pv1, const uint rc0, const uint rc1, const uint rc2, const uint rc3, const uint rc4, const uint rc5, const uint rc6, const uint rc7)
{
	*pv0 += *pv1;
	(*pv1).s0 = SKEIN_ROT(as_uint2((*pv1).s0), rc0);
	(*pv1).s1 = SKEIN_ROT(as_uint2((*pv1).s1), rc1);
	(*pv1).s2 = SKEIN_ROT(as_uint2((*pv1).s2), rc2);
	(*pv1).s3 = SKEIN_ROT(as_uint2((*pv1).s3), rc3);
	(*pv1).s4 = SKEIN_ROT(as_uint2((*pv1).s4), rc4);
	(*pv1).s5 = SKEIN_ROT(as_uint2((*pv1).s5), rc5);
	(*pv1).s6 = SKEIN_ROT(as_uint2((*pv1).s6), rc6);
	(*pv1).s7 = SKEIN_ROT(as_uint2((*pv1).s7), rc7);
	*pv1 ^= *pv0;
}

#define SKEIN_INJECT_KEY(p, s)	do { \
	p += h; \
	p.sd += t[(s) % 3]; \
	p.se += t[((s) + 1) % 3]; \
	p.sf += (s); \
} while(0)

ulong16 SkeinEvenRound(ulong16 p, const ulong *t, const uint s)
{
	ulong8 pv0 = p.even, pv1 = p.odd;
	
	SkeinMix8(&pv0, &pv1, 55, 43, 37, 40, 16, 22, 38, 12);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	SkeinMix8(&pv0, &pv1, 25, 25, 46, 13, 14, 13, 52, 57);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	SkeinMix8(&pv0, &pv1, 33, 8, 18, 57, 21, 12, 32, 54);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	SkeinMix8(&pv0, &pv1, 34, 43, 25, 60, 44, 9, 59, 34);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	return(shuffle2(pv0, pv1, (ulong16)(0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15)));
}

ulong16 SkeinOddRound(ulong16 p, const ulong *t, const uint s)
{
	ulong8 pv0 = p.even, pv1 = p.odd;
	
	// Permutation
	// 0 -> 0
	// 2 -> 2
	// 4 -> 6
	// 6 -> 4
	// 8 -> 10
	// 10 -> 12
	// 12 -> 14
	// 14 -> 8
	
	// 1 -> 9
	// 3 -> 13
	// 5 -> 11
	// 7 -> 15
	// 9 -> 7
	// 11 -> 3
	// 13 -> 5
	// 15 -> 1
	SkeinMix8(&pv0, &pv1, 28, 7, 47, 48, 51, 9, 35, 41);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	SkeinMix8(&pv0, &pv1, 17, 6, 18, 25, 43, 42, 40, 15);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	SkeinMix8(&pv0, &pv1, 58, 7, 32, 45, 19, 18, 2, 56);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	SkeinMix8(&pv0, &pv1, 47, 49, 27, 58, 37, 48, 53, 56);
	pv0 = shuffle(pv0, (ulong8)(0, 1, 3, 2, 5, 6, 7, 4));
	pv1 = shuffle(pv1, (ulong8)(4, 6, 5, 7, 3, 1, 2, 0));
	
	return(shuffle2(pv0, pv1, (ulong16)(0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15)));
}

ulong16 Skein1024Block(ulong16 p, ulong16 h, ulong h17, const ulong *t)
{
	#if 1
	#pragma unroll 10
	for(int i = 0; i < 20; i += 2)
	{
		SKEIN_INJECT_KEY(p, i);
		p = SkeinEvenRound(p, t, i);
		ulong tmp = h.s0;
		h = shuffle(h, (ulong16)(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0));
		h.sf = h17;
		h17 = tmp;
		
		SKEIN_INJECT_KEY(p, i + 1);
		p = SkeinOddRound(p, t, i + 1);
		tmp = h.s0;
		h = shuffle(h, (ulong16)(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0));
		h.sf = h17;
		h17 = tmp;
	}
	
	#else
	
	#pragma unroll 20
	for(int i = 0; i < 20; ++i)
	{
		SKEIN_INJECT_KEY(p, i);
		p = (i & 1) ? SkeinOddRound(p, t, i) : SkeinEvenRound(p, t, i);
		ulong tmp = h.s0;
		h = shuffle(h, (ulong16)(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0));
		h.sf = h17;
		h17 = tmp;
	}
	
	#endif
	
	SKEIN_INJECT_KEY(p, 20);
	return(p);
}

void DumpVerilogStyle(void *data, int len)
{
	printf("%d'h", len << 3);
	
	for(int i = len - 1; i >= 0; --i) printf("%02X", ((uchar *)data)[i]);
	printf("\n");
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void sk1024(__constant ulong *uMessage, __constant ulong *c_hv, const ulong HN, __global ulong *midbuf, const uint isolate)
{	
	ulong nonce = as_ulong((uint2)(get_global_id(0), (uint)HN));
	ulong16 p = 0, h = 0;
	ulong h17;
	
	//m.lo = vload8(2, uMessage);
	//m.s8 = uMessage[24];
	//m.s9 = uMessage[25];
	//m.sa = nonce;
	
	//p = m;
	
	p.lo = vload8(2, uMessage);
	p.s8 = uMessage[24];
	p.s9 = uMessage[25];
	p.sa = nonce;
	
	h = vload16(0, c_hv);
	h17 = c_hv[16];
	
	midbuf += ((get_global_id(0) - get_global_offset(0)) << 4);
	
	#if 1
	
	#pragma unroll
	for(int i = 0; i < 2; ++i)
	{
		ulong t[3];
		
		t[0] = (i) ? 0x08UL : 0xD8UL;
		t[1] = (i) ? 0xFF00000000000000UL : 0xB000000000000000UL;
		t[2] = t[0] | t[1];
		
		p = Skein1024Block(p, h, h17, t);
		if(i)
		{
			vstore16(p, 0, midbuf);
			mem_fence(CLK_GLOBAL_MEM_FENCE);
			return;
		}
		h.lo = p.lo ^ vload8(2, uMessage);
		h.s8 = p.s8 ^ uMessage[24];
		h.s9 = p.s9 ^ uMessage[25];
		h.sa = p.sa ^ nonce;
		h.sb = p.sb;
		h.scdef = p.scdef;
		p = (ulong16)(0);
		h17 = 0x5555555555555555UL ^ h.s0 ^ h.s1 ^ h.s2 ^ h.s3 ^ h.s4 ^ h.s5 ^ h.s6 ^ h.s7 ^ h.s8 ^ h.s9 ^ h.sa ^ h.sb ^ h.sc ^ h.sd ^ h.se ^ h.sf;
	}
	
	#else
	
	ulong t[3];
		
	t[0] = 0xD8UL;
	t[1] = 0xB000000000000000UL;
	t[2] = t[0] | t[1];
	
	if(!get_global_id(0))
	{
		ulong TmpBuf[17];
		
		printf("State:\n");
		vstore16(p, 0, TmpBuf);
		DumpVerilogStyle(TmpBuf, 128);
		
		printf("\nKey:\n");
		vstore16(h, 0, TmpBuf);
		TmpBuf[16] = h17;
		DumpVerilogStyle(TmpBuf, 136);

		printf("\nType:\n");
		DumpVerilogStyle(t, 24);
	}
	
	p = Skein1024Block(p, h, h17, t);
	
	if(!get_global_id(0))
	{
		printf("After Skein1024Block():\n");
		vstore16(p, 0, TmpBuf);
		DumpVerilogStyle(TmpBuf, 128);
	}
	
	h.lo = p.lo ^ vload8(2, uMessage);
	h.s8 = p.s8 ^ uMessage[24];
	h.s9 = p.s9 ^ uMessage[25];
	h.sa = p.sa ^ nonce;
	h.sb = p.sb;
	h.scdef = p.scdef;
	h17 = 0x5555555555555555UL ^ h.s0 ^ h.s1 ^ h.s2 ^ h.s3 ^ h.s4 ^ h.s5 ^ h.s6 ^ h.s7 ^ h.s8 ^ h.s9 ^ h.sa ^ h.sb ^ h.sc ^ h.sd ^ h.se ^ h.sf;
	
	t[0] = 0x08UL;
	t[1] = 0xFF00000000000000UL;
	t[2] = t[0] | t[1];
	
	vstore16(Skein1024Block((ulong16)(0), h, h17, t), 0, midbuf);
	mem_fence(CLK_GLOBAL_MEM_FENCE);
	
	#endif
}

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void sk1024_2(__constant ulong *midbuf, const ulong HN, __global ulong *output, const ulong Target, const uint isolate)
{
	uint2 state[25];
	ulong nonce = as_ulong((uint2)(get_global_id(0), (uint)HN)); //(ulong)get_global_id(0) + HN;
	midbuf += (16 * (get_global_id(0) - get_global_offset(0)));
	
	((uint16 *)state)[0] = vload16(0, (__constant uint *)midbuf);
	state[8] = as_uint2(midbuf[8]);
	
	#pragma unroll
	for(int i = 9; i < 25; ++i) state[i] = 0;
	
	keccak_block((uint2 *)state, isolate);
	
	state[0] ^= as_uint2(midbuf[9]);
	state[1] ^= as_uint2(midbuf[10]);
	state[2] ^= as_uint2(midbuf[11]);
	state[3] ^= as_uint2(midbuf[12]);
	state[4] ^= as_uint2(midbuf[13]);
	state[5] ^= as_uint2(midbuf[14]);
	state[6] ^= as_uint2(midbuf[15]);
	state[7] ^= (uint2)(0x05U, 0x00U);
	state[8] ^= (uint2)(0x00U, 0x80000000U);	//1UL << 63UL;
	
	keccak_block((uint2 *)state, isolate);
	keccak_block((uint2 *)state, isolate);
	
	if(as_ulong(state[6]) <= Target) output[output[0xFF]++] = nonce;
}

#endif
