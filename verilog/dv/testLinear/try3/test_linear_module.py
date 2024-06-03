import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly
import json
import logging
import sys
import os

# Load input data from fromcmvn.json
with open('fromcmvn.json', 'r') as file:
    input_data = json.load(file)

# Load linear weights from linear1724.json
with open('linear1724.json', 'r') as file:
    linear_weights_data = json.load(file)
    linear_weights = linear_weights_data['linear_subsampling']['ls1_linear_weight']

@cocotb.test(timeout_time=100000, timeout_unit="ns")
async def test_linear_module(dut):
    # Create a clock signal
    clock = Clock(dut.clk, 1, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Set the linear_mode signal
    dut.linear_mode.value = 0  # Set to 0 for CMVN input or 1 for ReLU input

    # Initialize input data and linear weights
    for i in range(20):
        for j in range(20):
            dut.linear_weights[i * 20 + j].value = int(linear_weights[i][j])

    # Drive the input data
    output_data = [[] for _ in range(50)]
    for i in range(50):
        for j in range(20):
            dut.cmvn_input_data.value = input_data[i * 20 + j]
            dut.cmvn_input_addr.value = j
            dut.cmvn_input_valid.value = 1
            await RisingEdge(dut.clk)

        dut.linear_en.value = 1
        await RisingEdge(dut.clk)
        dut.linear_en.value = 0

        await Timer(100, units="ns")  # Wait for computation to complete

        # Check the output data
        for j in range(20):
            await RisingEdge(dut.clk)
            if dut.output_valid.value == 1:
                output_data[i].append(int(dut.output_data.value))

        
        # Check the output data
        #row_output = []
        #for j in range(20):
            #await RisingEdge(dut.clk)
            #row_output.append(int(dut.output_data.value))
        #output_data.extend(row_output)

        #logging.info(f"Input row {i // 20}: {input_data[i:i+20]}")
        #logging.info(f"Output row {i // 20}: {row_output}")

    # Store the output data in output.json
    with open('output.json', 'w') as file:
        json.dump(output_data, file)

# Open the debug log file
debug_log_file = 'debug_log.txt'
with open(debug_log_file, 'w') as file:
    # Redirect stdout to the file
    original_stdout = sys.stdout
    sys.stdout = file

    # Run the simulation
    cocotb.test(test_linear_module)

    # Restore stdout
    sys.stdout = original_stdout