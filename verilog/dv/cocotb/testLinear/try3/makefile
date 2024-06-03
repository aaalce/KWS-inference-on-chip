# Makefile

# Defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Add your Verilog source files here
VERILOG_SOURCES += $(PWD)/linear.v


# TOPLEVEL is the name of the toplevel module in your Verilog file
TOPLEVEL = linear

# MODULE is the basename of the Python test file
MODULE = test_linear_module

# Include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
