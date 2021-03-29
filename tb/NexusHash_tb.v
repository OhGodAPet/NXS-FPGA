`timescale 1ns / 1ps

`define IDX64(x)            ((x) << 6)+:64

// Testbench for the Skein block process implementation
module NexusHash_tb;
	
	localparam ROUNDS = 20, KEYINJECTIONS = 21;
	localparam ROUNDSTAGES = 4, KEYSTAGES = 1;
	
	localparam STAGESPERBLK = (ROUNDSTAGES * ROUNDS) + (KEYINJECTIONS * KEYSTAGES);
	localparam TOTALSTAGES = STAGESPERBLK * 4;
	
	genvar x;
	
	// Reg
	reg clk = 1'b0, nHashRst = 1'b0;
	
	// Inputs
	reg [TOTALSTAGES-1:0] PipeOutputGood = 0;
	reg [1023:0] TestInput;
	reg [1087:0] TestKey;
	reg [191:0] TestType;
	reg PassedFirstRnd = 1'b0, PassedSkein = 1'b0;
	
	always #1 clk = ~clk;
	wire [1087:0] Output1;
	wire [1023:0] Output2;
	wire [63:0] Output3;
	wire FirstRoundValidSig, SecondRoundValidSig;
	wire CompletedSig;
			
    initial
	begin
	
		$dumpfile("SimOutput.lxt2");
		$dumpvars(0, NexusHash_tb);
		
		#2;
		
        // Initialize input
        //TestInput <= 1024'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060F27B8D098A828BF98FACDB647C0355371E5F0A3B9E81B7F7F78C1BAD4B1DF441B07D5909BE1F3FA16C4845892B8E46A34B94CDB69DFAF73D6E858FC504E56DFD6B3533D9D8B3B11BCECBB3A446FA31;
        //TestInput <= { 320'b0, 704'h0000000015D474847B033AFA0026F93C00000002D2F231964F2495631FD2F3A6DF35D62ED21C5999898598BF6B83ABAF13865C9654A330E0A248F909B757B9C81F059F02043D4B7FD4E50719B9B551714CD3ECA6A3238305 };
        //TestKey <= 1088'h5140285EA2E386F7167680BE7897F81971A3086ACC6CC8F057C1D69EA96127F3ABB56DF877FDECB8B1E9D263648DBE76F3CB2FA1739B5285E2AB244823C589F99B9F238E28F0C967101D5D42065C65273E274D718830E81ED86F7A18605FB3D75E674880CB9E47A4797A1003D479B77B3E245EDF8787BF9EAB986FFFA8FEF30A34646120A8B4C7D4;
        //TestKey <= 1088'h7425A77FFC307BB0CC3C17574EBAA329FF205DD725470071E7D3FC7287EB80CEF8835283808B0EDDD43BF6C61A270A41671D6B92B5E7973D1D05F622A30960297C8D791FB1E811A0B6E8DC225C84171F6CCF6DA6A7FC2F8AF604DFCF2F42053A3313447EDC4F03908F5C0D372831008344844FF57644C3B95BAFA2D6404E66FD50D5CE136E9774A3;
        TestType <= 192'hB0000000000000D8B00000000000000000000000000000D8;
		
		//TestInput <= 1024'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060F27B8D098A828BF98FACDB647C0355371E5F0A3B9E81B7F7F78C1BAD4B1DF441B07D5909BE1F3FA16C4845892B8E46A34B94CDB69DFAF73D6E858FC504E56DFD6B3533D9D8B3B11BCECBB3A446FA31;
		//TestKey <= 1088'h5140285EA2E386F7167680BE7897F81971A3086ACC6CC8F057C1D69EA96127F3ABB56DF877FDECB8B1E9D263648DBE76F3CB2FA1739B5285E2AB244823C589F99B9F238E28F0C967101D5D42065C65273E274D718830E81ED86F7A18605FB3D75E674880CB9E47A4797A1003D479B77B3E245EDF8787BF9EAB986FFFA8FEF30A34646120A8B4C7D4;
		TestInput <= { 320'b0, 704'h00000000000000007B01B1D000396D8D00000002BD97BE01DB09CB623352A9160F3F29B6F456862DC63E601430361FFA159BF93BBD8FDE57E4A0A20A3C343BA85BBED36C3157023906DF1973D1E4438EDBCD6FE21B65A290 };
		TestKey <= 1088'h38DD0C4440A756EAE0CBA5A50F952345FA9083AE768CB93D34EC5D92B788F0EA4D089565088FC9758F983C26648260CAB387D86481EB16086DD4E16D6D634C91D2FA7B77076D072D14DF39BD780F792616575E267E2C3E4B77FD99680CC716F3B724DA94566FE7E18059EBCC26E758DE2BEE15A3492386D7A0B0F2BC839976DA4450E101EC5D838A;
		
		
        #2

        // Release reset
		nHashRst <= 1'b1;
		
        //while(~CompletedSig) #2;
    end
    
    always @(posedge clk)
	begin
		PipeOutputGood <= (PipeOutputGood << 1) | nHashRst;
		
		/*
		if(~PassedSkein & SecondRoundValidSig)
		begin
			if(Output2 == 1024'h91518673AC59A009A2C5D6DFD258A5A264610638620B0405B1D9C0D98C5BB85E72EBC297DB4E2774B745D65721675B20DE93A805A2BBF0BFD1FEAD53E96EE6306D109F9524AB0B07B88C43AC856153E11C8321DEE4F422309FEFC8EC7CB35F000829EBF579AA5B6E0C358A6F496456BFCDF3C33102A2808A673A3BFE1DEA095B)
			begin
				$display("SKEIN PASS.");
				PassedSkein <= 1'b1;
			end
			else begin
				$display("SKEIN FAIL. 0x%h", Output2);
				//$finish;
			end
		end
		*/
		if(CompletedSig)
		begin
			if(Output3 == 64'h000000000E8A504F)
			begin
				$display("NEXUS PASS.\n");
				$finish;
			end else begin
				$display("NEXUS FAIL. 0x%h\n", Output3);
			end
		end
	end
	
	FirstSkeinRound Block1ProcessTest(Output1, FirstRoundValidSig, clk, nHashRst, TestInput[639:0], TestKey, 64'h00000001FCAFC044);
	SecondSkeinRound Block2ProcessTest(Output2, SecondRoundValidSig, clk, FirstRoundValidSig, Output1);
	NexusKeccak1024 KeccakProcessTest(Output3, CompletedSig, clk, SecondRoundValidSig, Output2);
endmodule
