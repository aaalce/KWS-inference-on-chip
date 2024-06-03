# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Add your Verilog source files here
VERILOG_SOURCES += $(PWD)/linear.v
VERILOG_SOURCES += $(PWD)/weights_reg_file.v

# Add your VHDL source files here
# VHDL_SOURCES += $(PWD)/my_vhdl_file.vhd

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = linear

# MODULE is the basename of the Python test file
MODULE = test_linear

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
