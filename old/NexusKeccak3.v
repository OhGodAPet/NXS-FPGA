`timescale 1ns / 1ps
`default_nettype none

`define SIMULATION
`define IDX32(x)			((x) << 5)+:32
`define IDX64(x)			((x) << 6)+:64
`define ROTL64(x, y)		{x[63 - y : 0], x[63: 63 - y + 1]}

module NexusKeccak1024(output wire [63:0] OutState, input wire clk, input wire [1023:0] InState);

	parameter HASHERS = 1;
	parameter COREIDX = 0;
	
	// Every round has one clock cycle of latency,
	// and there are 24 rounds per block process.
	localparam KECCAKRNDSTAGES = 1, KECCAKROUNDS = 24;
	localparam KECCAKBLKSTAGES = KECCAKRNDSTAGES * KECCAKROUNDS;
	
	// Three block processes are needed; as such,
	// the pipe stages for this module is given by
	// KECCAKBLKSTAGES * 3, or 144 clock cycles.
	localparam STAGES = KECCAKBLKSTAGES, IDLE = 1'b0, MINING = 1'b1;
	localparam TOTALSTAGES = (STAGES * 3);

	reg [31:0] CurNonce;
	reg CurState = IDLE;
	reg [575:0] CurWorkBlk;
	reg [447:0] SecondRoundInput[STAGES-1:0];
	reg [1599:0] IBuf[TOTALSTAGES-1:0];
	wire [1599:0] OBuf[TOTALSTAGES-1:0];
	wire Transform0Complete;
	
	assign OutState = OBuf[TOTALSTAGES-1][`IDX64(6)];
	integer x;
	
	always @(posedge clk)
	begin
		IBuf[0] <= { 1024'b0, InState[575:0] };
		SecondRoundInput[0] <= InState[1023:576];
		
		// Cycle pipeline
		for(x = 1; x < STAGES; x = x + 1)
		begin : DataMoveLoop
			IBuf[x] <= OBuf[x - 1];
			SecondRoundInput[x] <= SecondRoundInput[x - 1];
		end

		// Do NOT cycle OBuf[STAGES-1] to IBuf[STAGES] - this is
		// the transition that requires an XOR with the second
		// round input data.
		for(x = STAGES + 1; x < TOTALSTAGES; x = x + 1)
		begin : DataMoveLoop2
			IBuf[x] <= OBuf[x - 1];
		end
		
		// Handle transition of OBuf[STAGES-1] to IBuf[STAGES], mixing
		// in 448 bits (56 bytes) of input, and the constants...
		IBuf[STAGES] <= { OBuf[STAGES-1][1599:576], OBuf[STAGES-1][575:0] ^ { 64'h8000000000000000, 64'h05, SecondRoundInput[STAGES-1] } };
	end

	// Keccakf-1600 iteration 0
	
	KeccakF1600Perm Perm0(OBuf[0], IBuf[0], 64'h0000000000000001);
	KeccakF1600Perm Perm1(OBuf[1], IBuf[1], 64'h0000000000008082);
	KeccakF1600Perm Perm2(OBuf[2], IBuf[2], 64'h800000000000808a);
	KeccakF1600Perm Perm3(OBuf[3], IBuf[3], 64'h8000000080008000);
	KeccakF1600Perm Perm4(OBuf[4], IBuf[4], 64'h000000000000808b);
	KeccakF1600Perm Perm5(OBuf[5], IBuf[5], 64'h0000000080000001);
	KeccakF1600Perm Perm6(OBuf[6], IBuf[6], 64'h8000000080008081);
	KeccakF1600Perm Perm7(OBuf[7], IBuf[7], 64'h8000000000008009);
	KeccakF1600Perm Perm8(OBuf[8], IBuf[8], 64'h000000000000008a);
	KeccakF1600Perm Perm9(OBuf[9], IBuf[9], 64'h0000000000000088);
	KeccakF1600Perm Perm10(OBuf[10], IBuf[10], 64'h0000000080008009);
	KeccakF1600Perm Perm11(OBuf[11], IBuf[11], 64'h000000008000000a);
	KeccakF1600Perm Perm12(OBuf[12], IBuf[12], 64'h000000008000808b);
	KeccakF1600Perm Perm13(OBuf[13], IBuf[13], 64'h800000000000008b);
	KeccakF1600Perm Perm14(OBuf[14], IBuf[14], 64'h8000000000008089);
	KeccakF1600Perm Perm15(OBuf[15], IBuf[15], 64'h8000000000008003);
	KeccakF1600Perm Perm16(OBuf[16], IBuf[16], 64'h8000000000008002);
	KeccakF1600Perm Perm17(OBuf[17], IBuf[17], 64'h8000000000000080);
	KeccakF1600Perm Perm18(OBuf[18], IBuf[18], 64'h000000000000800a);
	KeccakF1600Perm Perm19(OBuf[19], IBuf[19], 64'h800000008000000a);
	KeccakF1600Perm Perm20(OBuf[20], IBuf[20], 64'h8000000080008081);
	KeccakF1600Perm Perm21(OBuf[21], IBuf[21], 64'h8000000000008080);
	KeccakF1600Perm Perm22(OBuf[22], IBuf[22], 64'h0000000080000001);
	KeccakF1600Perm Perm23(OBuf[23], IBuf[23], 64'h8000000080008008);

	// Keccakf-1600 iteration 1
	
	KeccakF1600Perm Perm1_0(OBuf[0 + (STAGES * 1)], IBuf[0 + (STAGES * 1)], 64'h0000000000000001);
	KeccakF1600Perm Perm1_1(OBuf[1 + (STAGES * 1)], IBuf[1 + (STAGES * 1)], 64'h0000000000008082);
	KeccakF1600Perm Perm1_2(OBuf[2 + (STAGES * 1)], IBuf[2 + (STAGES * 1)], 64'h800000000000808a);
	KeccakF1600Perm Perm1_3(OBuf[3 + (STAGES * 1)], IBuf[3 + (STAGES * 1)], 64'h8000000080008000);
	KeccakF1600Perm Perm1_4(OBuf[4 + (STAGES * 1)], IBuf[4 + (STAGES * 1)], 64'h000000000000808b);
	KeccakF1600Perm Perm1_5(OBuf[5 + (STAGES * 1)], IBuf[5 + (STAGES * 1)], 64'h0000000080000001);
	KeccakF1600Perm Perm1_6(OBuf[6 + (STAGES * 1)], IBuf[6 + (STAGES * 1)], 64'h8000000080008081);
	KeccakF1600Perm Perm1_7(OBuf[7 + (STAGES * 1)], IBuf[7 + (STAGES * 1)], 64'h8000000000008009);
	KeccakF1600Perm Perm1_8(OBuf[8 + (STAGES * 1)], IBuf[8 + (STAGES * 1)], 64'h000000000000008a);
	KeccakF1600Perm Perm1_9(OBuf[9 + (STAGES * 1)], IBuf[9 + (STAGES * 1)], 64'h0000000000000088);
	KeccakF1600Perm Perm1_10(OBuf[10 + (STAGES * 1)], IBuf[10 + (STAGES * 1)], 64'h0000000080008009);
	KeccakF1600Perm Perm1_11(OBuf[11 + (STAGES * 1)], IBuf[11 + (STAGES * 1)], 64'h000000008000000a);
	KeccakF1600Perm Perm1_12(OBuf[12 + (STAGES * 1)], IBuf[12 + (STAGES * 1)], 64'h000000008000808b);
	KeccakF1600Perm Perm1_13(OBuf[13 + (STAGES * 1)], IBuf[13 + (STAGES * 1)], 64'h800000000000008b);
	KeccakF1600Perm Perm1_14(OBuf[14 + (STAGES * 1)], IBuf[14 + (STAGES * 1)], 64'h8000000000008089);
	KeccakF1600Perm Perm1_15(OBuf[15 + (STAGES * 1)], IBuf[15 + (STAGES * 1)], 64'h8000000000008003);
	KeccakF1600Perm Perm1_16(OBuf[16 + (STAGES * 1)], IBuf[16 + (STAGES * 1)], 64'h8000000000008002);
	KeccakF1600Perm Perm1_17(OBuf[17 + (STAGES * 1)], IBuf[17 + (STAGES * 1)], 64'h8000000000000080);
	KeccakF1600Perm Perm1_18(OBuf[18 + (STAGES * 1)], IBuf[18 + (STAGES * 1)], 64'h000000000000800a);
	KeccakF1600Perm Perm1_19(OBuf[19 + (STAGES * 1)], IBuf[19 + (STAGES * 1)], 64'h800000008000000a);
	KeccakF1600Perm Perm1_20(OBuf[20 + (STAGES * 1)], IBuf[20 + (STAGES * 1)], 64'h8000000080008081);
	KeccakF1600Perm Perm1_21(OBuf[21 + (STAGES * 1)], IBuf[21 + (STAGES * 1)], 64'h8000000000008080);
	KeccakF1600Perm Perm1_22(OBuf[22 + (STAGES * 1)], IBuf[22 + (STAGES * 1)], 64'h0000000080000001);
	KeccakF1600Perm Perm1_23(OBuf[23 + (STAGES * 1)], IBuf[23 + (STAGES * 1)], 64'h8000000080008008);

	// Keccakf-1600 iteration 2
	
	KeccakF1600Perm Perm2_0(OBuf[0 + (STAGES * 2)], IBuf[0 + (STAGES * 2)], 64'h0000000000000001);
	KeccakF1600Perm Perm2_1(OBuf[1 + (STAGES * 2)], IBuf[1 + (STAGES * 2)], 64'h0000000000008082);
	KeccakF1600Perm Perm2_2(OBuf[2 + (STAGES * 2)], IBuf[2 + (STAGES * 2)], 64'h800000000000808a);
	KeccakF1600Perm Perm2_3(OBuf[3 + (STAGES * 2)], IBuf[3 + (STAGES * 2)], 64'h8000000080008000);
	KeccakF1600Perm Perm2_4(OBuf[4 + (STAGES * 2)], IBuf[4 + (STAGES * 2)], 64'h000000000000808b);
	KeccakF1600Perm Perm2_5(OBuf[5 + (STAGES * 2)], IBuf[5 + (STAGES * 2)], 64'h0000000080000001);
	KeccakF1600Perm Perm2_6(OBuf[6 + (STAGES * 2)], IBuf[6 + (STAGES * 2)], 64'h8000000080008081);
	KeccakF1600Perm Perm2_7(OBuf[7 + (STAGES * 2)], IBuf[7 + (STAGES * 2)], 64'h8000000000008009);
	KeccakF1600Perm Perm2_8(OBuf[8 + (STAGES * 2)], IBuf[8 + (STAGES * 2)], 64'h000000000000008a);
	KeccakF1600Perm Perm2_9(OBuf[9 + (STAGES * 2)], IBuf[9 + (STAGES * 2)], 64'h0000000000000088);
	KeccakF1600Perm Perm2_10(OBuf[10 + (STAGES * 2)], IBuf[10 + (STAGES * 2)], 64'h0000000080008009);
	KeccakF1600Perm Perm2_11(OBuf[11 + (STAGES * 2)], IBuf[11 + (STAGES * 2)], 64'h000000008000000a);
	KeccakF1600Perm Perm2_12(OBuf[12 + (STAGES * 2)], IBuf[12 + (STAGES * 2)], 64'h000000008000808b);
	KeccakF1600Perm Perm2_13(OBuf[13 + (STAGES * 2)], IBuf[13 + (STAGES * 2)], 64'h800000000000008b);
	KeccakF1600Perm Perm2_14(OBuf[14 + (STAGES * 2)], IBuf[14 + (STAGES * 2)], 64'h8000000000008089);
	KeccakF1600Perm Perm2_15(OBuf[15 + (STAGES * 2)], IBuf[15 + (STAGES * 2)], 64'h8000000000008003);
	KeccakF1600Perm Perm2_16(OBuf[16 + (STAGES * 2)], IBuf[16 + (STAGES * 2)], 64'h8000000000008002);
	KeccakF1600Perm Perm2_17(OBuf[17 + (STAGES * 2)], IBuf[17 + (STAGES * 2)], 64'h8000000000000080);
	KeccakF1600Perm Perm2_18(OBuf[18 + (STAGES * 2)], IBuf[18 + (STAGES * 2)], 64'h000000000000800a);
	KeccakF1600Perm Perm2_19(OBuf[19 + (STAGES * 2)], IBuf[19 + (STAGES * 2)], 64'h800000008000000a);
	KeccakF1600Perm Perm2_20(OBuf[20 + (STAGES * 2)], IBuf[20 + (STAGES * 2)], 64'h8000000080008081);
	KeccakF1600Perm Perm2_21(OBuf[21 + (STAGES * 2)], IBuf[21 + (STAGES * 2)], 64'h8000000000008080);
	KeccakF1600Perm Perm2_22(OBuf[22 + (STAGES * 2)], IBuf[22 + (STAGES * 2)], 64'h0000000080000001);
	KeccakF1600Perm Perm2_23(OBuf[23 + (STAGES * 2)], IBuf[23 + (STAGES * 2)], 64'h8000000080008008);
	
endmodule


`define IDX64(x)            ((x) << 6)+:64
`define ROTL64_2(x, y)		(((x) << (y)) | ((x) >> (64 - (y))))
`define ROTL64(x, y)		{x[63 - y : 0], x[63: 63 - y + 1]}

module KeccakFThetaRhoPi(output wire [63:0] OutVals [24:0], input wire [63:0] State [24:0]);

	wire [63:0] InitXORVals[4:0], MainXORVals[4:0], TmpVals[24:0];
	
	// Theta
	assign InitXORVals[0] = State[0] ^ State[5] ^ State[10] ^ State[15] ^ State[20];
	assign InitXORVals[1] = State[0 + 1] ^ State[5 + 1] ^ State[10 + 1] ^ State[15 + 1] ^ State[20 + 1];
	assign InitXORVals[2] = State[0 + 2] ^ State[5 + 2] ^ State[10 + 2] ^ State[15 + 2] ^ State[20 + 2];
	assign InitXORVals[3] = State[0 + 3] ^ State[5 + 3] ^ State[10 + 3] ^ State[15 + 3] ^ State[20 + 3];
	assign InitXORVals[4] = State[0 + 4] ^ State[5 + 4] ^ State[10 + 4] ^ State[15 + 4] ^ State[20 + 4];
	
	assign MainXORVals[0] = InitXORVals[0] ^ `ROTL64(InitXORVals[2], 1);
	assign MainXORVals[1] = InitXORVals[1] ^ `ROTL64(InitXORVals[3], 1);
	assign MainXORVals[2] = InitXORVals[2] ^ `ROTL64(InitXORVals[4], 1);
	assign MainXORVals[3] = InitXORVals[3] ^ `ROTL64(InitXORVals[0], 1);
	assign MainXORVals[4] = InitXORVals[4] ^ `ROTL64(InitXORVals[1], 1);
	
	assign TmpVals[1] = State[6] ^ MainXORVals[0];
	assign OutVals[1] = `ROTL64(TmpVals[1], 44);
	assign TmpVals[8] = State[16] ^ MainXORVals[0];
	assign OutVals[8] = `ROTL64(TmpVals[8], 45);
	assign TmpVals[10] = State[1] ^ MainXORVals[0];
	assign OutVals[10] = `ROTL64(TmpVals[10], 1);
	assign TmpVals[17] = State[11] ^ MainXORVals[0];
	assign OutVals[17] = `ROTL64(TmpVals[17], 10);
	assign TmpVals[24] = State[21] ^ MainXORVals[0];
	assign OutVals[24] = `ROTL64(TmpVals[24], 2);
	
	assign TmpVals[2] = State[12] ^ MainXORVals[1];
	assign OutVals[2] = `ROTL64(TmpVals[2], 43);
	assign TmpVals[9] = State[22] ^ MainXORVals[1];
	assign OutVals[9] = `ROTL64(TmpVals[9], 61);
	assign TmpVals[11] = State[7] ^ MainXORVals[1];
	assign OutVals[11] = `ROTL64(TmpVals[11], 6);
	assign TmpVals[18] = State[17] ^ MainXORVals[1];
	assign OutVals[18] = `ROTL64(TmpVals[18], 15);
	assign TmpVals[20] = State[2] ^ MainXORVals[1];
	assign OutVals[20] = `ROTL64(TmpVals[20], 62);
	
	assign TmpVals[3] = State[18] ^ MainXORVals[2];
	assign OutVals[3] = `ROTL64(TmpVals[3], 21);
	assign TmpVals[5] = State[3] ^ MainXORVals[2];
	assign OutVals[5] = `ROTL64(TmpVals[5], 28);
	assign TmpVals[12] = State[13] ^ MainXORVals[2];
	assign OutVals[12] = `ROTL64(TmpVals[12], 25);
	assign TmpVals[19] = State[23] ^ MainXORVals[2];
	assign OutVals[19] = `ROTL64(TmpVals[19], 56);
	assign TmpVals[21] = State[8] ^ MainXORVals[2];
	assign OutVals[21] = `ROTL64(TmpVals[21], 55);
	
	assign TmpVals[4] = State[24] ^ MainXORVals[3];
	assign OutVals[4] = `ROTL64(TmpVals[4], 14);
	assign TmpVals[6] = State[9] ^ MainXORVals[3];
	assign OutVals[6] = `ROTL64(TmpVals[6], 20);
	assign TmpVals[13] = State[19] ^ MainXORVals[3];
	assign OutVals[13] = `ROTL64(TmpVals[13], 8);
	assign TmpVals[15] = State[4] ^ MainXORVals[3];
	assign OutVals[15] = `ROTL64(TmpVals[15], 27);
	assign TmpVals[22] = State[14] ^ MainXORVals[3];
	assign OutVals[22] = `ROTL64(TmpVals[22], 39);
	
	assign TmpVals[0] = State[0] ^ MainXORVals[4];
	assign OutVals[0] = TmpVals[0];
	assign TmpVals[7] = State[10] ^ MainXORVals[4];
	assign OutVals[7] = `ROTL64(TmpVals[7], 3);
	assign TmpVals[14] = State[20] ^ MainXORVals[4];
	assign OutVals[14] = `ROTL64(TmpVals[14], 18);
	assign TmpVals[16] = State[5] ^ MainXORVals[4];
	assign OutVals[16] = `ROTL64(TmpVals[16], 36);
	assign TmpVals[23] = State[15] ^ MainXORVals[4];
	assign OutVals[23] = `ROTL64(TmpVals[23], 41);
endmodule

module KeccakF1600Perm(output wire [1599:0] OutState, input wire [1599:0] InState, input wire [63:0] RndConst);

	// It probably seems odd - why the wires used are structured like this,
	// as well as why the input/output states are 1600-bit vectors. The
	// less important reasoning is maintaining compatibility with Verilog at
	// least as far back as its 2001 spec (in contrast to SystemVerilog),
	// as it will not allow passing arrays to modules. The more important
	// is that it seems to produce my *intended* HW design over a large
	// variety of settings with Vivado - even over different versions of it.
	// It often will repeat work - instead of having the 5-input XOR values
	// done, then their XOR with one another only once (Theta) - it'll
	// instead re-do them as needed through Rho, Pi, and even occasionally
	// during Chi as well. The area becomes the relative size of Texas.
	
	wire [63:0] RoundMid[24:0];
	wire [63:0] State[24:0];
	wire [63:0] Mid0, Mid1, Mid2, Mid3, Mid4, Mid5, Mid6, Mid7, Mid8;
	wire [63:0] Mid9, Mid10, Mid11, Mid12, Mid13, Mid14, Mid15, Mid16;
	wire [63:0] Mid17, Mid18, Mid19, Mid20, Mid21, Mid22, Mid23, Mid24;
	wire [63:0] InitXORVals0, InitXORVals1, InitXORVals2, InitXORVals3, InitXORVals4;
		
	genvar x;
	
	generate
	
	for(x = 0; x < 25; x = x + 1)
	begin : STATEASSIGNLOOP
		assign State[x] = InState[`IDX64(x)];
	end
	
	endgenerate
	
	KeccakFThetaRhoPi ThetaRhoPi(RoundMid, State);
	
	wire [63:0] FirstQwordCopy;
	
	// Chi
	assign FirstQwordCopy = RoundMid[0] ^ ((~RoundMid[1]) & RoundMid[2]);
	assign OutState[`IDX64(1)] = RoundMid[1] ^ ((~RoundMid[2]) & RoundMid[3]);
	assign OutState[`IDX64(2)] = RoundMid[2] ^ ((~RoundMid[3]) & RoundMid[4]);
	assign OutState[`IDX64(3)] = RoundMid[3] ^ ((~RoundMid[4]) & RoundMid[0]);
	assign OutState[`IDX64(4)] = RoundMid[4] ^ ((~RoundMid[0]) & RoundMid[1]);
	
	generate
	
		for(x = 5; x < 25; x = x + 5)
		begin : CHILOOP0
			assign OutState[`IDX64(0 + x)] = RoundMid[0 + x] ^ ((~RoundMid[1 + x]) & RoundMid[2 + x]);
			assign OutState[`IDX64(1 + x)] = RoundMid[1 + x] ^ ((~RoundMid[2 + x]) & RoundMid[3 + x]);
			assign OutState[`IDX64(2 + x)] = RoundMid[2 + x] ^ ((~RoundMid[3 + x]) & RoundMid[4 + x]);
			assign OutState[`IDX64(3 + x)] = RoundMid[3 + x] ^ ((~RoundMid[4 + x]) & RoundMid[0 + x]);
			assign OutState[`IDX64(4 + x)] = RoundMid[4 + x] ^ ((~RoundMid[0 + x]) & RoundMid[1 + x]);
		end
		
	for(x = 0; x < 64; x = x + 1)
		begin : IOTALOOP0
			if(x == 0 || x == 1 || x == 3 || x == 7 || x == 15 || x == 31 || x == 63)
				assign OutState[x] = FirstQwordCopy[x] ^ RndConst[x];
			else
				assign OutState[x] = FirstQwordCopy[x];
		end
	endgenerate
endmodule
