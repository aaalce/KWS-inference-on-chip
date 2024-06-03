# Makefile

# Defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Add your Verilog source files here
VERILOG_SOURCES += $(PWD)/linear.v
VERILOG_SOURCES += $(PWD)/EF_SRAM_1024x32_wrapper.v
VERILOG_SOURCES += $(PWD)/EF_SRAM_1024x32_stub.v
VERILOG_SOURCES += $(PWD)/EF_SRAM_1024x32_wrapper_with_init.v
VERILOG_SOURCES += $(PWD)/SRAM_1024x32.v


# TOPLEVEL is the name of the toplevel module in your Verilog file
TOPLEVEL = linear

# MODULE is the basename of the Python test file
MODULE = test_linear

# Include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
