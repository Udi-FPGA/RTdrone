/*
Copyright (c) 2014-2018 Alex Forencich
... (standard header preserved) ...
*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module fpga_core #
(
    parameter TARGET = "GENERIC"
)
(
    input  wire       clk,
    input  wire       rst,

    /* GPIO */
    input  wire [3:0] btn,
    input  wire [3:0] sw,
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

    /* MIC input */
    input  wire  clk_50mhz_int  ,
    input  wire [15:0] PCM_Out  ,                              
    input  wire        pcm_valid,           
                    
    /* Ethernet: 100BASE-T MII */
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

// --- AXI/Internal Wires (Standard Forencich Wiring) ---
wire [7:0] rx_axis_tdata;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast ;
wire rx_axis_tuser ;

wire [7:0] tx_axis_tdata;
wire tx_axis_tvalid; 
wire tx_axis_tready; 
wire tx_axis_tlast ; 
wire tx_axis_tuser ;

wire rx_eth_hdr_ready; 
wire rx_eth_hdr_valid ;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac ;
wire [15:0] rx_eth_type ;
wire [7:0] rx_eth_payload_axis_tdata ;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast ;
wire rx_eth_payload_axis_tuser ;

wire tx_eth_hdr_ready; 
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [7:0]  tx_eth_payload_axis_tdata;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast ;
wire tx_eth_payload_axis_tuser ;


// IP and UDP wires
wire rx_ip_hdr_valid;
wire rx_ip_hdr_ready;
wire [31:0] rx_ip_source_ip; 
wire [31:0] rx_ip_dest_ip;
wire [7:0] rx_ip_payload_axis_tdata ;
wire rx_ip_payload_axis_tvalid ; // etc
wire rx_udp_hdr_valid;
wire rx_udp_hdr_ready;
wire [31:0] rx_udp_ip_source_ip; 
wire [31:0] rx_udp_ip_dest_ip;
wire [15:0] rx_udp_source_port;
wire [15:0] rx_udp_dest_port;
wire [15:0] rx_udp_length;
wire [7:0] rx_udp_payload_axis_tdata ;
wire rx_udp_payload_axis_tvalid;

wire tx_ip_hdr_valid; 
wire tx_ip_hdr_ready;
wire [7:0] tx_ip_payload_axis_tdata;
wire tx_ip_payload_axis_tready; // etc
wire tx_udp_hdr_valid; 
wire [5:0] tx_udp_ip_dscp;
wire [1:0] tx_udp_ip_ecn;
wire [7:0] tx_udp_ip_ttl;
wire [31:0] tx_udp_ip_source_ip;
wire [31:0] tx_udp_ip_dest_ip;
wire [15:0] tx_udp_source_port;
wire [15:0] tx_udp_dest_port;
wire [15:0] tx_udp_length;
wire [15:0] tx_udp_checksum;
wire tx_udp_hdr_ready;
wire [7:0] tx_udp_payload_axis_tdata;
wire tx_udp_payload_axis_tready; 
wire tx_udp_payload_axis_tvalid; 
wire tx_udp_payload_axis_tlast;
wire tx_udp_payload_axis_tuser;

// --- Configuration ---
wire [47:0] local_mac   = 48'h02_00_00_00_00_00;
wire [31:0] local_ip    = {8'd192, 8'd168, 8'd1,   8'd128};
wire [31:0] gateway_ip  = {8'd192, 8'd168, 8'd1,   8'd1};
wire [31:0] subnet_mask = {8'd255, 8'd255, 8'd255, 8'd0};

// --- DATA GENERATOR LOGIC ---
wire [31:0] gen_dest_ip   = {8'd192, 8'd168, 8'd1, 8'd39}; // Set to your PC IP
wire [15:0] gen_dest_port = 16'd1234;
wire [15:0] gen_src_port  = 16'd5678;
//wire [15:0] gen_payload_len = 16'd50; // Bytes of data
wire [15:0] gen_payload_len = 16'h0200; // Bytes of data
wire [7:0] gen_tdata;
//wire       gen_tvalid;
reg       gen_tvalid;
wire       gen_tready;
wire       gen_tlast;

    /* MIC input */
reg[2:0] Devpcm_valid;
always @(posedge clk_50mhz_int or posedge rst)
    if (rst) Devpcm_valid <= 3'b000;
     else Devpcm_valid <= {Devpcm_valid[1:0],pcm_valid};
wire  s_axis_tvalid      = ((Devpcm_valid==3'b001) || (Devpcm_valid== 3'b010)) ? 1'b1 : 1'b0;
wire  s_axis_tready      ;
wire  [7:0] s_axis_tdata = (Devpcm_valid==3'b001) ? PCM_Out[15:8] :
                           (Devpcm_valid==3'b010) ? PCM_Out[7:0]  : 8'h00;
wire m_axis_tvalid             ;
wire m_axis_tready = gen_tready ;
wire [7:0] m_axis_tdata        ;
wire [31:0] axis_rd_data_count ;

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
ila_3 ila_3_inst (
	.clk(clk_50mhz_int), // input wire clk

	.probe0(pcm_valid), // input wire [0:0]  probe0  
	.probe1(PCM_Out), // input wire [15:0]  probe1 
	.probe2(Devpcm_valid), // input wire [2:0]  probe2 
	.probe3(s_axis_tvalid), // input wire [0:0]  probe3 
	.probe4(s_axis_tready), // input wire [0:0]  probe4 
	.probe5(s_axis_tdata), // input wire [7:0]  probe5 
	.probe6(axis_rd_data_count) // input wire [31:0]  probe6
);
                           
//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
axis_data_fifo_0 axis_data_fifo_0_inst (
  .s_axis_aresetn(!rst),  // input wire s_axis_aresetn
  .s_axis_aclk(clk_50mhz_int),        // input wire s_axis_aclk
  .s_axis_tvalid(s_axis_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready),    // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata),      // input wire [7 : 0] s_axis_tdata
  .m_axis_aclk(clk),        // input wire m_axis_aclk
  .m_axis_tvalid(m_axis_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),    // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),      // output wire [7 : 0] m_axis_tdata
  .axis_rd_data_count(axis_rd_data_count)  // output wire [31 : 0] axis_rd_data_count
);
assign gen_tlast = ((axis_rd_data_count == 32'h00000002)&&gen_tready&&gen_tvalid) ? 1'b1 : 1'b0;
//reg [19:0] Debounce;
//always @(posedge clk or posedge rst)
//    if (rst) Debounce <= 20'hFFFFF;
//     else if (Debounce != 20'hFFFFF) Debounce <= Debounce + 1;
//     else if (btn[0]) Debounce <= 20'h00000;
//wire trigger = (Debounce == 20'h00002) ? 1'b1 : 1'b0;     
wire trigger = (axis_rd_data_count == gen_payload_len) ? 1'b1 : 1'b0;     
always @(posedge clk or posedge rst)
    if (rst) gen_tvalid <= 1'b0;
     else if (trigger)   gen_tvalid <= 1'b1;
     else if (gen_tlast) gen_tvalid <= 1'b0;
assign gen_tdata = m_axis_tdata;     
//udp_data_gen #(
//    .DATA_WIDTH(8)
//) udp_gen_inst (
//    .clk(clk),
//    .rst(rst),
//    .trigger(trigger),//btn[0]), // Press Button 0 to send
//    .packet_len(gen_payload_len),
//    .m_axis_tdata(gen_tdata),
//    .m_axis_tvalid(gen_tvalid),
//    .m_axis_tready(gen_tready),
//    .m_axis_tlast(gen_tlast)
//);

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
ila_0 ila_0_Inst (
	.clk(clk), // input wire clk
	
	.probe0(trigger), // input wire [0:0]  probe0  
	.probe1(gen_tdata), // input wire [7:0]  probe1 
	.probe2(gen_tvalid), // input wire [0:0]  probe2 
	.probe3(gen_tready), // input wire [0:0]  probe3 
	.probe4(gen_tlast), // input wire [0:0]  probe4
	.probe5(axis_rd_data_count) // input wire [31:0]  probe5
);
// Header control: Alex's stack needs a pulse on hdr_valid to start
reg tx_hdr_valid_reg = 0;
always @(posedge clk) begin
    if (rst) begin
        tx_hdr_valid_reg <= 0;
    end else begin
        if (gen_tvalid && !tx_hdr_valid_reg && tx_udp_hdr_ready) begin
            tx_hdr_valid_reg <= 1; // Assert header
        end else if (tx_udp_payload_axis_tlast && tx_udp_payload_axis_tready) begin
            tx_hdr_valid_reg <= 0; // Clear after packet done
        end
    end
end

// Connect generator to UDP Stack inputs
assign tx_udp_hdr_valid = (gen_tvalid && !tx_hdr_valid_reg); 
assign tx_udp_ip_dscp = 0;
assign tx_udp_ip_ecn = 0;
assign tx_udp_ip_ttl = 64;
assign tx_udp_ip_source_ip = local_ip;
assign tx_udp_ip_dest_ip   = gen_dest_ip;
assign tx_udp_source_port  = gen_src_port;
assign tx_udp_dest_port    = gen_dest_port;
assign tx_udp_length       = gen_payload_len + 8; // Data + Header
assign tx_udp_checksum     = 0;

assign tx_udp_payload_axis_tdata  = gen_tdata;
assign tx_udp_payload_axis_tvalid = gen_tvalid;
assign gen_tready                 = tx_udp_payload_axis_tready;
assign tx_udp_payload_axis_tlast  = gen_tlast;
assign tx_udp_payload_axis_tuser  = 0;

// --- Receiver / LEDs (Simple Monitoring) ---
assign rx_udp_hdr_ready = 1;
wire rx_udp_payload_axis_tready = 1;
wire rx_udp_payload_axis_tlast;

reg [7:0] led_reg = 0;
always @(posedge clk) begin
    if (rst) led_reg <= 0;
    else if (rx_udp_payload_axis_tvalid) led_reg <= rx_udp_payload_axis_tdata;
end
assign {led0_g, led1_g, led2_g, led3_g, led4, led5, led6, led7} = led_reg;

// --- Physical and MAC Instances (DO NOT REMOVE) ---
assign phy_reset_n = !rst;

eth_mac_mii_fifo #(
    .TARGET(TARGET),
    .CLOCK_INPUT_STYLE("BUFR"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
) eth_mac_inst (
    .rst(rst), 
	.logic_clk(clk), 
	.logic_rst(rst),
    .tx_axis_tdata(tx_axis_tdata), 
	.tx_axis_tvalid(tx_axis_tvalid), 
	.tx_axis_tready(tx_axis_tready), 
	.tx_axis_tlast(tx_axis_tlast), 
	.tx_axis_tuser(tx_axis_tuser),
    .rx_axis_tdata(rx_axis_tdata), 
	.rx_axis_tvalid(rx_axis_tvalid), 
	.rx_axis_tready(rx_axis_tready), 
	.rx_axis_tlast(rx_axis_tlast), 
	.rx_axis_tuser(rx_axis_tuser),
    .mii_rx_clk(phy_rx_clk), 
	.mii_rxd(phy_rxd), 
	.mii_rx_dv(phy_rx_dv), 
	.mii_rx_er(phy_rx_er),
    .mii_tx_clk(phy_tx_clk), 
	.mii_txd(phy_txd), 
	.mii_tx_en(phy_tx_en), 
	.mii_tx_er(),
    .cfg_ifg(8'd12), 
	.cfg_tx_enable(1'b1), 
	.cfg_rx_enable(1'b1)
);

eth_axis_rx 
eth_axis_rx_inst (
    .clk(clk), 
	.rst(rst),
    .s_axis_tdata(rx_axis_tdata), 
	.s_axis_tvalid(rx_axis_tvalid), 
	.s_axis_tready(rx_axis_tready), 
	.s_axis_tlast(rx_axis_tlast), 
	.s_axis_tuser(rx_axis_tuser),
    .m_eth_hdr_valid(rx_eth_hdr_valid), 
	.m_eth_hdr_ready(rx_eth_hdr_ready), 
	.m_eth_dest_mac(rx_eth_dest_mac), 
	.m_eth_src_mac(rx_eth_src_mac), 
	.m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata), 
	.m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid), 
	.m_eth_payload_axis_tready(rx_eth_payload_axis_tready), 
	.m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast), 
	.m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser)
);

eth_axis_tx 
eth_axis_tx_inst (
    .clk(clk), 
	.rst(rst),
    .s_eth_hdr_valid(tx_eth_hdr_valid), 
	.s_eth_hdr_ready(tx_eth_hdr_ready), 
	.s_eth_dest_mac(tx_eth_dest_mac), 
	.s_eth_src_mac(tx_eth_src_mac), 
	.s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata), 
	.s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid), 
	.s_eth_payload_axis_tready(tx_eth_payload_axis_tready), 
	.s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast), 
	.s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    .m_axis_tdata(tx_axis_tdata), 
	.m_axis_tvalid(tx_axis_tvalid), 
	.m_axis_tready(tx_axis_tready), 
	.m_axis_tlast(tx_axis_tlast), 
	.m_axis_tuser(tx_axis_tuser)
);

udp_complete 
udp_complete_inst (
    .clk(clk), 
	.rst(rst),
    .s_eth_hdr_valid(rx_eth_hdr_valid), 
	.s_eth_hdr_ready(rx_eth_hdr_ready), 
	.s_eth_dest_mac(rx_eth_dest_mac), 
	.s_eth_src_mac(rx_eth_src_mac), 
	.s_eth_type(rx_eth_type),
    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata), 
	.s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid), 
	.s_eth_payload_axis_tready(rx_eth_payload_axis_tready), 
	.s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast), 
	.s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    .m_eth_hdr_valid(tx_eth_hdr_valid), 
	.m_eth_hdr_ready(tx_eth_hdr_ready), 
	.m_eth_dest_mac(tx_eth_dest_mac), 
	.m_eth_src_mac(tx_eth_src_mac), 
	.m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata), 
	.m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid), 
	.m_eth_payload_axis_tready(tx_eth_payload_axis_tready), 
	.m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast), 
	.m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    .s_ip_hdr_valid(0), 
	.s_ip_hdr_ready(), 
	// IP input not used
    .m_ip_hdr_valid(), 
	.m_ip_payload_axis_tready(1'b1),
    .s_udp_hdr_valid(tx_udp_hdr_valid), 
	.s_udp_hdr_ready(tx_udp_hdr_ready), 
	.s_udp_ip_dscp(tx_udp_ip_dscp), 
	.s_udp_ip_ecn(tx_udp_ip_ecn), 
	.s_udp_ip_ttl(tx_udp_ip_ttl), 
	.s_udp_ip_source_ip(tx_udp_ip_source_ip), 
	.s_udp_ip_dest_ip(tx_udp_ip_dest_ip), 
	.s_udp_source_port(tx_udp_source_port), 
	.s_udp_dest_port(tx_udp_dest_port), 
	.s_udp_length(tx_udp_length), 
	.s_udp_checksum(tx_udp_checksum),
    .s_udp_payload_axis_tdata(tx_udp_payload_axis_tdata), 
	.s_udp_payload_axis_tvalid(tx_udp_payload_axis_tvalid), 
	.s_udp_payload_axis_tready(tx_udp_payload_axis_tready), 
	.s_udp_payload_axis_tlast(tx_udp_payload_axis_tlast), 
	.s_udp_payload_axis_tuser(tx_udp_payload_axis_tuser),
    .m_udp_hdr_valid(rx_udp_hdr_valid), 
	.m_udp_hdr_ready(rx_udp_hdr_ready), 
	.m_udp_ip_source_ip(rx_udp_ip_source_ip), 
	.m_udp_dest_port(rx_udp_dest_port), 
	.m_udp_payload_axis_tdata(rx_udp_payload_axis_tdata), 
	.m_udp_payload_axis_tvalid(rx_udp_payload_axis_tvalid), 
	.m_udp_payload_axis_tready(rx_udp_payload_axis_tready), 
	.m_udp_payload_axis_tlast(rx_udp_payload_axis_tlast),
    .local_mac(local_mac), 
	.local_ip(local_ip), 
	.gateway_ip(gateway_ip), 
	.subnet_mask(subnet_mask), 
	.clear_arp_cache(0)
);

endmodule
`resetall