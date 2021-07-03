`timescale 1ns / 1ps
`default_nettype none

`define IDX64(x)            ((x) << 6)+:64
`define ROTL64(x, y)		(((x) << (y)) | ((x) >> (64 - (y))))

//`define QOR_PIPE_STAGE              1

module SkeinMix8(output wire [511:0] OutEven, output wire [511:0] OutOdd, input wire [511:0] InEven, input wire [511:0] InOdd);
	
	parameter R0 = 0, R1 = 0, R2 = 0, R3 = 0, R4 = 0, R5 = 0, R6 = 0, R7 = 0;
	genvar x;
	
	wire [511:0] TempEven, TempOdd;

	for(x = 0; x < 8; x = x + 1)
	begin : MIXADDLOOP
		assign TempEven[`IDX64(x)] = InEven[`IDX64(x)] + InOdd[`IDX64(x)];
	end
	
	// SkeinMix8 permutes the data in the same fashion,
	// every time. For the even half, it is:
	// (0, 1, 3, 2, 5, 6, 7, 4), and for the odd half:
	// (4, 6, 5, 7, 3, 1, 2, 0). These permutations will
	// cause the state to return to its original order
	// after it is done four times in the round functions.
	
	// This function is called a hell of a lot; keep it tighter
	// than a nun's tailhole.

    assign OutOdd[`IDX64(0)] = TempEven[`IDX64(4)] ^ `ROTL64(InOdd[`IDX64(4)], R4);
	assign OutOdd[`IDX64(1)] = TempEven[`IDX64(6)] ^ `ROTL64(InOdd[`IDX64(6)], R6);
	assign OutOdd[`IDX64(2)] = TempEven[`IDX64(5)] ^ `ROTL64(InOdd[`IDX64(5)], R5);
	assign OutOdd[`IDX64(3)] = TempEven[`IDX64(7)] ^ `ROTL64(InOdd[`IDX64(7)], R7);
	assign OutOdd[`IDX64(4)] = TempEven[`IDX64(3)] ^ `ROTL64(InOdd[`IDX64(3)], R3);
	assign OutOdd[`IDX64(5)] = TempEven[`IDX64(1)] ^ `ROTL64(InOdd[`IDX64(1)], R1);
	assign OutOdd[`IDX64(6)] = TempEven[`IDX64(2)] ^ `ROTL64(InOdd[`IDX64(2)], R2);
	assign OutOdd[`IDX64(7)] = TempEven[`IDX64(0)] ^ `ROTL64(InOdd[`IDX64(0)], R0);
	
	assign OutEven[`IDX64(0)] = TempEven[`IDX64(0)];
	assign OutEven[`IDX64(1)] = TempEven[`IDX64(1)];
	assign OutEven[`IDX64(2)] = TempEven[`IDX64(3)];
	assign OutEven[`IDX64(3)] = TempEven[`IDX64(2)];
	assign OutEven[`IDX64(4)] = TempEven[`IDX64(5)];
	assign OutEven[`IDX64(5)] = TempEven[`IDX64(6)];
	assign OutEven[`IDX64(6)] = TempEven[`IDX64(7)];
	assign OutEven[`IDX64(7)] = TempEven[`IDX64(4)];
endmodule

`ifdef QOR_PIPE_STAGE

module SkeinEvenRound(output wire [1023:0] Out, input wire clk, input wire [1023:0] In);
	
	genvar x;

	// MixInputs holds the even qwords in its low half,
	// and holds the odd qwords in its high half.
	reg [1023:0] MixInputs[3:0];
	wire [1023:0] FirstMixInput;
	wire [1023:0] MixOutputs[3:0];
	
	assign FirstMixInput[`IDX64(0)] = In[`IDX64(0)];
	assign FirstMixInput[`IDX64(1)] = In[`IDX64(2)];
	assign FirstMixInput[`IDX64(2)] = In[`IDX64(4)];
	assign FirstMixInput[`IDX64(3)] = In[`IDX64(6)];
	assign FirstMixInput[`IDX64(4)] = In[`IDX64(8)];
	assign FirstMixInput[`IDX64(5)] = In[`IDX64(10)];
	assign FirstMixInput[`IDX64(6)] = In[`IDX64(12)];
	assign FirstMixInput[`IDX64(7)] = In[`IDX64(14)];
	
	assign FirstMixInput[`IDX64(8)] = In[`IDX64(1)];
	assign FirstMixInput[`IDX64(9)] = In[`IDX64(3)];
	assign FirstMixInput[`IDX64(10)] = In[`IDX64(5)];
	assign FirstMixInput[`IDX64(11)] = In[`IDX64(7)];
	assign FirstMixInput[`IDX64(12)] = In[`IDX64(9)];
	assign FirstMixInput[`IDX64(13)] = In[`IDX64(11)];
	assign FirstMixInput[`IDX64(14)] = In[`IDX64(13)];
	assign FirstMixInput[`IDX64(15)] = In[`IDX64(15)];
	
	SkeinMix8 #(.R0(55), .R1(43), .R2(37), .R3(40), .R4(16), .R5(22), .R6(38), .R7(12)) Mix0(MixOutputs[0][511:0], MixOutputs[0][1023:512], MixInputs[0][511:0], MixInputs[0][1023:512]);
	SkeinMix8 #(.R0(25), .R1(25), .R2(46), .R3(13), .R4(14), .R5(13), .R6(52), .R7(57)) Mix1(MixOutputs[1][511:0], MixOutputs[1][1023:512], MixInputs[1][511:0], MixInputs[1][1023:512]);
	SkeinMix8 #(.R0(33), .R1( 8), .R2(18), .R3(57), .R4(21), .R5(12), .R6(32), .R7(54)) Mix2(MixOutputs[2][511:0], MixOutputs[2][1023:512], MixInputs[2][511:0], MixInputs[2][1023:512]);
	SkeinMix8 #(.R0(34), .R1(43), .R2(25), .R3(60), .R4(44), .R5( 9), .R6(59), .R7(34)) Mix3(MixOutputs[3][511:0], MixOutputs[3][1023:512], MixInputs[3][511:0], MixInputs[3][1023:512]);
	
	always @(posedge clk)
	begin
		//MixInputs[0] <= MixOutputs[0];
		MixInputs[0] <= FirstMixInput;
		MixInputs[1] <= MixOutputs[0];
		MixInputs[2] <= MixOutputs[1];
		MixInputs[3] <= MixOutputs[2];
	end

	// We must un-do the even/odd seperation, creating this permutation:
	// (0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15)

	assign Out[`IDX64(0)] = MixOutputs[3][`IDX64(0)];
	assign Out[`IDX64(2)] = MixOutputs[3][`IDX64(1)];
	assign Out[`IDX64(4)] = MixOutputs[3][`IDX64(2)];
	assign Out[`IDX64(6)] = MixOutputs[3][`IDX64(3)];
	assign Out[`IDX64(8)] = MixOutputs[3][`IDX64(4)];
	assign Out[`IDX64(10)] = MixOutputs[3][`IDX64(5)];
	assign Out[`IDX64(12)] = MixOutputs[3][`IDX64(6)];
	assign Out[`IDX64(14)] = MixOutputs[3][`IDX64(7)];

	assign Out[`IDX64(1)] = MixOutputs[3][`IDX64(8)];
	assign Out[`IDX64(3)] = MixOutputs[3][`IDX64(9)];
	assign Out[`IDX64(5)] = MixOutputs[3][`IDX64(10)];
	assign Out[`IDX64(7)] = MixOutputs[3][`IDX64(11)];
	assign Out[`IDX64(9)] = MixOutputs[3][`IDX64(12)];
	assign Out[`IDX64(11)] = MixOutputs[3][`IDX64(13)];
	assign Out[`IDX64(13)] = MixOutputs[3][`IDX64(14)];
	assign Out[`IDX64(15)] = MixOutputs[3][`IDX64(15)];
endmodule

module SkeinOddRound(output wire [1023:0] Out, input wire clk, input wire [1023:0] In);
	
	genvar x;

	// MixInputs holds the even qwords in its low half,
	// and holds the odd qwords in its high half.
	reg [1023:0] MixInputs[3:0];
	wire [1023:0] FirstMixInput;
	wire [1023:0] MixOutputs[3:0];

	assign FirstMixInput[`IDX64(0)] = In[`IDX64(0)];
	assign FirstMixInput[`IDX64(8)] = In[`IDX64(1)];
	assign FirstMixInput[`IDX64(1)] = In[`IDX64(2)];
	assign FirstMixInput[`IDX64(9)] = In[`IDX64(3)];
	assign FirstMixInput[`IDX64(2)] = In[`IDX64(4)];
	assign FirstMixInput[`IDX64(10)] = In[`IDX64(5)];
	assign FirstMixInput[`IDX64(3)] = In[`IDX64(6)];
	assign FirstMixInput[`IDX64(11)] = In[`IDX64(7)];
	
	assign FirstMixInput[`IDX64(4)] = In[`IDX64(8)];
	assign FirstMixInput[`IDX64(12)] = In[`IDX64(9)];
	assign FirstMixInput[`IDX64(5)] = In[`IDX64(10)];
	assign FirstMixInput[`IDX64(13)] = In[`IDX64(11)];
	assign FirstMixInput[`IDX64(6)] = In[`IDX64(12)];
	assign FirstMixInput[`IDX64(14)] = In[`IDX64(13)];
	assign FirstMixInput[`IDX64(7)] = In[`IDX64(14)];
	assign FirstMixInput[`IDX64(15)] = In[`IDX64(15)];
	
	SkeinMix8 #(.R0(28), .R1( 7), .R2(47), .R3(48), .R4(51), .R5( 9), .R6(35), .R7(41)) Mix0(MixOutputs[0][511:0], MixOutputs[0][1023:512], MixInputs[0][511:0], MixInputs[0][1023:512]);
	SkeinMix8 #(.R0(17), .R1( 6), .R2(18), .R3(25), .R4(43), .R5(42), .R6(40), .R7(15)) Mix1(MixOutputs[1][511:0], MixOutputs[1][1023:512], MixInputs[1][511:0], MixInputs[1][1023:512]);
	SkeinMix8 #(.R0(58), .R1( 7), .R2(32), .R3(45), .R4(19), .R5(18), .R6( 2), .R7(56)) Mix2(MixOutputs[2][511:0], MixOutputs[2][1023:512], MixInputs[2][511:0], MixInputs[2][1023:512]);
	SkeinMix8 #(.R0(47), .R1(49), .R2(27), .R3(58), .R4(37), .R5(48), .R6(53), .R7(56)) Mix3(MixOutputs[3][511:0], MixOutputs[3][1023:512], MixInputs[3][511:0], MixInputs[3][1023:512]);
	
	always @(posedge clk)
	begin
		MixInputs[0] <= FirstMixInput;
		MixInputs[1] <= MixOutputs[0];
		MixInputs[2] <= MixOutputs[1];
		MixInputs[3] <= MixOutputs[2];
	end

	// We must un-do the even/odd seperation, creating this permutation:
	// (0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15)

	assign Out[`IDX64(0)] = MixOutputs[3][`IDX64(0)];
	assign Out[`IDX64(1)] = MixOutputs[3][`IDX64(8)];
	assign Out[`IDX64(2)] = MixOutputs[3][`IDX64(1)];
	assign Out[`IDX64(3)] = MixOutputs[3][`IDX64(9)];
	assign Out[`IDX64(4)] = MixOutputs[3][`IDX64(2)];
	assign Out[`IDX64(5)] = MixOutputs[3][`IDX64(10)];
	assign Out[`IDX64(6)] = MixOutputs[3][`IDX64(3)];
	assign Out[`IDX64(7)] = MixOutputs[3][`IDX64(11)];

	assign Out[`IDX64(8)] = MixOutputs[3][`IDX64(4)];
	assign Out[`IDX64(9)] = MixOutputs[3][`IDX64(12)];
	assign Out[`IDX64(10)] = MixOutputs[3][`IDX64(5)];
	assign Out[`IDX64(11)] = MixOutputs[3][`IDX64(13)];
	assign Out[`IDX64(12)] = MixOutputs[3][`IDX64(6)];
	assign Out[`IDX64(13)] = MixOutputs[3][`IDX64(14)];
	assign Out[`IDX64(14)] = MixOutputs[3][`IDX64(7)];
	assign Out[`IDX64(15)] = MixOutputs[3][`IDX64(15)];
endmodule

`else


module SkeinEvenRound(output wire [1023:0] Out, input wire clk, input wire [1023:0] In);
	
	genvar x;

	// MixInputs holds the even qwords in its low half,
	// and holds the odd qwords in its high half.
	reg [1023:0] MixInputs[2:0];
	wire [1023:0] FirstMixInput;
	wire [1023:0] MixOutputs[3:0];
	
	assign FirstMixInput[`IDX64(0)] = In[`IDX64(0)];
	assign FirstMixInput[`IDX64(1)] = In[`IDX64(2)];
	assign FirstMixInput[`IDX64(2)] = In[`IDX64(4)];
	assign FirstMixInput[`IDX64(3)] = In[`IDX64(6)];
	assign FirstMixInput[`IDX64(4)] = In[`IDX64(8)];
	assign FirstMixInput[`IDX64(5)] = In[`IDX64(10)];
	assign FirstMixInput[`IDX64(6)] = In[`IDX64(12)];
	assign FirstMixInput[`IDX64(7)] = In[`IDX64(14)];
	
	assign FirstMixInput[`IDX64(8)] = In[`IDX64(1)];
	assign FirstMixInput[`IDX64(9)] = In[`IDX64(3)];
	assign FirstMixInput[`IDX64(10)] = In[`IDX64(5)];
	assign FirstMixInput[`IDX64(11)] = In[`IDX64(7)];
	assign FirstMixInput[`IDX64(12)] = In[`IDX64(9)];
	assign FirstMixInput[`IDX64(13)] = In[`IDX64(11)];
	assign FirstMixInput[`IDX64(14)] = In[`IDX64(13)];
	assign FirstMixInput[`IDX64(15)] = In[`IDX64(15)];
	
	SkeinMix8 #(.R0(55), .R1(43), .R2(37), .R3(40), .R4(16), .R5(22), .R6(38), .R7(12)) Mix0(MixOutputs[0][511:0], MixOutputs[0][1023:512], FirstMixInput[511:0], FirstMixInput[1023:512]);
	SkeinMix8 #(.R0(25), .R1(25), .R2(46), .R3(13), .R4(14), .R5(13), .R6(52), .R7(57)) Mix1(MixOutputs[1][511:0], MixOutputs[1][1023:512], MixInputs[0][511:0], MixInputs[0][1023:512]);
	SkeinMix8 #(.R0(33), .R1( 8), .R2(18), .R3(57), .R4(21), .R5(12), .R6(32), .R7(54)) Mix2(MixOutputs[2][511:0], MixOutputs[2][1023:512], MixInputs[1][511:0], MixInputs[1][1023:512]);
	SkeinMix8 #(.R0(34), .R1(43), .R2(25), .R3(60), .R4(44), .R5( 9), .R6(59), .R7(34)) Mix3(MixOutputs[3][511:0], MixOutputs[3][1023:512], MixInputs[2][511:0], MixInputs[2][1023:512]);
	
	always @(posedge clk)
	begin
		MixInputs[0] <= MixOutputs[0];
		MixInputs[1] <= MixOutputs[1];
		MixInputs[2] <= MixOutputs[2];
	end

	// We must un-do the even/odd seperation, creating this permutation:
	// (0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15)

	assign Out[`IDX64(0)] = MixOutputs[3][`IDX64(0)];
	assign Out[`IDX64(2)] = MixOutputs[3][`IDX64(1)];
	assign Out[`IDX64(4)] = MixOutputs[3][`IDX64(2)];
	assign Out[`IDX64(6)] = MixOutputs[3][`IDX64(3)];
	assign Out[`IDX64(8)] = MixOutputs[3][`IDX64(4)];
	assign Out[`IDX64(10)] = MixOutputs[3][`IDX64(5)];
	assign Out[`IDX64(12)] = MixOutputs[3][`IDX64(6)];
	assign Out[`IDX64(14)] = MixOutputs[3][`IDX64(7)];

	assign Out[`IDX64(1)] = MixOutputs[3][`IDX64(8)];
	assign Out[`IDX64(3)] = MixOutputs[3][`IDX64(9)];
	assign Out[`IDX64(5)] = MixOutputs[3][`IDX64(10)];
	assign Out[`IDX64(7)] = MixOutputs[3][`IDX64(11)];
	assign Out[`IDX64(9)] = MixOutputs[3][`IDX64(12)];
	assign Out[`IDX64(11)] = MixOutputs[3][`IDX64(13)];
	assign Out[`IDX64(13)] = MixOutputs[3][`IDX64(14)];
	assign Out[`IDX64(15)] = MixOutputs[3][`IDX64(15)];
endmodule

module SkeinOddRound(output wire [1023:0] Out, input wire clk, input wire [1023:0] In);
	
	genvar x;

	// MixInputs holds the even qwords in its low half,
	// and holds the odd qwords in its high half.
	reg [1023:0] MixInputs[2:0];
	wire [1023:0] FirstMixInput;
	wire [1023:0] MixOutputs[3:0];

	assign FirstMixInput[`IDX64(0)] = In[`IDX64(0)];
	assign FirstMixInput[`IDX64(8)] = In[`IDX64(1)];
	assign FirstMixInput[`IDX64(1)] = In[`IDX64(2)];
	assign FirstMixInput[`IDX64(9)] = In[`IDX64(3)];
	assign FirstMixInput[`IDX64(2)] = In[`IDX64(4)];
	assign FirstMixInput[`IDX64(10)] = In[`IDX64(5)];
	assign FirstMixInput[`IDX64(3)] = In[`IDX64(6)];
	assign FirstMixInput[`IDX64(11)] = In[`IDX64(7)];
	
	assign FirstMixInput[`IDX64(4)] = In[`IDX64(8)];
	assign FirstMixInput[`IDX64(12)] = In[`IDX64(9)];
	assign FirstMixInput[`IDX64(5)] = In[`IDX64(10)];
	assign FirstMixInput[`IDX64(13)] = In[`IDX64(11)];
	assign FirstMixInput[`IDX64(6)] = In[`IDX64(12)];
	assign FirstMixInput[`IDX64(14)] = In[`IDX64(13)];
	assign FirstMixInput[`IDX64(7)] = In[`IDX64(14)];
	assign FirstMixInput[`IDX64(15)] = In[`IDX64(15)];
	
	SkeinMix8 #(.R0(28), .R1( 7), .R2(47), .R3(48), .R4(51), .R5( 9), .R6(35), .R7(41)) Mix0(MixOutputs[0][511:0], MixOutputs[0][1023:512], FirstMixInput[511:0], FirstMixInput[1023:512]);
	SkeinMix8 #(.R0(17), .R1( 6), .R2(18), .R3(25), .R4(43), .R5(42), .R6(40), .R7(15)) Mix1(MixOutputs[1][511:0], MixOutputs[1][1023:512], MixInputs[0][511:0], MixInputs[0][1023:512]);
	SkeinMix8 #(.R0(58), .R1( 7), .R2(32), .R3(45), .R4(19), .R5(18), .R6( 2), .R7(56)) Mix2(MixOutputs[2][511:0], MixOutputs[2][1023:512], MixInputs[1][511:0], MixInputs[1][1023:512]);
	SkeinMix8 #(.R0(47), .R1(49), .R2(27), .R3(58), .R4(37), .R5(48), .R6(53), .R7(56)) Mix3(MixOutputs[3][511:0], MixOutputs[3][1023:512], MixInputs[2][511:0], MixInputs[2][1023:512]);
	
	always @(posedge clk)
	begin
		MixInputs[0] <= MixOutputs[0];
		MixInputs[1] <= MixOutputs[1];
		MixInputs[2] <= MixOutputs[2];
	end

	// We must un-do the even/odd seperation, creating this permutation:
	// (0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15)

	assign Out[`IDX64(0)] = MixOutputs[3][`IDX64(0)];
	assign Out[`IDX64(1)] = MixOutputs[3][`IDX64(8)];
	assign Out[`IDX64(2)] = MixOutputs[3][`IDX64(1)];
	assign Out[`IDX64(3)] = MixOutputs[3][`IDX64(9)];
	assign Out[`IDX64(4)] = MixOutputs[3][`IDX64(2)];
	assign Out[`IDX64(5)] = MixOutputs[3][`IDX64(10)];
	assign Out[`IDX64(6)] = MixOutputs[3][`IDX64(3)];
	assign Out[`IDX64(7)] = MixOutputs[3][`IDX64(11)];

	assign Out[`IDX64(8)] = MixOutputs[3][`IDX64(4)];
	assign Out[`IDX64(9)] = MixOutputs[3][`IDX64(12)];
	assign Out[`IDX64(10)] = MixOutputs[3][`IDX64(5)];
	assign Out[`IDX64(11)] = MixOutputs[3][`IDX64(13)];
	assign Out[`IDX64(12)] = MixOutputs[3][`IDX64(6)];
	assign Out[`IDX64(13)] = MixOutputs[3][`IDX64(14)];
	assign Out[`IDX64(14)] = MixOutputs[3][`IDX64(7)];
	assign Out[`IDX64(15)] = MixOutputs[3][`IDX64(15)];
endmodule

`endif
