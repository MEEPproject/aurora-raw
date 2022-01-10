ROOT_DIR  = $(PWD)
IP_DIR    = $(ROOT_DIR)/ip/aurora_dma_ip
VIVADO_VER  := 2020.1
VIVADO_PATH := /opt/Xilinx/Vivado/$(VIVADO_VER)/bin/
VIVADO_XLNX := $(VIVADO_PATH)/vivado
VIVADO_OPT  := -mode batch -nolog -nojournal -notrace -source


#Generate the Aurora DMA IP

generate_ip:
		echo "Generate Aurora DMA IP"
		$(VIVADO_XLNX) $(VIVADO_OPT)  ./tcl/gen_project.tcl


clean:
	git clean -f
	@(cd ip; find . -type f ! -name "*.tcl" -exec rm -r {} \;)
	rm -rf xgui project



