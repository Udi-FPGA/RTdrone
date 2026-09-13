`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/08/2026 07:06:43 PM
// Design Name: 
// Module Name: udp_data_gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module udp_data_gen #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = (DATA_WIDTH/8)
)(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * Control Interface
     */
    input  wire                   trigger,
    input  wire [15:0]            packet_len, // Length of payload

    /*
     * AXI-Stream Master Interface (To UDP Stack)
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast
);

localparam STATE_IDLE = 0;
localparam STATE_SEND = 1;

reg [0:0]  state_reg = STATE_IDLE;
reg [15:0] count_reg = 0;
reg [DATA_WIDTH-1:0] data_reg = 0;
//parameter INIT_FILE = "D:/Designs/UDP/MyUDP1209/Wave/DroneWave.hex";                       // Specify name/location of RAM initialization file if using one (leave blank if not)
parameter INIT_FILE = "DroneWave.hex";                       // Specify name/location of RAM initialization file if using one (leave blank if not)

assign m_axis_tdata  = data_reg;
assign m_axis_tkeep  = {KEEP_WIDTH{1'b1}};
assign m_axis_tvalid = (state_reg == STATE_SEND);
assign m_axis_tlast  = (state_reg == STATE_SEND) && (count_reg == packet_len - KEEP_WIDTH);
reg [15:0] WaveMem [255:0];
reg [15:0] outWaveMem;
initial begin
   if (INIT_FILE != "") begin
//        $readmemh("D:/Designs/UDP/MyUDP1209/Wave/DroneWave.hex", WaveMem, 0, 255);
        $readmemh("DroneWave.hex", WaveMem, 0, 255);
        $display("Loading memory from: %s", INIT_FILE);
    end   
end
always @(posedge clk) 
     outWaveMem <= WaveMem[count_reg[15:1]];
     
always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        count_reg <= 0;
        data_reg  <= 0;
    end else begin
        case (state_reg)
            STATE_IDLE: begin
                count_reg <= 0;
                data_reg  <= outWaveMem[15:8];
                if (trigger) begin
                    state_reg <= STATE_SEND;
                end
            end

            STATE_SEND: begin
                if (m_axis_tready) begin
                    if (m_axis_tlast) begin
                        state_reg <= STATE_IDLE;
                    end else begin
                        count_reg <= count_reg + KEEP_WIDTH;
//                        data_reg  <= data_reg + 1; // Incrementing pattern
                        if (count_reg[0]==1'b0) data_reg <= outWaveMem[7:0];
                         else data_reg <= outWaveMem[15:8];
                    end
                end
            end
        endcase
    end
end

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG

ila_1 ila_1_inst (
	.clk(clk), // input wire clk

	.probe0(trigger), // input wire [0:0]  probe0  
	.probe1(state_reg), // input wire [0:0]  probe1 
	.probe2(count_reg), // input wire [15:0]  probe2 
	.probe3(m_axis_tdata), // input wire [7:0]  probe3 
	.probe4(m_axis_tvalid), // input wire [0:0]  probe4 
	.probe5(m_axis_tready), // input wire [0:0]  probe5 
	.probe6(m_axis_tlast), // input wire [0:0]  probe6 
	.probe7(outWaveMem) // input wire [15:0]  probe7
);

endmodule