`timescale 1ns / 1ps

`define IDX64(x)            ((x) << 6)+:64

// Testbench for the Skein even round function implementation
module SkeinEvenRound_tb;
	
	localparam STARTING_WORK = 2'b00, MIDDLE_SECTION = 2'b01, WAITING_ON_RESULTS = 2'b10;
	genvar x;
	
	// Reg
	reg clk = 1'b0;
	
	// Inputs
	reg [1023:0] TestInput;
	wire [63:0] InputArrayEven[7:0], InputArrayOdd[7:0];
	    
	always #1 clk = ~clk;

	wire [63:0] OutputArrayEven[7:0], OutputArrayOdd[7:0];
	wire [1023:0] Output;
	
	for(x = 0; x < 8; x = x + 1)
	begin : ARRAYCOPYLOOPEVEN
		assign InputArrayEven[x] = TestInput[`IDX64(x)];
	end
	
	for(x = 0; x < 8; x = x + 1)
	begin : ARRAYCOPYLOOPODD
		assign InputArrayOdd[x] = TestInput[`IDX64(x + 8)];
	end

	assign Output = { OutputArrayOdd[7], OutputArrayOdd[6], OutputArrayOdd[5], OutputArrayOdd[4], OutputArrayOdd[3], OutputArrayOdd[2], OutputArrayOdd[1], OutputArrayOdd[0], OutputArrayEven[7], OutputArrayEven[6], OutputArrayEven[5], OutputArrayEven[4], OutputArrayEven[3], OutputArrayEven[2], OutputArrayEven[1], OutputArrayEven[0] };
		
    initial
	begin
	
		$dumpfile("SimOutput.lxt2");
		$dumpvars(0, SkeinEvenRound_tb);
		
		#2;
		
        // Initialize input
        TestInput <= 1024'hA6D8A0A61291CD34F4546149C74CC22E2649339EB37B6519AED442CA29B94FB21BFFD5B90DE16C135743D3A68ED874A160F27B8D098A828BF98FACDB647C0355371E5F0A3B9E81B7F7F78C1BAD4B1DF441B07D5909BE1F3FA16C4845892B8E46A34B94CDB69DFAF73D6E858FC504E56DFD6B3533D9D8B3B11BCECBB3A446FA31;
        
        #2;
        #2;
        #2;
        #2;

        if(Output == 1024'h8B551591955CCAF9726A5B9BD4877BF83DC131B02502E3AC28CC9F6E7D6D56301AC28D2B08C85569A1011D4AFE2AB520AF37AAF4011C77D498571481110AF4C7C7FF7EA97F03824962798814A7A3B4550D51FDC86A751BA8CDF47B45EE322D47766903F698F21DC480597C0B5291C8CD385EBC70C0A425D2A1A56BCB3CD84AB0)
			$display("PASS.");
		else
			$display("FAIL. 0x%h", Output);

		$finish;
	end
	//SkeinMix8(output wire [63:0] OutEven[7:0], output wire [63:0] OutOdd[7:0], input wire [63:0] InEven[7:0], input wire [63:0] InOdd[7:0]);
	//20, 53, 43, 6, 40, 31, 52, 16
	//SkeinMix8 #(.R0(20), .R1(53), .R2(43), .R3( 6), .R4(40), .R5(31), .R6(52), .R7(16)) MixFunc(Output[511:0], Output[1023:512], TestInput[511:0], TestInput[1023:512]);
	SkeinEvenRound EvenTestRnd(Output, clk, TestInput);
endmodule
