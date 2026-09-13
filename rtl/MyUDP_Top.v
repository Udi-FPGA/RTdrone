`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2026 02:04:24 PM
// Design Name: 
// Module Name: MyUDP_Top
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


module MyUDP_Top(
    /*
     * Clock: 100MHz
     * Reset: Push button, active low
     */
    input  wire       clk,
    input  wire       reset_n,

    /*
     * GPIO
     */
    input  wire [3:0] sw,
    input  wire [3:0] btn,
    output wire       led0_r,
    output wire       led0_g,
    output wire       led0_b,
    output wire       led1_r,
    output wire       led1_g,
    output wire       led1_b,
    output wire       led2_r,
    output wire       led2_g,
    output wire       led2_b,
    output wire       led3_r,
    output wire       led3_g,
    output wire       led3_b,
    output wire       led4,
    output wire       led5,
    output wire       led6,
    output wire       led7,

    input gpio_ja1 ,  //;# PMOD JA pin 1 LOC G13  MIC data
//    input gpio_ja2 ,  //;# PMOD JA pin 2 LOC B11
//    input gpio_ja3 ,  //;# PMOD JA pin 3 LOC A11
//    output gpio_ja4 ,  //;# PMOD JA pin 4 LOC D12 MIC clk
    output gpio_ja7 ,  //;# PMOD JA pin 7 LOC D13
//    input gpio_ja8 ,  //;# PMOD JA pin 8 LOC B18
//    input gpio_ja9 ,  //;# PMOD JA pin 9 LOC A18
//    input gpio_ja10,  //;# PMOD JA pin 10LOC K16

    /*
     * Ethernet: 100BASE-T MII
     */
    output wire       phy_ref_clk,
    input  wire       phy_rx_clk,
    input  wire [3:0] phy_rxd,
    input  wire       phy_rx_dv,
    input  wire       phy_rx_er,
    input  wire       phy_tx_clk,
    output wire [3:0] phy_txd,
    output wire       phy_tx_en,
    input  wire       phy_col,
    input  wire       phy_crs,
    output wire       phy_reset_n
    );
// Clock and reset

wire clk_ibufg;

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire rst_int;

wire mmcm_rst = ~reset_n;
wire mmcm_locked;
wire mmcm_clkfb;

IBUFG
clk_ibufg_inst(
    .I(clk),
    .O(clk_ibufg)
);

wire clk_25mhz_mmcm_out;
wire clk_25mhz_int;
wire clk_50mhz_mmcm_out;
wire clk_50mhz_int;

// MMCM instance
// 100 MHz in, 125 MHz out
// PFD range: 10 MHz to 550 MHz
// VCO range: 600 MHz to 1200 MHz
// M = 10, D = 1 sets Fvco = 1000 MHz (in range)
// Divide by 8 to get output frequency of 125 MHz
// Divide by 40 to get output frequency of 25 MHz
// Divide by 20 to get output frequency of 50 MHz
// 1000 / 5 = 200 MHz
MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT1_DIVIDE(40),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    .CLKOUT2_DIVIDE(20),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKFBOUT_MULT_F(10),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(10.0),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(clk_ibufg),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(clk_25mhz_mmcm_out),
    .CLKOUT1B(),
    .CLKOUT2(clk_50mhz_mmcm_out),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked)
);

BUFG
clk_bufg_inst (
    .I(clk_mmcm_out),
    .O(clk_int)
);

BUFG
clk_25mhz_bufg_inst (
    .I(clk_25mhz_mmcm_out),
    .O(clk_25mhz_int)
);

BUFG
clk_50mhz_bufg_inst (
    .I(clk_50mhz_mmcm_out),
    .O(clk_50mhz_int)
);
sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~mmcm_locked),
    .out(rst_int)
);
// GPIO
wire [3:0] btn_int;
wire [3:0] sw_int;

debounce_switch #(
    .WIDTH(8),
    .N(4),
    .RATE(125000)
)
debounce_switch_inst (
    .clk(clk_int),
    .rst(rst_int),
    .in({btn,
        sw}),
    .out({btn_int,
        sw_int})
);
reg [3:0] ClkCount;
always @(posedge clk_50mhz_int) ClkCount <= ClkCount + 1;
assign gpio_ja7 =  ClkCount[3];

wire  ce = (ClkCount == 3'b111) ? 1'b1 : 1'b0;       // 3.072MHz Enable מה-TOP  //input  wire                  ce,        // 3.072MHz Enable מה-TOP   
wire        signal = gpio_ja1;    // כבר מסונכרן מה-TOP      //input  wire                  signal,    // כבר מסונכרן מה-TOP       
wire [15:0] PCM_Out;                              //output reg  [OUT_BITS-1:0]   PCM_Out,                               
wire        pcm_valid  ;                          //output reg                   pcm_valid                              

CIC_filter #(
    .N        (3 ),              
    .R        (64),             
    .OUT_BITS (16)       
) CIC_filter_inst (
    .clk      (clk_50mhz_int),       
    .rst      (rst_int),       // Active-High
    .ce       (ce),            // 3.072MHz Enable מה-TOP
    .in_valid (1'b1),  
    .signal   (signal),        // כבר מסונכרן מה-TOP
    .PCM_Out  (PCM_Out),   
    .pcm_valid(pcm_valid)  
);

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
ila_2 ila_2_inst (
	.clk(clk_50mhz_int), // input wire clk

	.probe0(ClkCount), // input wire [3:0]  probe0  
	.probe1(ce), // input wire [0:0]  probe1 
	.probe2(signal), // input wire [0:0]  probe2 
	.probe3(PCM_Out), // input wire [15:0]  probe3 
	.probe4(pcm_valid), // input wire [0:0]  probe4
	.probe5(rst_int) // input wire [0:0]  probe5
);

assign phy_ref_clk = clk_25mhz_int;

fpga_core #(
    .TARGET("XILINX")
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .rst(rst_int),
    /*
     * GPIO
     */
    .btn(btn_int),
    .sw(sw_int),
    .led0_r(led0_r),
    .led0_g(led0_g),
    .led0_b(led0_b),
    .led1_r(led1_r),
    .led1_g(led1_g),
    .led1_b(led1_b),
    .led2_r(led2_r),
    .led2_g(led2_g),
    .led2_b(led2_b),
    .led3_r(led3_r),
    .led3_g(led3_g),
    .led3_b(led3_b),
    .led4(led4),
    .led5(led5),
    .led6(led6),
    .led7(led7),
    
    /* MIC input */
    .clk_50mhz_int(clk_50mhz_int)  ,
    .PCM_Out  (PCM_Out),   
    .pcm_valid(pcm_valid),  

    /*
     * Ethernet: 100BASE-T MII
     */
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd),
    .phy_rx_dv(phy_rx_dv),
    .phy_rx_er(phy_rx_er),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_en(phy_tx_en),
    .phy_col(phy_col),
    .phy_crs(phy_crs),
    .phy_reset_n(phy_reset_n)
);    
endmodule
