`timescale 1ns / 1ps
`default_nettype none

// Helper macro to use Verilog part-select to extract 8 bits (one byte.)
// A shift up by three is the same as a multiply by eight.
`define IDX8(x)            ((x) << 3)+:8

// Module for the FPGA to read 216 bytes of input using the RS-232 Verilog.
// When ByteReady goes high, it reads a byte from RXByte into the data buffer.
module USBSerial_RX(input wire clk, input wire UART_TXD_IN, output reg [1727:0] OutData, output reg ReadCompletedSig);

// This is the length of the data we want to read in bytes.
localparam MSG_LEN = 216;

// This calculates how many bits we will need to store those bytes (during synthesis, of course!)
localparam ADDR_SIZE = $clog2((MSG_LEN << 3) + 1);

wire ByteReady;
wire [7:0] RXByte;
reg [ADDR_SIZE - 1:0] addr = 0;

always @(posedge clk)
begin
	ReadCompletedSig <= 1'b0;
	
	if(ByteReady)
	begin
		//OutData[`IDX8(addr)] <= RXByte;
		OutData <= { RXByte, OutData[1727:8] };
		
		if(addr == MSG_LEN-1)
		begin
			ReadCompletedSig <= 1'b1;
			addr <= 0;
		end else
		begin
			addr <= addr + 1'b1;
		end
	end
end

async_receiver RX(.clk(clk), .RxD(UART_TXD_IN), .RxD_data_ready(ByteReady), .RxD_data(RXByte));

endmodule
