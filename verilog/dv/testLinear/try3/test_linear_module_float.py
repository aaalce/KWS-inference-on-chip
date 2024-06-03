import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly
import json
import logging

def to_fixed_point(value, fraction_bits=24):
    return int(round(value * (1 << fraction_bits)))

# Load input data from fromcmvn.json
with open('fromcmvn.json', 'r') as file:
    input_data = json.load(file)
    print("Input data loaded from fromcmvn.json:")
    print(input_data)

# Load linear weights from linear1724.json
with open('linear1724.json', 'r') as file:
    linear_weights_data = json.load(file)
    linear_weights = linear_weights_data['linear_subsampling']['ls1_linear_weight']

@cocotb.test(timeout_time=100000, timeout_unit="ns")
async def test_linear_module(dut):
    # Create a clock signal
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Initialize input data and linear weights
    for i in range(20):
        for j in range(20):
            dut.linear_weights[i * 20 + j].value = int(linear_weights[i][j])

    # Drive the input data
    for i in range(0, len(input_data), 20):
        print(f"Processing input data from index {i} to {i+20}")
        for j in range(20):
            if i + j < len(input_data):
                fixed_point_value = to_fixed_point(input_data[i + j])
                dut.cmvn_input_data.value = fixed_point_value
                dut.cmvn_input_addr.value = j
                dut.cmvn_input_valid.value = 1
                await RisingEdge(dut.clk)
            else:
                dut.cmvn_input_valid.value = 0
                await RisingEdge(dut.clk)

        dut.linear_en.value = 1
        await RisingEdge(dut.clk)
        dut.linear_en.value = 0

        await Timer(100, units="ns")  # Wait for computation to complete

        # Check the output data
        output_data = []
        for j in range(20):
            await RisingEdge(dut.clk)
            output_data.append(int(dut.output_data.value))

        logging.info(f"Input row {i // 20}: {input_data[i:i+20]}")
        logging.info(f"Output row {i // 20}: {output_data}")

    # Store the output data in output.json
    with open('output.json', 'w') as file:
        json.dump(output_data, file)
