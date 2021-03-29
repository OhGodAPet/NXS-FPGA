`timescale 1ns / 1ps

`define IDX64(x)            ((x) << 6)+:64

// Testbench for the Skein odd round function implementation
module SkeinOddRound_tb;
	
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
		$dumpvars(0, SkeinOddRound_tb);
		
		#2;
		
        // Initialize input
        TestInput <= 1024'hA6D8A0A61291CD34F4546149C74CC22E2649339EB37B6519AED442CA29B94FB21BFFD5B90DE16C135743D3A68ED874A160F27B8D098A828BF98FACDB647C0355371E5F0A3B9E81B7F7F78C1BAD4B1DF441B07D5909BE1F3FA16C4845892B8E46A34B94CDB69DFAF73D6E858FC504E56DFD6B3533D9D8B3B11BCECBB3A446FA31;
        
        #2;
        #2;
        #2;
        #2;

        if(Output == 1024'hF3ED853EB4F30F0CD8615734D30144DEB59910C5FE6B9DD13FB687C0F5DA3A7CD76ECA044B728B3077BED2E978BD37129B57C367CAD7F8FDFBF8A2BA1DBDEB376C007A96778DA85D35C66F6D3574C235E303712E75A293ED5AEA9115DF2ECE7FDE833C8089BC3AEDD9413F3F396B12DE02A5FC4A497D1602D952CFA624B48384)
			$display("PASS.");
		else
			$display("FAIL. 0x%h", Output);

		$finish;
	end
	
	SkeinOddRound OddTestRnd(Output, clk, TestInput);
endmodule
