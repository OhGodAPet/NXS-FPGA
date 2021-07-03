`timescale 1ns / 1ps
`default_nettype none

`define IDX64(x)            ((x) << 6)+:64
`define ROTR1088(x, y)		{x[(y) - 1 : 0], x[1087 : y]}

`define SKEIN_KS_PARITY		64'h5555555555555555

//`define COMBINATORIAL_KEY_INJ		1

//`define QOR_PIPE_STAGE              1

module SkeinInjectKey(output wire [1023:0] OutState, input wire clk, input wire [1023:0] State, input wire [1087:0] RotatedKey, input wire [191:0] Type);
	parameter RNDNUM = 0;
	parameter RNDNUM_MOD_3 = 0;
	
	integer x;
	
	reg [1023:0] TmpState;
	assign OutState = TmpState;
	
	always @(posedge clk)
	begin
		for(x = 0; x < 13; x = x + 1)
		begin : KEYADDLOOP
			TmpState[`IDX64(x)] <= State[`IDX64(x)] + RotatedKey[`IDX64(x)];
		end

		if(RNDNUM_MOD_3 == 0)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + Type[`IDX64(0)];
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + Type[`IDX64(1)];
		end else if(RNDNUM_MOD_3 == 1)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + Type[`IDX64(1)];
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + Type[`IDX64(2)];
		end else if(RNDNUM_MOD_3 == 2)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + Type[`IDX64(2)];
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + Type[`IDX64(0)];
		end

		TmpState[`IDX64(15)] <= State[`IDX64(15)] + RotatedKey[`IDX64(15)] + RNDNUM;
	end
	
endmodule

`ifdef COMBINATORIAL_KEY_INJ

module SkeinInjectKeyNexusBlk0(output wire [1023:0] OutState, input wire clk, input wire [1023:0] State, input wire [1087:0] RotatedKey);
	parameter RNDNUM = 0;
	parameter RNDNUM_MOD_3 = 0;

	genvar x;

	// Type[0] = 0xD8, Type[1] = 0xB000000000000000, Type[2] = 0xB0000000000000D8
	for(x = 0; x < 13; x = x + 1)
	begin : KEYADDLOOP
		assign OutState[`IDX64(x)] = State[`IDX64(x)] + RotatedKey[`IDX64(x)];
	end
	
	if(RNDNUM_MOD_3 == 0)
	begin
		assign OutState[`IDX64(13)] = State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 8'hD8;
		assign OutState[`IDX64(14)] = State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hB000000000000000;
	end else if(RNDNUM_MOD_3 == 1)
	begin
		assign OutState[`IDX64(13)] = State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hB000000000000000;
		assign OutState[`IDX64(14)] = State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hB0000000000000D8;
	end else if(RNDNUM_MOD_3 == 2)
	begin
		assign OutState[`IDX64(13)] = State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hB0000000000000D8;
		assign OutState[`IDX64(14)] = State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 8'hD8;
	end
	
	assign OutState[`IDX64(15)] = State[`IDX64(15)] + RotatedKey[`IDX64(15)] + RNDNUM;

endmodule

module SkeinInjectKeyNexusBlk1(output wire [1023:0] OutState, input wire clk, input wire [1023:0] State, input wire [1087:0] RotatedKey);
	parameter RNDNUM = 0;
	parameter RNDNUM_MOD_3 = 0;

	genvar x;

	// Type[0] = 0x08, Type[1] = 0xFF00000000000000, Type[2] = 0xFF00000000000008
	for(x = 0; x < 13; x = x + 1)
	begin : KEYADDLOOP
		assign OutState[`IDX64(x)] = State[`IDX64(x)] + RotatedKey[`IDX64(x)];
	end
	
	if(RNDNUM_MOD_3 == 0)
	begin
		assign OutState[`IDX64(13)] = State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 8'h08;
		assign OutState[`IDX64(14)] = State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hFF00000000000000;
	end else if(RNDNUM_MOD_3 == 1)
	begin
		assign OutState[`IDX64(13)] = State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hFF00000000000000;
		assign OutState[`IDX64(14)] = State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hFF00000000000008;
	end else if(RNDNUM_MOD_3 == 2)
	begin
		assign OutState[`IDX64(13)] = State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hFF00000000000008;
		assign OutState[`IDX64(14)] = State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 8'h08;
	end
	
	assign OutState[`IDX64(15)] = State[`IDX64(15)] + RotatedKey[`IDX64(15)] + RNDNUM;

endmodule

`else

module SkeinInjectKeyNexusBlk0(output wire [1023:0] OutState, input wire clk, input wire [1023:0] State, input wire [1087:0] RotatedKey);
	parameter RNDNUM = 0;
	parameter RNDNUM_MOD_3 = 0;
	
	integer x;
	
	reg [1023:0] TmpState;
	assign OutState = TmpState;
	
	// Type[0] = 0xD8, Type[1] = 0xB000000000000000, Type[2] = 0xB0000000000000D8
	always @(posedge clk)
	begin
		for(x = 0; x < 13; x = x + 1)
		begin : KEYADDLOOP
			TmpState[`IDX64(x)] <= State[`IDX64(x)] + RotatedKey[`IDX64(x)];
		end

		if(RNDNUM_MOD_3 == 0)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 8'hD8;
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hB000000000000000;
		end else if(RNDNUM_MOD_3 == 1)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hB000000000000000;
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hB0000000000000D8;
		end else if(RNDNUM_MOD_3 == 2)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hB0000000000000D8;
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 8'hD8;
		end

		TmpState[`IDX64(15)] <= State[`IDX64(15)] + RotatedKey[`IDX64(15)] + RNDNUM;
	end
	
endmodule

module SkeinInjectKeyNexusBlk1(output wire [1023:0] OutState, input wire clk, input wire [1023:0] State, input wire [1087:0] RotatedKey);
	parameter RNDNUM = 0;
	parameter RNDNUM_MOD_3 = 0;
	
	integer x;
	
	reg [1023:0] TmpState;
	assign OutState = TmpState;
	
	// Type[0] = 0x08, Type[1] = 0xFF00000000000000, Type[2] = 0xFF00000000000008
	always @(posedge clk)
	begin
		for(x = 0; x < 13; x = x + 1)
		begin : KEYADDLOOP
			TmpState[`IDX64(x)] <= State[`IDX64(x)] + RotatedKey[`IDX64(x)];
		end

		if(RNDNUM_MOD_3 == 0)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 8'h08;
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hFF00000000000000;
		end else if(RNDNUM_MOD_3 == 1)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hFF00000000000000;
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 64'hFF00000000000008;
		end else if(RNDNUM_MOD_3 == 2)
		begin
			TmpState[`IDX64(13)] <= State[`IDX64(13)] + RotatedKey[`IDX64(13)] + 64'hFF00000000000008;
			TmpState[`IDX64(14)] <= State[`IDX64(14)] + RotatedKey[`IDX64(14)] + 8'h08;
		end

		TmpState[`IDX64(15)] <= State[`IDX64(15)] + RotatedKey[`IDX64(15)] + RNDNUM;
	end
	
endmodule
`endif

/*
#pragma unroll
for(int i = 0; i < 2; ++i)
{
	ulong t[3];
	
	t[0] = (i) ? 0x08UL : 0xD8UL;
	t[1] = (i) ? 0xFF00000000000000UL : 0xB000000000000000UL;
	t[2] = t[0] | t[1];
	
	p = Skein1024Block((i) ? (ulong16)(0) : p, h, h17, t);
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
	h17 = 0x5555555555555555UL ^ h.s0 ^ h.s1 ^ h.s2 ^ h.s3 ^ h.s4 ^ h.s5 ^ h.s6 ^ h.s7 ^ h.s8 ^ h.s9 ^ h.sa ^ h.sb ^ h.sc ^ h.sd ^ h.se ^ h.sf;
}
*/

// Work data requires the state portions not pre-processed (64-bit words 16 - 25, inclusive.) The 64-bit nonce follows.
// It requires the key - 17 64-bit words. The type for each block process is fixed.
// The original data is copied, and a block process is done. The result of the block process is XOR'd with the original data.
// The result of the XOR becomes the new key, with the last key 64-bit word being derived as usual with Skein.

// To use, put state on the InState wires, with InKey set as well.
// Bring nHashRst high, and it will accept input on these wires once per clock
// as long as nHashRst remains held high.

// Latency for this module is 123 cycles (one extra for the final XOR!) and throughput is one hash/clk.
module FirstSkeinRound(output wire [1087:0] OutState, input wire clk, input wire [639:0] InState, input wire [1087:0] InKey, input wire [63:0] InNonce);
	
	parameter COREIDX = 0, HASHERS = 1;
	
	// Every Skein round has four clock cycles of latency, and every
	// Skein key injection has 2 clock cycles of latency. If using the
	// pipe stage for QoR, each Skein round has five clock cycles of latency.
	// If using combinatorial key injections, each key stage has one cycle
	// of latency.
	`ifdef QOR_PIPE_STAGE
	localparam SKEINRNDSTAGES = 5;
	`else
	localparam SKEINRNDSTAGES = 4;
	`endif
	
	`ifdef COMBINATORIAL_KEY_INJ
	localparam SKEINKEYSTAGES = 1;
	`else
	localparam SKEINKEYSTAGES = 2;
	`endif
	
	// 20 rounds, with 21 key injections per block process
	localparam SKEINROUNDS = 20, SKEINKEYINJECTIONS = 21;
	
	// 20 rounds, 4 clock cycles of latency per round, and 21 key
	// injections, 2 clock cycles of latency per key injection
	localparam SKEINBLKSTAGES = (SKEINRNDSTAGES * SKEINROUNDS) + (SKEINKEYINJECTIONS * SKEINKEYSTAGES);
	
	localparam STAGES = SKEINROUNDS + SKEINKEYINJECTIONS;
	
	// Add one extra for the register stage between the XORs!
	localparam BLKSTAGES = (SKEINRNDSTAGES * SKEINROUNDS) + (SKEINKEYINJECTIONS * SKEINKEYSTAGES);
	
	// Type[0] = 0xD8, Type[1] = 0xB000000000000000, Type[2] = 0xB0000000000000D8
	reg [63:0] CurNonce;
	reg [1023:0] IBuf[STAGES-1:0];
	reg [1023:0] OutXORBuf;
	reg [1087:0] KeyBuf;
	
	wire [1023:0] OBuf[STAGES-1:0];
	assign OutState[1023:0] = OutXORBuf;
	assign OutState[1087:1024] = OutXORBuf[`IDX64(0)] ^ OutXORBuf[`IDX64(1)] ^ OutXORBuf[`IDX64(2)] ^ OutXORBuf[`IDX64(3)] ^ OutXORBuf[`IDX64(4)] ^ OutXORBuf[`IDX64(5)] ^ OutXORBuf[`IDX64(6)] ^ OutXORBuf[`IDX64(7)] ^ OutXORBuf[`IDX64(8)] ^ OutXORBuf[`IDX64(9)] ^ OutXORBuf[`IDX64(10)] ^ OutXORBuf[`IDX64(11)] ^ OutXORBuf[`IDX64(12)] ^ OutXORBuf[`IDX64(13)] ^ OutXORBuf[`IDX64(14)] ^ OutXORBuf[`IDX64(15)] ^ `SKEIN_KS_PARITY;
	genvar x;
	integer i;

	always @(posedge clk)
	begin
		IBuf[0] <= { 320'b0, CurNonce, InState };
		KeyBuf <= InKey;
		CurNonce <= InNonce;
		
		for(i = 1; i < STAGES; i = i + 1)
		begin : PIPECYCLELOOP
			IBuf[i] <= OBuf[i - 1];
		end		
		
		OutXORBuf <= OBuf[STAGES-1] ^ { 320'b0, CurNonce - ((BLKSTAGES * HASHERS) + COREIDX), InState };
	end

	// Due to ROTR1088 not being truly circular, values greater than 16
	// will break it - as well as a value of zero. Therefore, the first
	// round and the final four rounds (as well as the final key
	// injection) are removed from the loop and placed outside it.
	
	SkeinInjectKeyNexusBlk0 #(.RNDNUM(0), .RNDNUM_MOD_3(0)) FirstKeyInjection(OBuf[0], clk, IBuf[0], KeyBuf);
	SkeinEvenRound FirstRound(OBuf[1], clk, IBuf[1]);
	
	// Loop for all rounds from 1 - 17, skipping 0, 18, and 19.
	for(x = 1; x < 17; x = x + 1)
	begin : MAINRNDINSTANTIATIONLOOP0
		// A shift up by six is done to multiply the rotation constant by 64 before use.
		// Note that the mod is done on a synthesis time constant which will be optimized out.
		SkeinInjectKeyNexusBlk0 #(.RNDNUM(x), .RNDNUM_MOD_3(x % 3)) KeyInjection(OBuf[x << 1], clk, IBuf[x << 1], `ROTR1088(KeyBuf, x << 6));
			
		if(x & 1)
		begin
			SkeinOddRound OddRound(OBuf[(x << 1) + 1], clk, IBuf[(x << 1) + 1]);
		end else
		begin
			SkeinEvenRound EvenRound(OBuf[(x << 1) + 1], clk, IBuf[(x << 1) + 1]);
		end	
	end
	
	// Key rotation for this round is a no-op.
	SkeinInjectKeyNexusBlk0 #(.RNDNUM(17), .RNDNUM_MOD_3(2)) KeyInjection17(OBuf[34], clk, IBuf[34], KeyBuf);
	SkeinOddRound OddRound17(OBuf[35], clk, IBuf[35]);
	
	SkeinInjectKeyNexusBlk0 #(.RNDNUM(18), .RNDNUM_MOD_3(0)) KeyInjection18(OBuf[36], clk, IBuf[36], `ROTR1088(KeyBuf, 64));
	SkeinEvenRound EvenRound18(OBuf[37], clk, IBuf[37]);

	SkeinInjectKeyNexusBlk0 #(.RNDNUM(19), .RNDNUM_MOD_3(1)) KeyInjection19(OBuf[38], clk, IBuf[38], `ROTR1088(KeyBuf, 128));
	SkeinOddRound OddRound19(OBuf[39], clk, IBuf[39]);
	
	SkeinInjectKeyNexusBlk0 #(.RNDNUM(20), .RNDNUM_MOD_3(2)) KeyInjection20(OBuf[40], clk, IBuf[40], `ROTR1088(KeyBuf, 192));

endmodule

// Latency is 122 clock cycles. Throughput is one hash/clk.
module SecondSkeinRound(output wire [1023:0] OutState, input wire clk, input wire [1087:0] InKey);

	// Every Skein round has four clock cycles of latency, and every
	// Skein key injection has 2 clock cycles of latency. If using the
	// pipe stage for QoR, each Skein round has five clock cycles of latency.
	// If using combinatorial key injections, each key stage has one cycle
	// of latency.
	`ifdef QOR_PIPE_STAGE
	localparam SKEINRNDSTAGES = 5;
	`else
	localparam SKEINRNDSTAGES = 4;
	`endif
	
	`ifdef COMBINATORIAL_KEY_INJ
	localparam SKEINKEYSTAGES = 1;
	`else
	localparam SKEINKEYSTAGES = 2;
	`endif
	
	// 20 rounds, with 21 key injections per block process
	localparam SKEINROUNDS = 20, SKEINKEYINJECTIONS = 21;
	
	// 20 rounds, 4 clock cycles of latency per round, and 21 key
	// injections, 2 clock cycles of latency per key injection
	localparam SKEINBLKSTAGES = (SKEINRNDSTAGES * SKEINROUNDS) + (SKEINKEYINJECTIONS * SKEINKEYSTAGES);
	
	localparam STAGES = SKEINROUNDS + SKEINKEYINJECTIONS;
	
	localparam BLKSTAGES = (SKEINRNDSTAGES * SKEINROUNDS) + (SKEINKEYINJECTIONS * SKEINKEYSTAGES);
	localparam TOTALSTAGES = BLKSTAGES;
		
	// Type[0] = 0x08, Type[1] = 0xFF00000000000000, Type[2] = 0xFF00000000000008
	reg [1023:0] IBuf[STAGES-1:0];
	reg [1087:0] KeyBuf[BLKSTAGES-1:0];
		
	wire [1023:0] OBuf[STAGES-1:0];
	assign OutState[1023:0] = OBuf[STAGES-1];
		
	integer i;

	always @(posedge clk)
	begin
		IBuf[0] <= 1024'b0;
		KeyBuf[0] <= InKey;
		
		for(i = 1; i < STAGES; i = i + 1)
		begin : PIPECYCLELOOP
			IBuf[i] <= OBuf[i - 1];
			KeyBuf[i] <= KeyBuf[i - 1];
		end

		for(i = STAGES; i < BLKSTAGES; i = i + 1)
		begin : KEYCYCLELOOP
			KeyBuf[i] <= KeyBuf[i - 1];
		end		
	end
	
	SkeinInjectKeyNexusBlk1 #(.RNDNUM(0), .RNDNUM_MOD_3(0)) KeyInjection0(OBuf[0], clk, IBuf[0], KeyBuf[0]);
	SkeinEvenRound EvenRound0(OBuf[1], clk, IBuf[1]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(1), .RNDNUM_MOD_3(1)) KeyInjection1(OBuf[2], clk, IBuf[2], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 1], 64));
	SkeinOddRound OddRound1(OBuf[3], clk, IBuf[3]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(2), .RNDNUM_MOD_3(2)) KeyInjection2(OBuf[4], clk, IBuf[4], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 2], 128));
	SkeinEvenRound EvenRound2(OBuf[5], clk, IBuf[5]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(3), .RNDNUM_MOD_3(0)) KeyInjection3(OBuf[6], clk, IBuf[6], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 3], 192));
	SkeinOddRound OddRound3(OBuf[7], clk, IBuf[7]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(4), .RNDNUM_MOD_3(1)) KeyInjection4(OBuf[8], clk, IBuf[8], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 4], 256));
	SkeinEvenRound EvenRound4(OBuf[9], clk, IBuf[9]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(5), .RNDNUM_MOD_3(2)) KeyInjection5(OBuf[10], clk, IBuf[10], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 5], 320));
	SkeinOddRound OddRound5(OBuf[11], clk, IBuf[11]);
	
	SkeinInjectKeyNexusBlk1 #(.RNDNUM(6), .RNDNUM_MOD_3(0)) KeyInjection6(OBuf[12], clk, IBuf[12], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 6], 384));
	SkeinEvenRound EvenRound6(OBuf[13], clk, IBuf[13]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(7), .RNDNUM_MOD_3(1)) KeyInjection7(OBuf[14], clk, IBuf[14], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 7], 448));
	SkeinOddRound OddRound7(OBuf[15], clk, IBuf[15]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(8), .RNDNUM_MOD_3(2)) KeyInjection8(OBuf[16], clk, IBuf[16], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 8], 512));
	SkeinEvenRound EvenRound8(OBuf[17], clk, IBuf[17]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(9), .RNDNUM_MOD_3(0)) KeyInjection9(OBuf[18], clk, IBuf[18], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 9], 576));
	SkeinOddRound OddRound9(OBuf[19], clk, IBuf[19]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(10), .RNDNUM_MOD_3(1)) KeyInjection10(OBuf[20], clk, IBuf[20], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 10], 640));
	SkeinEvenRound EvenRound10(OBuf[21], clk, IBuf[21]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(11), .RNDNUM_MOD_3(2)) KeyInjection11(OBuf[22], clk, IBuf[22], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 11], 704));
	SkeinOddRound OddRound11(OBuf[23], clk, IBuf[23]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(12), .RNDNUM_MOD_3(0)) KeyInjection12(OBuf[24], clk, IBuf[24], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 12], 768));
	SkeinEvenRound EvenRound12(OBuf[25], clk, IBuf[25]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(13), .RNDNUM_MOD_3(1)) KeyInjection13(OBuf[26], clk, IBuf[26], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 13], 832));
	SkeinOddRound OddRound13(OBuf[27], clk, IBuf[27]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(14), .RNDNUM_MOD_3(2)) KeyInjection14(OBuf[28], clk, IBuf[28], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 14], 896));
	SkeinEvenRound EvenRound14(OBuf[29], clk, IBuf[29]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(15), .RNDNUM_MOD_3(0)) KeyInjection15(OBuf[30], clk, IBuf[30], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 15], 960));
	SkeinOddRound OddRound15(OBuf[31], clk, IBuf[31]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(16), .RNDNUM_MOD_3(1)) KeyInjection16(OBuf[32], clk, IBuf[32], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 16], 1024));
	SkeinEvenRound EvenRound16(OBuf[33], clk, IBuf[33]);
	
	// Key rotation for this round is a no-op.
	SkeinInjectKeyNexusBlk1 #(.RNDNUM(17), .RNDNUM_MOD_3(2)) KeyInjection17(OBuf[34], clk, IBuf[34], KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 17]);
	SkeinOddRound OddRound17(OBuf[35], clk, IBuf[35]);
	
	SkeinInjectKeyNexusBlk1 #(.RNDNUM(18), .RNDNUM_MOD_3(0)) KeyInjection18(OBuf[36], clk, IBuf[36], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 18], 64));
	SkeinEvenRound EvenRound18(OBuf[37], clk, IBuf[37]);

	SkeinInjectKeyNexusBlk1 #(.RNDNUM(19), .RNDNUM_MOD_3(1)) KeyInjection19(OBuf[38], clk, IBuf[38], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 19], 128));
	SkeinOddRound OddRound19(OBuf[39], clk, IBuf[39]);
	
	SkeinInjectKeyNexusBlk1 #(.RNDNUM(20), .RNDNUM_MOD_3(2)) KeyInjection20(OBuf[40], clk, IBuf[40], `ROTR1088(KeyBuf[(SKEINRNDSTAGES + SKEINKEYSTAGES) * 20], 192));
endmodule
