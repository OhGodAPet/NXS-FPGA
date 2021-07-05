`timescale 1ns / 1ps

`define IDX64(x)            ((x) << 6)+:64

//`define PIPED_MIX8			1
//`define PIPED_KEY_INJ		1

// Testbench for the Skein block process implementation
module NexusTransform_tb;
	// Every Skein round has four clock cycles of latency, and every
	// Skein key injection has 2 clock cycles of latency.
	`ifdef PIPED_MIX8
	localparam SKEINRNDSTAGES = 8;
	`else
	localparam SKEINRNDSTAGES = 4;
	`endif
	
	`ifdef PIPED_KEY_INJ
	localparam SKEINKEYSTAGES = 3;
	`else
	localparam SKEINKEYSTAGES = 2;
	`endif
	
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
	// and three Keccak block processes. Add one to account for the extra
	// XOR stage in the first Skein block. Add 2 more cause I missed stages.
	localparam TOTALSTAGES = (SKEINBLKSTAGES * 2) + (KECCAKBLKSTAGES * 3) + 3;	
		
	genvar x;
	
	// Reg
	reg clk = 1'b0, nHashRst = 1'b0;
	
	// Inputs
	wire [1023:0] BlkHdrTail = { 320'b0, 704'h00000000000000007B01B1D000396D8D00000002BD97BE01DB09CB623352A9160F3F29B6F456862DC63E601430361FFA159BF93BBD8FDE57E4A0A20A3C343BA85BBED36C3157023906DF1973D1E4438EDBCD6FE21B65A290 };
	wire [1087:0] Midstate = 1088'h38DD0C4440A756EAE0CBA5A50F952345FA9083AE768CB93D34EC5D92B788F0EA4D089565088FC9758F983C26648260CAB387D86481EB16086DD4E16D6D634C91D2FA7B77076D072D14DF39BD780F792616575E267E2C3E4B77FD99680CC716F3B724DA94566FE7E18059EBCC26E758DE2BEE15A3492386D7A0B0F2BC839976DA4450E101EC5D838A;
	
	reg [TOTALSTAGES-1:0] PipeOutputGood = 0;
	reg [1727:0] TestWorkPkt;
	reg [1023:0] TestInput;
	reg [1087:0] TestKey;
	reg [63:0] FoundNonce, InNonce;
	reg PassedFirstRnd = 1'b0, PassedSkein = 1'b0;
	reg [16:0] PipeStageCtr;
	always #1 clk = ~clk;
	wire ValidNonceFound;
	
    initial
	begin
	
		$dumpfile("SimOutput.lxt2");
		$dumpvars(0, NexusTransform_tb);
		
		#2;
		
        // Initialize input
		TestWorkPkt <= { Midstate, BlkHdrTail[639:0] };
		InNonce <= 64'h00000001FCAFC044;
		
        #2;
        // Zero the pipe stage counter and release reset on the same clk
		PipeStageCtr <= 16'b0;
		nHashRst <= 1'b1;
		
    end
    
    always @(posedge clk)
	begin
		PipeStageCtr <= PipeStageCtr + 1'b1;
		PipeOutputGood <= (PipeOutputGood << 1) | nHashRst;
		
		if(ValidNonceFound)
		begin
			$display("NEXUS FOUND NONCE 0x%h\n", FoundNonce);
			$display("NEXUS PASS. YOUR PIPE IS %d STAGES.\n", PipeStageCtr);
			$finish;
		end
		if(PipeOutputGood[TOTALSTAGES-1]) $display("NEXUS 0x%h.\n", FoundNonce);
	end
	
	//module NexusHashTransform(output reg [63:0] NonceOut, output reg GoodNonceFound, input clk, input nHashRst, input [1727:0] WorkPkt, input [63:0] InNonce);
	NexusHashTransform #(.HASHERS(1), .COREIDX(0)) NexusCore(FoundNonce, ValidNonceFound, clk, nHashRst, TestWorkPkt, InNonce);
endmodule
