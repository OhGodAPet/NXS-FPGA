`timescale 1ns / 1ps

`define IDX64(x)            ((x) << 6)+:64

module NexusHashTransform(output reg [63:0] NonceOut, output reg GoodNonceFound, input clk, input nHashRst, input [1727:0] WorkPkt, input [63:0] InNonce);
	
	parameter HASHERS = 1, COREIDX = 0;
	
	// Every Skein round has four clock cycles of latency, and every
	// Skein key injection has 2 clock cycles of latency
	localparam SKEINRNDSTAGES = 4, SKEINKEYSTAGES = 2;
	
	// Every Keccak round has two clock cycles of latency,
	// and there are 24 rounds
	localparam KECCAKRNDSTAGES = 2, KECCAKROUNDS = 24;
	
	// 20 rounds, with 21 key injections per block process
	localparam SKEINROUNDS = 20, SKEINKEYINJECTIONS = 21;
	
	// 24 rounds, round has 2 clock cycles of latency
	localparam KECCAKBLKSTAGES = KECCAKRNDSTAGES * KECCAKROUNDS;
	
	// 20 rounds, 4 clock cycles of latency per round, and 21 key
	// injections, 2 clock cycles of latency per key injection
	localparam SKEINBLKSTAGES = (SKEINRNDSTAGES * SKEINROUNDS) + (SKEINKEYINJECTIONS * SKEINKEYSTAGES);
	
	// Nexus' SK1024 proof-of-work, SK1024 (after midstate, during which
	// one Skein block process is done) consists of two Skein block processes
	// and three Keccak block processes.
	localparam TOTALSTAGES = (SKEINBLKSTAGES * 2) + (KECCAKBLKSTAGES * 3);	
		
	genvar x;
		
	// Inputs
	reg [TOTALSTAGES-1:0] PipeOutputGood = 0;
	reg [639:0] BlkHdrTail;
	reg [1087:0] Midstate;
	reg [63:0] CurNonce;
		
	wire [1087:0] SkeinOutput0;
	wire [1023:0] SkeinOutput1;
	wire [63:0] KeccakOutputQword;
	
    
    always @(posedge clk)
	begin
		// Active-low reset pulled low, reload work
		if(~nHashRst)
		begin
			PipeOutputGood <= 0;
			BlkHdrTail <= WorkPkt[639:0];
			Midstate <= WorkPkt[1727:640];
			CurNonce <= InNonce;
		end else
		begin
			CurNonce <= CurNonce + 1'b1;
		end
		
		PipeOutputGood <= (PipeOutputGood << 1) | nHashRst;
		
		// Lazy target check - check for 32 bits of zero, and filter further
		// on the miner side; I am cheap and dirty
		GoodNonceFound <= PipeOutputGood[TOTALSTAGES-1] & (KeccakOutputQword[63:32] == 32'b0);
		NonceOut <= CurNonce - 390;
	end
	
	FirstSkeinRound Block1ProcessTest(SkeinOutput0, clk, BlkHdrTail[639:0], Midstate, CurNonce);
	SecondSkeinRound Block2ProcessTest(SkeinOutput1, clk, SkeinOutput0);
	NexusKeccak1024 KeccakProcessTest(KeccakOutputQword, clk, SkeinOutput1);
endmodule