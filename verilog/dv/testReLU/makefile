# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Add your Verilog source files here
VERILOG_SOURCES += $(PWD)/relu.v

# Add your VHDL source files here
# VHDL_SOURCES += $(PWD)/my_vhdl_file.vhd

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = relu

# MODULE is the basename of the Python test file
MODULE = test_relu

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim