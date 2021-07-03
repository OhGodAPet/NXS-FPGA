`timescale 1ns / 1ps
`default_nettype none

`define IDX64(x)			((x) << 6)+:64
`define ROTL64(x, y)		{x[63 - y : 0], x[63: 63 - y + 1]}

module KeccakF1600(output wire [1599:0] OutState, input wire clk, input wire [1599:0] InState);
	// Every round has two clock cycles of latency,
	// and there are 24 rounds per block process.
	localparam KECCAKRNDSTAGES = 2, KECCAKROUNDS = 24;
	localparam STAGES = KECCAKRNDSTAGES * KECCAKROUNDS;

	reg [1599:0] IBuf[STAGES-1:0];
	wire [1599:0] OBuf[STAGES-1:0];
	
	assign OutState = OBuf[STAGES-1];
	
	integer x;
	
	always @(posedge clk)
	begin
		//IBuf[0] <= InState;
				
		// Cycle pipeline
		for(x = 1; x < STAGES; x = x + 1)
		begin : DataMoveLoop
			IBuf[x] <= OBuf[x - 1];
		end
	end

	// Keccakf-1600 iteration 0
	
	KeccakF1600Perm0 Perm0_0(OBuf[0], InState);
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
endmodule
