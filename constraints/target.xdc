#set_false_path -from [get_clocks -of_objects [get_pins clk_mmcm_inst/CLKOUT0]] -to [get_clocks clk]
#set_false_path -from [get_clocks clk] -to [get_clocks -of_objects [get_pins clk_mmcm_inst/CLKOUT0]]
#set_false_path -from [get_clocks -of_objects [get_pins clk_mmcm_inst/CLKOUT1]] -to [get_clocks clk]
#set_false_path -from [get_clocks clk] -to [get_clocks -of_objects [get_pins clk_mmcm_inst/CLKOUT1]]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks clk_mmcm_out] \
    -group [get_clocks phy_rx_clk] \
    -group [get_clocks phy_tx_clk]