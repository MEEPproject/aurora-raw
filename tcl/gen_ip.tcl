# Copyright 2022 Barcelona Supercomputing Center-Centro Nacional de Supercomputación

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Francelly Cano, BSC-CNS
# Date: 22.02.2022
# Description: 


source $root_dir/tcl/environment.tcl
source $root_dir/tcl/project_options.tcl

set ip_properties [ list \
    vendor "meep-project.eu" \
    library "MEEP" \
    name "MEEP_${g_design_name}" \
    version "$g_ip_version" \
    taxonomy "/MEEP_IP" \
    display_name "MEEP Aurora RAW" \
    description "${g_ip_description}" \
    vendor_display_name "MEEP Project" \
    company_url "https://meep-project.eu/" \
    ]

set family_lifecycle { \
  virtexuplusHBM Production \
}


# Package project and set properties
ipx::package_project
set ip_core [ipx::current_core]
set_property -dict ${ip_properties} ${ip_core}
set_property SUPPORTED_FAMILIES ${family_lifecycle} ${ip_core}


## Relative path to IP root directory
ipx::create_xgui_files ${ip_core} -logo_file "misc/BSC-Logo.png"
set_property type LOGO [ipx::get_files "misc/BSC-Logo.png" -of_objects [ipx::get_file_groups xilinx_utilityxitfiles -of_objects [ipx::current_core]]]


ipx::add_bus_interface gt_refclk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:diff_clock_rtl:1.0 [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:diff_clock:1.0 [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property abstraction_type_vlnv xilinx.com:interface:gt_rtl:1.0 [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:gt:1.0 [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
ipx::add_port_map GRX_P [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property physical_name RXP [ipx::get_port_maps GRX_P -of_objects [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]]
ipx::add_port_map GTX_N [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property physical_name TXN [ipx::get_port_maps GTX_N -of_objects [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]]
ipx::add_port_map GRX_N [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property physical_name RXN [ipx::get_port_maps GRX_N -of_objects [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]]
ipx::add_port_map GTX_P [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property physical_name TXP [ipx::get_port_maps GTX_P -of_objects [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]]
set_property name aurora_mgt [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
ipx::add_bus_interface gt_refclk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:diff_clock_rtl:1.0 [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:diff_clock:1.0 [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
ipx::add_port_map CLK_P [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property physical_name GT_REFCLK1_P [ipx::get_port_maps CLK_P -of_objects [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]]
ipx::add_port_map CLK_N [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
set_property physical_name GT_REFCLK1_N [ipx::get_port_maps CLK_N -of_objects [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces gt_refclk -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces S_USER_AXIS_UI_TX -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces M_USER_AXIS_UI_RX -of_objects [ipx::current_core]]

ipx::infer_bus_interface USER_CLK_OUT xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface SYS_RESET_OUT xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::associate_bus_interfaces -busif M_USER_AXIS_UI_RX -clock USER_CLK_OUT [ipx::current_core]
ipx::associate_bus_interfaces -busif S_USER_AXIS_UI_TX -clock USER_CLK_OUT [ipx::current_core]



# Save IP and close project
ipx::check_integrity ${ip_core}
ipx::save_core ${ip_core}

puts "IP succesfully packaged " 
