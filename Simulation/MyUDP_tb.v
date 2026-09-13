`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2026 11:54:34 AM
// Design Name: 
// Module Name: MyUDP_tb
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


module MyUDP_tb();
reg clk ;
reg rstn;
reg [3:0] btn;
initial begin 
clk  = 1'b0;
rstn = 1'b0;
btn = 4'h0;
force MyUDP_Top_inst.ClkCount = 0;
#100;
release MyUDP_Top_inst.ClkCount;
rstn = 1'b1;
#7000;
force MyUDP_Top_inst.btn_int = 4'h1;
#100;
release MyUDP_Top_inst.btn_int;
end
always #5 clk = ~clk;

wire MICclk;
reg MICdata = 0;
always @(posedge MICclk) MICdata <= ~MICdata;
reg [15:0] MICmem [255:0];
wire LoadPCM;
reg [15:0] CountPCM;
reg [15:0] DataPCM;
initial begin 
   $readmemh("DroneWave.hex", MICmem, 0, 255);
CountPCM = 16'h0000;
force LoadPCM = MyUDP_Top_inst.core_inst.s_axis_tvalid;
force MyUDP_Top_inst.core_inst.PCM_Out = DataPCM;
end 
always @(negedge LoadPCM) begin 
         CountPCM <= CountPCM + 1;
         DataPCM <= MICmem[CountPCM];
      end 
       
wire phy_ref_clk   ;
wire phy_rx_clk  = phy_ref_clk;
wire phy_tx_clk  = phy_ref_clk;

MyUDP_Top MyUDP_Top_inst(
    .clk    (clk ),
    .reset_n(rstn),
    .gpio_ja1(MICdata) ,  //;# PMOD JA pin 1 LOC G13  MIC data
    .gpio_ja4(MICclk),   //;# PMOD JA pin 4 LOC D12 MIC clk
    .phy_ref_clk(phy_ref_clk),
    .phy_rx_clk (phy_rx_clk ),
    .phy_tx_clk (phy_tx_clk )
);
endmodule
