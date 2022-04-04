# Copyright 2022 Barcelona Supercomputing Center-Centro Nacional de Supercomputación

# Licensed under the Solderpad Hardware License v 2.1 (the "License");
# you may not use this file except in compliance with the License, or, at your option, the Apache License version 2.0.
# You may obtain a copy of the License at
# 
#     http://www.solderpad.org/licenses/SHL-2.1
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Francelly Cano, BSC-CNS
# Date: 22.02.2022
# Description: 


create_ip -name aurora_64b66b -vendor xilinx.com -library ip -version 12.0 -module_name aurora_64b66b_0

set_property -dict [list CONFIG.drp_mode {Native} CONFIG.SupportLevel {1}] [get_ips aurora_64b66b_0]

set_property -dict [list CONFIG.CHANNEL_ENABLE {X1Y0 X1Y1 X1Y2 X1Y3} CONFIG.C_AURORA_LANES {4} CONFIG.C_GT_LOC_4 {4} CONFIG.C_GT_LOC_3 {3} CONFIG.C_GT_LOC_2 {2}] [get_ips aurora_64b66b_0]

set_property -dict [list CONFIG.interface_mode {Streaming}] [get_ips aurora_64b66b_0]

set_property -dict [list CONFIG.C_USE_BYTESWAP {true}] [get_ips aurora_64b66b_0]

generate_target {instantiation_template} [get_files $g_root_dir/ip/aurora/aurora_64b66b_0.xci]
