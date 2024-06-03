# Makefile

# Defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Verilog source files
VERILOG_SOURCES += $(PWD)/relu_32int.v

# Toplevel module name
TOPLEVEL = relut32int

# Python test module name
MODULE = test_relu

# Include Cocotb's make rules
include $(shell cocotb-config --makefiles)/Makefile.sim
