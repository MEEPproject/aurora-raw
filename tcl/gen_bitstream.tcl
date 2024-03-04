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


source [pwd]/tcl/environment.tcl

if { [catch {current_project} result] } {
open_project ${project_dir}/${g_project_name}.xpr
}

proc reportImpl {g_root_dir} {
	open_run impl_1
	file delete -force ./reports
	file mkdir $g_root_dir/reports
	report_clocks -file "${g_root_dir}/reports/clock.rpt"
	report_utilization -file "${g_root_dir}/reports/utilization.rpt"
	report_timing_summary -warn_on_violation -file "${g_root_dir}/reports/timing_summary.rpt"
	report_power -file "${g_root_dir}/reports/power.rpt"
	report_drc -file "${g_root_dir}/reports/drc_imp.rpt"
	report_timing -setup -file "${g_root_dir}/reports/timing_setup.rpt"
	report_timing -hold -file "${g_root_dir}/reports/timing_hold.rpt"
}

proc implementation { g_root_dir g_project_name } {

set number_of_jobs 4
reset_run impl_1
launch_runs impl_1 -jobs ${number_of_jobs}
wait_on_run impl_1
 
reportImpl $g_root_dir

write_bitstream -force ${g_root_dir}/${g_project_name}.bit

}
variable stepImpl 1
proc show_options {g_root_dir designStep g_project_name} {

variable stepSynth
variable stepImpl
variable stepBits

puts "Do you want to launch the ${designStep} process now? (Y/n)"
set option [gets stdin]
puts "\n"
puts "Selected Option: $option"
	switch -regexp $option {
		[Y,y] {
			switch $designStep {
				"synthesis" {
				set stepSynth 1
				}
				"implementation" {
				implementation $g_root_dir $g_project_name
				}
				"bitstream" {
				set stepBits 1
				}
			}
		}
		[N,n] {
			puts "The ${designStep} process won't be run" 
		}
		default {
		puts "No valid option selected, try again...\n"
		show_options $g_root_dir $designStep
		}
	}	
}

show_options $g_root_dir "implementation" $g_project_name
