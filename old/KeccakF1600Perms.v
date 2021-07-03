`timescale 1ns / 1ps
`default_nettype none

`define IDX64(x)			((x) << 6)+:64
`define ROTL64(x, y)		{x[63 - y : 0], x[63: 63 - y + 1]}

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
	
	wire [63:0] Mid[24:0];
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

	assign Mid[1] = InState[`IDX64(6)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(1)] = `ROTL64(Mid[1], 44);
	assign Mid[8] = InState[`IDX64(16)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(8)] = `ROTL64(Mid[8], 45);
	assign Mid[10] = InState[`IDX64(1)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(10)] = `ROTL64(Mid[10], 1);
	assign Mid[17] = InState[`IDX64(11)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(17)] = `ROTL64(Mid[17], 10);
	assign Mid[24] = InState[`IDX64(21)] ^ InitXORVals0 ^ `ROTL64(InitXORVals2, 1);
	assign OutState[`IDX64(24)] = `ROTL64(Mid[24], 2);
	
	assign Mid[2] = InState[`IDX64(12)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(2)] = `ROTL64(Mid[2], 43);
	assign Mid[9] = InState[`IDX64(22)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(9)] = `ROTL64(Mid[9], 61);
	assign Mid[11] = InState[`IDX64(7)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(11)] = `ROTL64(Mid[11], 6);
	assign Mid[18] = InState[`IDX64(17)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(18)] = `ROTL64(Mid[18], 15);
	assign Mid[20] = InState[`IDX64(2)] ^ InitXORVals1 ^ `ROTL64(InitXORVals3, 1);
	assign OutState[`IDX64(20)] = `ROTL64(Mid[20], 62);
	
	assign Mid[3] = InState[`IDX64(18)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(3)] = `ROTL64(Mid[3], 21);
	assign Mid[5] = InState[`IDX64(3)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(5)] = `ROTL64(Mid[5], 28);
	assign Mid[12] = InState[`IDX64(13)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(12)] = `ROTL64(Mid[12], 25);
	assign Mid[19] = InState[`IDX64(23)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(19)] = `ROTL64(Mid[19], 56);
	assign Mid[21] = InState[`IDX64(8)] ^ InitXORVals2 ^ `ROTL64(InitXORVals4, 1);
	assign OutState[`IDX64(21)] = `ROTL64(Mid[21], 55);
	
	assign Mid[4] = InState[`IDX64(24)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(4)] = `ROTL64(Mid[4], 14);
	assign Mid[6] = InState[`IDX64(9)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(6)] = `ROTL64(Mid[6], 20);
	assign Mid[13] = InState[`IDX64(19)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(13)] = `ROTL64(Mid[13], 8);
	assign Mid[15] = InState[`IDX64(4)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(15)] = `ROTL64(Mid[15], 27);
	assign Mid[22] = InState[`IDX64(14)] ^ InitXORVals3 ^ `ROTL64(InitXORVals0, 1);
	assign OutState[`IDX64(22)] = `ROTL64(Mid[22], 39);
	
	assign Mid[0] = InState[`IDX64(0)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(0)] = Mid[0];
	assign Mid[7] = InState[`IDX64(10)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(7)] = `ROTL64(Mid[7], 3);
	assign Mid[14] = InState[`IDX64(20)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(14)] = `ROTL64(Mid[14], 18);
	assign Mid[16] = InState[`IDX64(5)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(16)] = `ROTL64(Mid[16], 36);
	assign Mid[23] = InState[`IDX64(15)] ^ InitXORVals4 ^ `ROTL64(InitXORVals1, 1);
	assign OutState[`IDX64(23)] = `ROTL64(Mid[23], 41);
endmodule

module Bitselect(output wire [63:0] Result, input wire [63:0] A, input wire [63:0] B, input wire [63:0] C);
    assign Result = (A & C) | (B & (~C));
endmodule

module KeccakF1600Perm1(output wire [1599:0] OutState, input wire [1599:0] RoundMid, input wire [63:0] RndConst);
	
	genvar x;

	wire [63:0] FirstQwordCopy;
	
	Bitselect BS0(FirstQwordCopy, RoundMid[`IDX64(0)] ^ RoundMid[`IDX64(2)], RoundMid[`IDX64(0)], RoundMid[`IDX64(1)]);
	Bitselect BS1(OutState[`IDX64(1)], RoundMid[`IDX64(1)] ^ RoundMid[`IDX64(3)], RoundMid[`IDX64(1)], RoundMid[`IDX64(2)]);
	Bitselect BS2(OutState[`IDX64(2)], RoundMid[`IDX64(2)] ^ RoundMid[`IDX64(4)], RoundMid[`IDX64(2)], RoundMid[`IDX64(3)]);
	Bitselect BS3(OutState[`IDX64(3)], RoundMid[`IDX64(3)] ^ RoundMid[`IDX64(0)], RoundMid[`IDX64(3)], RoundMid[`IDX64(4)]);
	Bitselect BS4(OutState[`IDX64(4)], RoundMid[`IDX64(4)] ^ RoundMid[`IDX64(1)], RoundMid[`IDX64(4)], RoundMid[`IDX64(0)]);
	
	generate
	
	for(x = 5; x < 25; x = x + 5)
    begin : CHILOOP
        Bitselect BS5(RoundMid[`IDX64(0 + x)] ^ RoundMid[`IDX64(2 + x)], RoundMid[`IDX64(0) + x], RoundMid[`IDX64(1 + x)]);
	    Bitselect BS6(RoundMid[`IDX64(1 + x)] ^ RoundMid[`IDX64(3 + x)], RoundMid[`IDX64(1 + x)], RoundMid[`IDX64(2 + x)]);
	    Bitselect BS7(RoundMid[`IDX64(2 + x)] ^ RoundMid[`IDX64(4 + x)], RoundMid[`IDX64(2 + x)], RoundMid[`IDX64(3 + x)]);
	    Bitselect BS8(RoundMid[`IDX64(3 + x)] ^ RoundMid[`IDX64(0 + x)], RoundMid[`IDX64(3 + x)], RoundMid[`IDX64(4 + x)]);
	    Bitselect BS9(RoundMid[`IDX64(4 + x)] ^ RoundMid[`IDX64(1 + x)], RoundMid[`IDX64(4 + x)], RoundMid[`IDX64(0 + x)]);
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
