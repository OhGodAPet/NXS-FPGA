`timescale 1ns / 1ps
`default_nettype none

`define IDX64(x)            ((x) << 6)+:64
`define ROTR1088(x, y)		{x[(y) - 1 : 0], x[1087 : y]}

// To use, put state on the InState wires, with InKey and InType set as well.
// Bring DataValid high, and it will accept input on these wires once per clock
// as long as DataValid remains held high.
module Skein1024Block(output wire [1023:0] OutState, output wire OutputValid, input wire clk, input wire DataValid, input wire [1023:0] InState, input wire [1087:0] InKey, input wire [191:0] InType);

	localparam ROUNDS = 20, KEYINJECTIONS = 21;
	localparam STAGES = ROUNDS + KEYINJECTIONS, ROUNDSTAGES = 5, KEYSTAGES = 1;
	
	localparam TOTALSTAGES = (ROUNDSTAGES * ROUNDS) + (KEYINJECTIONS * KEYSTAGES);
	
	reg [1023:0] IBuf[STAGES-1:0];
	reg [1087:0] KeyBuf[STAGES-1:0];
	reg [191:0] TypeBuf[STAGES-1:0];
	reg [TOTALSTAGES-1:0] PipeOutputGood = 0;
	
	wire [1023:0] OBuf[STAGES-1:0];
		
	assign OutputValid = PipeOutputGood[TOTALSTAGES-1];
	assign OutState = OBuf[STAGES-1];
	
	genvar x;
	integer i;

	always @(posedge clk)
	begin
		IBuf[0] <= InState;
		KeyBuf[0] <= InKey;
		TypeBuf[0] <= InType;
		
		for(i = 1; i < STAGES; i = i + 1)
		begin : PIPECYCLELOOP
			IBuf[i] <= OBuf[i - 1];
			KeyBuf[i] <= KeyBuf[i - 1];
			TypeBuf[i] <= TypeBuf[i - 1];
		end
		
		PipeOutputGood = (PipeOutputGood << 1) | DataValid;
	end

	// Due to ROTR1088 not being truly circular, values greater than 16
	// will break it - as well as a value of zero. Therefore, the first
	// round and the final four rounds (as well as the final key
	// injection) are removed from the loop and placed outside it.
	
	SkeinInjectKey #(.RNDNUM(0), .RNDNUM_MOD_3(0)) FirstKeyInjection(OBuf[0], clk, IBuf[0], KeyBuf[0], TypeBuf[0]);
	SkeinEvenRound FirstRound(OBuf[1], clk, IBuf[1]);
	
	// Loop for all rounds from 1 - 17, skipping 0, 18, and 19.
	for(x = 1; x < 17; x = x + 1)
	begin : MAINRNDINSTANTIATIONLOOP
		// A shift up by six is done to multiply the rotation constant by 64 before use.
		// Note that the mod is done on a synthesis time constant which will be optimized out.
		SkeinInjectKey #(.RNDNUM(x), .RNDNUM_MOD_3(x % 3)) KeyInjection(OBuf[x << 1], clk, IBuf[x << 1], `ROTR1088(KeyBuf[x << 1], x << 6), TypeBuf[x << 1]);
			
		if(x & 1)
		begin
			SkeinOddRound OddRound(OBuf[(x << 1) + 1], clk, IBuf[(x << 1) + 1]);
		end else
		begin
			SkeinEvenRound EvenRound(OBuf[(x << 1) + 1], clk, IBuf[(x << 1) + 1]);
		end	
	end
	
	// Key rotation for this round is a no-op.
	SkeinInjectKey #(.RNDNUM(17), .RNDNUM_MOD_3(2)) KeyInjection17(OBuf[34], clk, IBuf[34], KeyBuf[34], TypeBuf[34]);
	SkeinOddRound OddRound17(OBuf[35], clk, IBuf[35]);
	
	SkeinInjectKey #(.RNDNUM(18), .RNDNUM_MOD_3(0)) KeyInjection18(OBuf[36], clk, IBuf[36], `ROTR1088(KeyBuf[36], 64), TypeBuf[36]);
	SkeinEvenRound EvenRound18(OBuf[37], clk, IBuf[37]);

	SkeinInjectKey #(.RNDNUM(19), .RNDNUM_MOD_3(1)) KeyInjection19(OBuf[38], clk, IBuf[38], `ROTR1088(KeyBuf[38], 128), TypeBuf[38]);
	SkeinOddRound OddRound19(OBuf[39], clk, IBuf[39]);
	
	SkeinInjectKey #(.RNDNUM(20), .RNDNUM_MOD_3(2)) KeyInjection20(OBuf[40], clk, IBuf[40], `ROTR1088(KeyBuf[40], 192), TypeBuf[40]);
	
endmodule
