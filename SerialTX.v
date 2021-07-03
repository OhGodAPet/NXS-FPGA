`timescale 1ns / 1ps
`default_nettype none

module USBSerial_TX(input wire clk, input wire NewValidInput, input wire [63:0] OutData, output wire UART_RXD_OUT);

localparam STATE_SIZE = 1;
localparam IDLE = 0, OUTPUT_DATA = 1;

// This is the length of the data we want to output in bytes.
localparam MSG_LEN = 8;

// This calculates how many bits we will need to store those bytes (during synthesis, of course!)
localparam ADDR_SIZE = $clog2((MSG_LEN << 3) + 1);

wire TXBusy;
reg State = IDLE, PulseNewData = 1'b0;
reg [7:0] OutByte;
reg [ADDR_SIZE - 1:0] Address;
reg [(MSG_LEN << 3) - 1:0] Msg;

always @(posedge clk)
begin
	case(State)
		IDLE:
			begin
				Address <= 8'b0;
				PulseNewData <= 1'b0;
				if(NewValidInput)
				begin
					Msg <= OutData;
					State <= OUTPUT_DATA;
				end
			end
		OUTPUT_DATA:
		begin
			if(~TXBusy)
			begin
				PulseNewData <= 1'b1;
				OutByte <= Msg[(Address << 3) +: 8];
				if(Address == MSG_LEN) State <= IDLE;
				else Address <= Address + 1'b1;
			end
		end
	endcase
end

async_transmitter TX(clk, PulseNewData, OutByte, UART_RXD_OUT, TXBusy);

endmodule
