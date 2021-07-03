`timescale 1ns / 1ps
`default_nettype none

// Helper macro to use Verilog part-select to extract 8 bits (one byte.)
// A shift up by three is the same as a multiply by eight.
`define IDX8(x)            ((x) << 3)+:8

// Ditto for 64 bits.
`define IDX64(x)            ((x) << 6)+:64

// As my top module - all inputs and outputs must be "real" - that is,
// they need to come from somewhere, like the FPGA physical connections.

// Part of the job of the XDC file is to lay out what connections go to
// what names, and what sort of signal needs to be driven or accepted.
 
module BCUNXSMinerTop(
    input wire SYSCLK1_300_N,
    input wire SYSCLK1_300_P,
    
    input wire UART_TXD_IN,
    output wire UART_RXD_OUT
);

wire clk;					// Main clock signal. See below.

wire NonceFound;            // Goes high when a new nonce has been found
wire [63:0] NonceOut;       // Nonce outputted by hash core

// Structure/size of data:
// 10 x 64-bit words for remainder of block header (input to FirstSkeinRound as InState, 640 bits.)
// 17 x 64-bit words for midstate (input to FirstSkeinRound as InKey, 1088 bits.)
// 1088 + 640 = 1728 bits = 216 bytes
// (17 + 10) * 8 * 8 = 1728 bits = 216 bytes
wire [1727:0] InData;		// Signals for our incoming data;
wire ReceivedFullInput;		// Signal to indicate 216 whole bytes have been read.

reg OutputReady = 1'b0;		// Signal to indicate we have our output data ready.
reg DataValid = 1'b0;		// Someplace to store a 1 if we ever get valid input.
reg nHashRst = 1'b0;        // Active-low reset signal to cause work reload.

reg [1727:0] InDataReg;		// Someplace to store the data we get.
reg [63:0] OutDataReg;		// Someplace to hold data for output.

// Convert differential 600Mhz clock into single-ended 600Mhz clock we can use...
//MMCM650 MainMMCM(.clk_out1(clk), .clk_in1_p(SYSCLK0_200_P), .clk_in1_n(SYSCLK0_200_N));
IBUFDS MufIBUF(.O(clk), .I(SYSCLK1_300_P), .IB(SYSCLK1_300_N));

// Here, we instantiate the RX and TX modules used for communications logic.

USBSerial_RX InputReader(.clk(clk), .UART_TXD_IN(UART_TXD_IN), .OutData(InData), .ReadCompletedSig(ReceivedFullInput));
USBSerial_TX OutputTransmitter(.clk(clk), .NewValidInput(OutputReady), .OutData(OutDataReg), .UART_RXD_OUT(UART_RXD_OUT));

//USBSerial SerialTransciever(.clk(clk), .RX(UART_TXD_IN), .TX(UART_RXD_OUT), .BlkHdr(InData), .BlkHdrValid(ReceivedFullInput), .OutData(OutDataReg), .OutDataValid(OutputReady));

always @(posedge clk)
begin
	// This goes high, store the work, and note that we received
	// valid data to work on.
	if(ReceivedFullInput)
	begin
		InDataReg <= InData;
		
		// Unlike most of our signals, this one remains high
        // once we've gotten valid data at least once.
        // Technically, it should be pulled low on work exhaustion,
        // but we're never gonna exhaust 2^64 possibles...
        DataValid <= 1'b1;
	end
    
    // Reset the hash core so it will pick up the new work
    nHashRst <= ~ReceivedFullInput;
    
	OutDataReg <= NonceOut;
	OutputReady <= NonceFound;
end

NexusHashTransform NexusMinerCore(NonceOut, NonceFound, clk, nHashRst, InDataReg, 64'b0);

endmodule