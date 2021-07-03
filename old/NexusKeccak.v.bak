`timescale 1ns / 1ps
`default_nettype none

`define SIMULATION
`define IDX32(x)			((x) << 5)+:32
`define IDX64(x)			((x) << 6)+:64
`define ROTL64(x, y)		{x[63 - y : 0], x[63: 63 - y + 1]}

module NexusKeccak1024(output wire [63:0] OutState, input wire clk, input wire [1023:0] InState);

	parameter HASHERS = 1;
	parameter COREIDX = 0;
	
	// Every round has two clock cycles of latency,
	// and there are 24 rounds per block process.
	localparam KECCAKRNDSTAGES = 2, KECCAKROUNDS = 24;
	localparam KECCAKBLKSTAGES = KECCAKRNDSTAGES * KECCAKROUNDS;
	
	// Three block processes are needed; as such,
	// the pipe stages for this module is given by
	// KECCAKBLKSTAGES * 3, or 144 clock cycles.
	localparam STAGES = 48, IDLE = 1'b0, MINING = 1'b1;
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
	
	KeccakF1600Perm0 Perm0_0(OBuf[0], IBuf[0]);
	KeccakF1600Perm1 Perm1_0(OBuf[1], IBuf[1], 64'h0000000000000001);
	KeccakF1600Perm0 Perm0_1(OBuf[2], IBuf[2]);
	KeccakF1600Perm1 Perm1_1(OBuf[3], IBuf[3], 64'h0000000000008082);
	KeccakF1600Perm0 Perm0_2(OBuf[4], IBuf[4]);
	KeccakF1600Perm1 Perm1_2(OBuf[5], IBuf[5], 64'h800000000000808a);
	KeccakF1600Perm0 Perm0_3(OBuf[6], IBuf[6]);
	KeccakF1600Perm1 Perm1_3(OBuf[7], IBuf[7], 64'h8000000080008000);
	KeccakF1600Perm0 Perm0_4(OBuf[8], IBuf[8]);
	KeccakF1600Perm1 Perm1_4(OBuf[9], IBuf[9], 64'h000000000000808b);
	KeccakF1600Perm0 Perm0_5(OBuf[10], IBuf[10]);
	KeccakF1600Perm1 Perm1_5(OBuf[11], IBuf[11], 64'h0000000080000001);
	KeccakF1600Perm0 Perm0_6(OBuf[12], IBuf[12]);
	KeccakF1600Perm1 Perm1_6(OBuf[13], IBuf[13], 64'h8000000080008081);
	KeccakF1600Perm0 Perm0_7(OBuf[14], IBuf[14]);
	KeccakF1600Perm1 Perm1_7(OBuf[15], IBuf[15], 64'h8000000000008009);
	KeccakF1600Perm0 Perm0_8(OBuf[16], IBuf[16]);
	KeccakF1600Perm1 Perm1_8(OBuf[17], IBuf[17], 64'h000000000000008a);
	KeccakF1600Perm0 Perm0_9(OBuf[18], IBuf[18]);
	KeccakF1600Perm1 Perm1_9(OBuf[19], IBuf[19], 64'h0000000000000088);
	KeccakF1600Perm0 Perm0_10(OBuf[20], IBuf[20]);
	KeccakF1600Perm1 Perm1_10(OBuf[21], IBuf[21], 64'h0000000080008009);
	KeccakF1600Perm0 Perm0_11(OBuf[22], IBuf[22]);
	KeccakF1600Perm1 Perm1_11(OBuf[23], IBuf[23], 64'h000000008000000a);
	KeccakF1600Perm0 Perm0_12(OBuf[24], IBuf[24]);
	KeccakF1600Perm1 Perm1_12(OBuf[25], IBuf[25], 64'h000000008000808b);
	KeccakF1600Perm0 Perm0_13(OBuf[26], IBuf[26]);
	KeccakF1600Perm1 Perm1_13(OBuf[27], IBuf[27], 64'h800000000000008b);
	KeccakF1600Perm0 Perm0_14(OBuf[28], IBuf[28]);
	KeccakF1600Perm1 Perm1_14(OBuf[29], IBuf[29], 64'h8000000000008089);
	KeccakF1600Perm0 Perm0_15(OBuf[30], IBuf[30]);
	KeccakF1600Perm1 Perm1_15(OBuf[31], IBuf[31], 64'h8000000000008003);
	KeccakF1600Perm0 Perm0_16(OBuf[32], IBuf[32]);
	KeccakF1600Perm1 Perm1_16(OBuf[33], IBuf[33], 64'h8000000000008002);
	KeccakF1600Perm0 Perm0_17(OBuf[34], IBuf[34]);
	KeccakF1600Perm1 Perm1_17(OBuf[35], IBuf[35], 64'h8000000000000080);
	KeccakF1600Perm0 Perm0_18(OBuf[36], IBuf[36]);
	KeccakF1600Perm1 Perm1_18(OBuf[37], IBuf[37], 64'h000000000000800a);
	KeccakF1600Perm0 Perm0_19(OBuf[38], IBuf[38]);
	KeccakF1600Perm1 Perm1_19(OBuf[39], IBuf[39], 64'h800000008000000a);
	KeccakF1600Perm0 Perm0_20(OBuf[40], IBuf[40]);
	KeccakF1600Perm1 Perm1_20(OBuf[41], IBuf[41], 64'h8000000080008081);
	KeccakF1600Perm0 Perm0_21(OBuf[42], IBuf[42]);
	KeccakF1600Perm1 Perm1_21(OBuf[43], IBuf[43], 64'h8000000000008080);
	KeccakF1600Perm0 Perm0_22(OBuf[44], IBuf[44]);
	KeccakF1600Perm1 Perm1_22(OBuf[45], IBuf[45], 64'h0000000080000001);
	KeccakF1600Perm0 Perm0_23(OBuf[46], IBuf[46]);
	KeccakF1600Perm1 Perm1_23(OBuf[47], IBuf[47], 64'h8000000080008008);

	// Keccakf-1600 iteration 1
	
	KeccakF1600Perm0 Perm1_0_0(OBuf[0 + 48], IBuf[0 + 48]);
	KeccakF1600Perm1 Perm1_1_0(OBuf[1 + 48], IBuf[1 + 48], 64'h0000000000000001);
	KeccakF1600Perm0 Perm1_0_1(OBuf[2 + 48], IBuf[2 + 48]);
	KeccakF1600Perm1 Perm1_1_1(OBuf[3 + 48], IBuf[3 + 48], 64'h0000000000008082);
	KeccakF1600Perm0 Perm1_0_2(OBuf[4 + 48], IBuf[4 + 48]);
	KeccakF1600Perm1 Perm1_1_2(OBuf[5 + 48], IBuf[5 + 48], 64'h800000000000808a);
	KeccakF1600Perm0 Perm1_0_3(OBuf[6 + 48], IBuf[6 + 48]);
	KeccakF1600Perm1 Perm1_1_3(OBuf[7 + 48], IBuf[7 + 48], 64'h8000000080008000);
	KeccakF1600Perm0 Perm1_0_4(OBuf[8 + 48], IBuf[8 + 48]);
	KeccakF1600Perm1 Perm1_1_4(OBuf[9 + 48], IBuf[9 + 48], 64'h000000000000808b);
	KeccakF1600Perm0 Perm1_0_5(OBuf[10 + 48], IBuf[10 + 48]);
	KeccakF1600Perm1 Perm1_1_5(OBuf[11 + 48], IBuf[11 + 48], 64'h0000000080000001);
	KeccakF1600Perm0 Perm1_0_6(OBuf[12 + 48], IBuf[12 + 48]);
	KeccakF1600Perm1 Perm1_1_6(OBuf[13 + 48], IBuf[13 + 48], 64'h8000000080008081);
	KeccakF1600Perm0 Perm1_0_7(OBuf[14 + 48], IBuf[14 + 48]);
	KeccakF1600Perm1 Perm1_1_7(OBuf[15 + 48], IBuf[15 + 48], 64'h8000000000008009);
	KeccakF1600Perm0 Perm1_0_8(OBuf[16 + 48], IBuf[16 + 48]);
	KeccakF1600Perm1 Perm1_1_8(OBuf[17 + 48], IBuf[17 + 48], 64'h000000000000008a);
	KeccakF1600Perm0 Perm1_0_9(OBuf[18 + 48], IBuf[18 + 48]);
	KeccakF1600Perm1 Perm1_1_9(OBuf[19 + 48], IBuf[19 + 48], 64'h0000000000000088);
	KeccakF1600Perm0 Perm1_0_10(OBuf[20 + 48], IBuf[20 + 48]);
	KeccakF1600Perm1 Perm1_1_10(OBuf[21 + 48], IBuf[21 + 48], 64'h0000000080008009);
	KeccakF1600Perm0 Perm1_0_11(OBuf[22 + 48], IBuf[22 + 48]);
	KeccakF1600Perm1 Perm1_1_11(OBuf[23 + 48], IBuf[23 + 48], 64'h000000008000000a);
	KeccakF1600Perm0 Perm1_0_12(OBuf[24 + 48], IBuf[24 + 48]);
	KeccakF1600Perm1 Perm1_1_12(OBuf[25 + 48], IBuf[25 + 48], 64'h000000008000808b);
	KeccakF1600Perm0 Perm1_0_13(OBuf[26 + 48], IBuf[26 + 48]);
	KeccakF1600Perm1 Perm1_1_13(OBuf[27 + 48], IBuf[27 + 48], 64'h800000000000008b);
	KeccakF1600Perm0 Perm1_0_14(OBuf[28 + 48], IBuf[28 + 48]);
	KeccakF1600Perm1 Perm1_1_14(OBuf[29 + 48], IBuf[29 + 48], 64'h8000000000008089);
	KeccakF1600Perm0 Perm1_0_15(OBuf[30 + 48], IBuf[30 + 48]);
	KeccakF1600Perm1 Perm1_1_15(OBuf[31 + 48], IBuf[31 + 48], 64'h8000000000008003);
	KeccakF1600Perm0 Perm1_0_16(OBuf[32 + 48], IBuf[32 + 48]);
	KeccakF1600Perm1 Perm1_1_16(OBuf[33 + 48], IBuf[33 + 48], 64'h8000000000008002);
	KeccakF1600Perm0 Perm1_0_17(OBuf[34 + 48], IBuf[34 + 48]);
	KeccakF1600Perm1 Perm1_1_17(OBuf[35 + 48], IBuf[35 + 48], 64'h8000000000000080);
	KeccakF1600Perm0 Perm1_0_18(OBuf[36 + 48], IBuf[36 + 48]);
	KeccakF1600Perm1 Perm1_1_18(OBuf[37 + 48], IBuf[37 + 48], 64'h000000000000800a);
	KeccakF1600Perm0 Perm1_0_19(OBuf[38 + 48], IBuf[38 + 48]);
	KeccakF1600Perm1 Perm1_1_19(OBuf[39 + 48], IBuf[39 + 48], 64'h800000008000000a);
	KeccakF1600Perm0 Perm1_0_20(OBuf[40 + 48], IBuf[40 + 48]);
	KeccakF1600Perm1 Perm1_1_20(OBuf[41 + 48], IBuf[41 + 48], 64'h8000000080008081);
	KeccakF1600Perm0 Perm1_0_21(OBuf[42 + 48], IBuf[42 + 48]);
	KeccakF1600Perm1 Perm1_1_21(OBuf[43 + 48], IBuf[43 + 48], 64'h8000000000008080);
	KeccakF1600Perm0 Perm1_0_22(OBuf[44 + 48], IBuf[44 + 48]);
	KeccakF1600Perm1 Perm1_1_22(OBuf[45 + 48], IBuf[45 + 48], 64'h0000000080000001);
	KeccakF1600Perm0 Perm1_0_23(OBuf[46 + 48], IBuf[46 + 48]);
	KeccakF1600Perm1 Perm1_1_23(OBuf[47 + 48], IBuf[47 + 48], 64'h8000000080008008);

	// Keccakf-1600 iteration 2
	
	KeccakF1600Perm0 Perm2_0_0(OBuf[0 + 96], IBuf[0 + 96]);
	KeccakF1600Perm1 Perm2_1_0(OBuf[1 + 96], IBuf[1 + 96], 64'h0000000000000001);
	KeccakF1600Perm0 Perm2_0_1(OBuf[2 + 96], IBuf[2 + 96]);
	KeccakF1600Perm1 Perm2_1_1(OBuf[3 + 96], IBuf[3 + 96], 64'h0000000000008082);
	KeccakF1600Perm0 Perm2_0_2(OBuf[4 + 96], IBuf[4 + 96]);
	KeccakF1600Perm1 Perm2_1_2(OBuf[5 + 96], IBuf[5 + 96], 64'h800000000000808a);
	KeccakF1600Perm0 Perm2_0_3(OBuf[6 + 96], IBuf[6 + 96]);
	KeccakF1600Perm1 Perm2_1_3(OBuf[7 + 96], IBuf[7 + 96], 64'h8000000080008000);
	KeccakF1600Perm0 Perm2_0_4(OBuf[8 + 96], IBuf[8 + 96]);
	KeccakF1600Perm1 Perm2_1_4(OBuf[9 + 96], IBuf[9 + 96], 64'h000000000000808b);
	KeccakF1600Perm0 Perm2_0_5(OBuf[10 + 96], IBuf[10 + 96]);
	KeccakF1600Perm1 Perm2_1_5(OBuf[11 + 96], IBuf[11 + 96], 64'h0000000080000001);
	KeccakF1600Perm0 Perm2_0_6(OBuf[12 + 96], IBuf[12 + 96]);
	KeccakF1600Perm1 Perm2_1_6(OBuf[13 + 96], IBuf[13 + 96], 64'h8000000080008081);
	KeccakF1600Perm0 Perm2_0_7(OBuf[14 + 96], IBuf[14 + 96]);
	KeccakF1600Perm1 Perm2_1_7(OBuf[15 + 96], IBuf[15 + 96], 64'h8000000000008009);
	KeccakF1600Perm0 Perm2_0_8(OBuf[16 + 96], IBuf[16 + 96]);
	KeccakF1600Perm1 Perm2_1_8(OBuf[17 + 96], IBuf[17 + 96], 64'h000000000000008a);
	KeccakF1600Perm0 Perm2_0_9(OBuf[18 + 96], IBuf[18 + 96]);
	KeccakF1600Perm1 Perm2_1_9(OBuf[19 + 96], IBuf[19 + 96], 64'h0000000000000088);
	KeccakF1600Perm0 Perm2_0_10(OBuf[20 + 96], IBuf[20 + 96]);
	KeccakF1600Perm1 Perm2_1_10(OBuf[21 + 96], IBuf[21 + 96], 64'h0000000080008009);
	KeccakF1600Perm0 Perm2_0_11(OBuf[22 + 96], IBuf[22 + 96]);
	KeccakF1600Perm1 Perm2_1_11(OBuf[23 + 96], IBuf[23 + 96], 64'h000000008000000a);
	KeccakF1600Perm0 Perm2_0_12(OBuf[24 + 96], IBuf[24 + 96]);
	KeccakF1600Perm1 Perm2_1_12(OBuf[25 + 96], IBuf[25 + 96], 64'h000000008000808b);
	KeccakF1600Perm0 Perm2_0_13(OBuf[26 + 96], IBuf[26 + 96]);
	KeccakF1600Perm1 Perm2_1_13(OBuf[27 + 96], IBuf[27 + 96], 64'h800000000000008b);
	KeccakF1600Perm0 Perm2_0_14(OBuf[28 + 96], IBuf[28 + 96]);
	KeccakF1600Perm1 Perm2_1_14(OBuf[29 + 96], IBuf[29 + 96], 64'h8000000000008089);
	KeccakF1600Perm0 Perm2_0_15(OBuf[30 + 96], IBuf[30 + 96]);
	KeccakF1600Perm1 Perm2_1_15(OBuf[31 + 96], IBuf[31 + 96], 64'h8000000000008003);
	KeccakF1600Perm0 Perm2_0_16(OBuf[32 + 96], IBuf[32 + 96]);
	KeccakF1600Perm1 Perm2_1_16(OBuf[33 + 96], IBuf[33 + 96], 64'h8000000000008002);
	KeccakF1600Perm0 Perm2_0_17(OBuf[34 + 96], IBuf[34 + 96]);
	KeccakF1600Perm1 Perm2_1_17(OBuf[35 + 96], IBuf[35 + 96], 64'h8000000000000080);
	KeccakF1600Perm0 Perm2_0_18(OBuf[36 + 96], IBuf[36 + 96]);
	KeccakF1600Perm1 Perm2_1_18(OBuf[37 + 96], IBuf[37 + 96], 64'h000000000000800a);
	KeccakF1600Perm0 Perm2_0_19(OBuf[38 + 96], IBuf[38 + 96]);
	KeccakF1600Perm1 Perm2_1_19(OBuf[39 + 96], IBuf[39 + 96], 64'h800000008000000a);
	KeccakF1600Perm0 Perm2_0_20(OBuf[40 + 96], IBuf[40 + 96]);
	KeccakF1600Perm1 Perm2_1_20(OBuf[41 + 96], IBuf[41 + 96], 64'h8000000080008081);
	KeccakF1600Perm0 Perm2_0_21(OBuf[42 + 96], IBuf[42 + 96]);
	KeccakF1600Perm1 Perm2_1_21(OBuf[43 + 96], IBuf[43 + 96], 64'h8000000000008080);
	KeccakF1600Perm0 Perm2_0_22(OBuf[44 + 96], IBuf[44 + 96]);
	KeccakF1600Perm1 Perm2_1_22(OBuf[45 + 96], IBuf[45 + 96], 64'h0000000080000001);
	KeccakF1600Perm0 Perm2_0_23(OBuf[46 + 96], IBuf[46 + 96]);
	KeccakF1600Perm1 Perm2_1_23(OBuf[47 + 96], IBuf[47 + 96], 64'h8000000080008008);
	
endmodule

module KeccakF1600Perm0(output wire [1599:0] OutState, input wire [1599:0] InState);
	
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
	
	wire [63:0] Mid0, Mid1, Mid2, Mid3, Mid4, Mid5, Mid6, Mid7, Mid8;
	wire [63:0] Mid9, Mid10, Mid11, Mid12, Mid13, Mid14, Mid15, Mid16;
	wire [63:0] Mid17, Mid18, Mid19, Mid20, Mid21, Mid22, Mid23, Mid24;
	wire [63:0] InitXORVals0, InitXORVals1, InitXORVals2, InitXORVals3, InitXORVals4;
	//wire [63:0] MainXORVals0, MainXORVals1, MainXORVals2, MainXORVals3, MainXORVals4;
		
	// Theta
	assign InitXORVals0 = InState[`IDX64(0 + 0)] ^ InState[`IDX64(5 + 0)] ^ InState[`IDX64(10 + 0)] ^ InState[`IDX64(15 + 0)] ^ InState[`IDX64(20 + 0)];
	assign InitXORVals1 = InState[`IDX64(0 + 1)] ^ InState[`IDX64(5 + 1)] ^ InState[`IDX64(10 + 1)] ^ InState[`IDX64(15 + 1)] ^ InState[`IDX64(20 + 1)];
	assign InitXORVals2 = InState[`IDX64(0 + 2)] ^ InState[`IDX64(5 + 2)] ^ InState[`IDX64(10 + 2)] ^ InState[`IDX64(15 + 2)] ^ InState[`IDX64(20 + 2)];
	assign InitXORVals3 = InState[`IDX64(0 + 3)] ^ InState[`IDX64(5 + 3)] ^ InState[`IDX64(10 + 3)] ^ InState[`IDX64(15 + 3)] ^ InState[`IDX64(20 + 3)];
	assign InitXORVals4 = InState[`IDX64(0 + 4)] ^ InState[`IDX64(5 + 4)] ^ InState[`IDX64(10 + 4)] ^ InState[`IDX64(15 + 4)] ^ InState[`IDX64(20 + 4)];

	// Leads to suboptimal synthesis
	//assign MainXORVals0 = InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	//assign MainXORVals1 = InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	//assign MainXORVals2 = InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	//assign MainXORVals3 = InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	//assign MainXORVals4 = InitXORVals4 ^ `ROTL64(InitXORVals1, 1);

	assign Mid1 = InState[`IDX64(6)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(1)] = `ROTL64(Mid1, 44);
	assign Mid8 = InState[`IDX64(16)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(8)] = `ROTL64(Mid8, 45);
	assign Mid10 = InState[`IDX64(1)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(10)] = `ROTL64(Mid10, 1);
	assign Mid17 = InState[`IDX64(11)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(17)] = `ROTL64(Mid17, 10);
	assign Mid24 = InState[`IDX64(21)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(24)] = `ROTL64(Mid24, 2);
	
	assign Mid2 = InState[`IDX64(12)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(2)] = `ROTL64(Mid2, 43);
	assign Mid9 = InState[`IDX64(22)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(9)] = `ROTL64(Mid9, 61);
	assign Mid11 = InState[`IDX64(7)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(11)] = `ROTL64(Mid11, 6);
	assign Mid18 = InState[`IDX64(17)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(18)] = `ROTL64(Mid18, 15);
	assign Mid20 = InState[`IDX64(2)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(20)] = `ROTL64(Mid20, 62);
	
	assign Mid3 = InState[`IDX64(18)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(3)] = `ROTL64(Mid3, 21);
	assign Mid5 = InState[`IDX64(3)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(5)] = `ROTL64(Mid5, 28);
	assign Mid12 = InState[`IDX64(13)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(12)] = `ROTL64(Mid12, 25);
	assign Mid19 = InState[`IDX64(23)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(19)] = `ROTL64(Mid19, 56);
	assign Mid21 = InState[`IDX64(8)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(21)] = `ROTL64(Mid21, 55);
	
	assign Mid4 = InState[`IDX64(24)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(4)] = `ROTL64(Mid4, 14);
	assign Mid6 = InState[`IDX64(9)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(6)] = `ROTL64(Mid6, 20);
	assign Mid13 = InState[`IDX64(19)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(13)] = `ROTL64(Mid13, 8);
	assign Mid15 = InState[`IDX64(4)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(15)] = `ROTL64(Mid15, 27);
	assign Mid22 = InState[`IDX64(14)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(22)] = `ROTL64(Mid22, 39);
	
	assign Mid0 = InState[`IDX64(0)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(0)] = Mid0;
	assign Mid7 = InState[`IDX64(10)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(7)] = `ROTL64(Mid7, 3);
	assign Mid14 = InState[`IDX64(20)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(14)] = `ROTL64(Mid14, 18);
	assign Mid16 = InState[`IDX64(5)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(16)] = `ROTL64(Mid16, 36);
	assign Mid23 = InState[`IDX64(15)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(23)] = `ROTL64(Mid23, 41);
endmodule

module KeccakF1600Perm1(output wire [1599:0] OutState, input wire [1599:0] RoundMid, input wire [63:0] RndConst);
	
	genvar x;

	wire [63:0] FirstQwordCopy;
	
	// Chi
	assign FirstQwordCopy = RoundMid[`IDX64(0)] ^ ((~RoundMid[`IDX64(1)]) & RoundMid[`IDX64(2)]);
	assign OutState[`IDX64(1)] = RoundMid[`IDX64(1)] ^ ((~RoundMid[`IDX64(2)]) & RoundMid[`IDX64(3)]);
	assign OutState[`IDX64(2)] = RoundMid[`IDX64(2)] ^ ((~RoundMid[`IDX64(3)]) & RoundMid[`IDX64(4)]);
	assign OutState[`IDX64(3)] = RoundMid[`IDX64(3)] ^ ((~RoundMid[`IDX64(4)]) & RoundMid[`IDX64(0)]);
	assign OutState[`IDX64(4)] = RoundMid[`IDX64(4)] ^ ((~RoundMid[`IDX64(0)]) & RoundMid[`IDX64(1)]);
	
	generate
	
		for(x = 5; x < 25; x = x + 5)
		begin : CHILOOP0
			assign OutState[`IDX64(0 + x)] = RoundMid[`IDX64(0 + x)] ^ ((~RoundMid[`IDX64(1 + x)]) & RoundMid[`IDX64(2 + x)]);
			assign OutState[`IDX64(1 + x)] = RoundMid[`IDX64(1 + x)] ^ ((~RoundMid[`IDX64(2 + x)]) & RoundMid[`IDX64(3 + x)]);
			assign OutState[`IDX64(2 + x)] = RoundMid[`IDX64(2 + x)] ^ ((~RoundMid[`IDX64(3 + x)]) & RoundMid[`IDX64(4 + x)]);
			assign OutState[`IDX64(3 + x)] = RoundMid[`IDX64(3 + x)] ^ ((~RoundMid[`IDX64(4 + x)]) & RoundMid[`IDX64(0 + x)]);
			assign OutState[`IDX64(4 + x)] = RoundMid[`IDX64(4 + x)] ^ ((~RoundMid[`IDX64(0 + x)]) & RoundMid[`IDX64(1 + x)]);
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

