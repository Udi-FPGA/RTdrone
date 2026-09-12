`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/09/2026 07:02:56 PM
// Design Name: 
// Module Name: ARTYmic_Top
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


module ARTYmic_Top(
input CLK100MHZ,
input [3:0] btn,

inout [7:0] ja
    );
wire rstn = !btn[0];
wire clk;
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
  clk_wiz_0 clk_wiz_0_inst
   (
    // Clock out ports
    .clk_out1(clk),     // output clk_out1
   // Clock in ports
    .clk_in1(CLK100MHZ)      // input clk_in1
);

reg [3:0] ClkCount;
always @(posedge clk) ClkCount <= ClkCount + 1;

assign ja[4] =  ClkCount[3];

wire  ce = (ClkCount == 3'b111) ? 1'b1 : 1'b0;       // 3.072MHz Enable מה-TOP  //input  wire                  ce,        // 3.072MHz Enable מה-TOP   
//wire        in_valid,                             //input  wire                  in_valid,                              
wire        signal = ja[0];    // כבר מסונכרן מה-TOP      //input  wire                  signal,    // כבר מסונכרן מה-TOP       
wire [15:0] PCM_Out;                              //output reg  [OUT_BITS-1:0]   PCM_Out,                               
wire        pcm_valid  ;                          //output reg                   pcm_valid                              
                                                                       //output reg                   pcm_valid                              
CIC_filter #(
    .N        (3 ),              
    .R        (64),             
    .OUT_BITS (16)       
) CIC_filter_inst (
    .clk      (clk),       
    .rst      (!rstn),       // Active-High
    .ce       (ce),        // 3.072MHz Enable מה-TOP
    .in_valid (1'b1),  
    .signal   (signal),    // כבר מסונכרן מה-TOP
    .PCM_Out  (PCM_Out),   
    .pcm_valid(pcm_valid)  
);
reg [15:0] FFTcount;
always @(posedge clk or negedge rstn)
   if (!rstn) FFTcount <= 16'h0000;
    else if (pcm_valid) FFTcount <= FFTcount + 1;
    
wire [31 : 0] s_axis_data_tdata  = {16'h0000,PCM_Out}; //input wire [31 : 0] s_axis_data_tdata    
wire s_axis_data_tvalid  = (FFTcount[14] && (FFTcount[2:0]==3'b111) && pcm_valid) ? 1'b1 : 1'b0;        //input wire s_axis_data_tvalid            
 wire s_axis_data_tready;         //output wire s_axis_data_tready           
wire s_axis_data_tlast  = (FFTcount[13:3] == 11'h7FF) ? 1'b1 : 1'b0;           //input wire s_axis_data_tlast             
 wire [31 : 0] m_axis_data_tdata ; //output wire [31 : 0] m_axis_data_tdata   
 wire m_axis_data_tvalid         ; //output wire m_axis_data_tvalid           
wire m_axis_data_tready    = 1'b1      ; //input wire m_axis_data_tready            
 wire m_axis_data_tlast          ; //output wire m_axis_data_tlast            

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
xfft_0 xfft_0 (
  .aclk(clk),                                                // input wire aclk
  .s_axis_config_tdata(24'h000000),//s_axis_config_tdata),                  // input wire [23 : 0] s_axis_config_tdata
  .s_axis_config_tvalid(1'b0),//s_axis_config_tvalid),                // input wire s_axis_config_tvalid
  .s_axis_config_tready(),//s_axis_config_tready),                // output wire s_axis_config_tready
  .s_axis_data_tdata(s_axis_data_tdata),                      // input wire [31 : 0] s_axis_data_tdata
  .s_axis_data_tvalid(s_axis_data_tvalid),                    // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),                    // output wire s_axis_data_tready
  .s_axis_data_tlast(s_axis_data_tlast),                      // input wire s_axis_data_tlast
  .m_axis_data_tdata(m_axis_data_tdata),                      // output wire [31 : 0] m_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),                    // output wire m_axis_data_tvalid
  .m_axis_data_tready(m_axis_data_tready),                    // input wire m_axis_data_tready
  .m_axis_data_tlast(m_axis_data_tlast),                      // output wire m_axis_data_tlast
  .event_frame_started(),                  // output wire event_frame_started
  .event_tlast_unexpected(),            // output wire event_tlast_unexpected
  .event_tlast_missing(),                  // output wire event_tlast_missing
  .event_status_channel_halt(),      // output wire event_status_channel_halt
  .event_data_in_channel_halt(),    // output wire event_data_in_channel_halt
  .event_data_out_channel_halt()  // output wire event_data_out_channel_halt
);
wire [15:0] FFTR =  (m_axis_data_tdata[15]) ? 17'h10000-m_axis_data_tdata[15:0]  : m_axis_data_tdata[15:0] ; 
wire [15:0] FFTI =  (m_axis_data_tdata[31]) ? 17'h10000-m_axis_data_tdata[31:16] : m_axis_data_tdata[31:16]; 
wire [16:0] FFT = FFTR + FFTI;
reg [11:0] SampCount;
always @(posedge clk or negedge rstn)
    if (!rstn) SampCount <= 12'h000;
     else if (!m_axis_data_tvalid) SampCount <= 12'h000;
     else SampCount <= SampCount + 1;
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG

ila_0 ila_0_inst (
	.clk(clk), // input wire clk

	.probe0(ClkCount), // input wire [2:0]  probe0  
	.probe1(ce), // input wire [0:0]  probe1 
	.probe2(signal), // input wire [0:0]  probe2
	.probe3(PCM_Out), // input wire [15:0]  probe3 
	.probe4(pcm_valid), // input wire [0:0]  probe4
	.probe5(FFTcount), // input wire [11:0]  probe5 
	.probe6(s_axis_data_tvalid), // input wire [0:0]  probe6 
	.probe7(s_axis_data_tlast), // input wire [0:0]  probe7 
	.probe8(FFTR), // input wire [15:0]  probe8 
	.probe9(FFTI), // input wire [15:0]  probe9 
	.probe10(m_axis_data_tvalid), // input wire [0:0]  probe10 
	.probe11(m_axis_data_tlast), // input wire [0:0]  probe11 
	.probe12(s_axis_data_tready), // input wire [0:0]  probe12
	.probe13(FFT), // input wire [16:0]  probe13 
	.probe14(SampCount) // input wire [11:0]  probe14
);

ila_0 ila_0_inst1 (
	.clk(clk), // input wire clk

	.probe0(ClkCount), // input wire [2:0]  probe0  
	.probe1(ce), // input wire [0:0]  probe1 
	.probe2(signal), // input wire [0:0]  probe2
	.probe3(PCM_Out), // input wire [15:0]  probe3 
	.probe4(pcm_valid), // input wire [0:0]  probe4
	.probe5(FFTcount), // input wire [11:0]  probe5 
	.probe6(s_axis_data_tvalid), // input wire [0:0]  probe6 
	.probe7(s_axis_data_tlast), // input wire [0:0]  probe7 
	.probe8(FFTR), // input wire [15:0]  probe8 
	.probe9(FFTI), // input wire [15:0]  probe9 
	.probe10(m_axis_data_tvalid), // input wire [0:0]  probe10 
	.probe11(m_axis_data_tlast), // input wire [0:0]  probe11 
	.probe12(s_axis_data_tready), // input wire [0:0]  probe12
	.probe13(FFT), // input wire [16:0]  probe13 
	.probe14(SampCount) // input wire [11:0]  probe14
);
   
endmodule
