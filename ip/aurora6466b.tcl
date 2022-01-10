create_ip -name aurora_64b66b -vendor xilinx.com -library ip -version 12.0 -module_name aurora_64b66b_0

set_property -dict [list CONFIG.drp_mode {Native} CONFIG.SupportLevel {1}] [get_ips aurora_64b66b_0]

set_property -dict [list CONFIG.CHANNEL_ENABLE {X1Y0 X1Y1 X1Y2 X1Y3} CONFIG.C_AURORA_LANES {4} CONFIG.C_GT_LOC_4 {4} CONFIG.C_GT_LOC_3 {3} CONFIG.C_GT_LOC_2 {2}] [get_ips aurora_64b66b_0]

set_property -dict [list CONFIG.interface_mode {Streaming}] [get_ips aurora_64b66b_0]

set_property -dict [list CONFIG.C_USE_BYTESWAP {true}] [get_ips aurora_64b66b_0]

generate_target {instantiation_template} [get_files $g_root_dir/ip/aurora/aurora_64b66b_0.xci]
