import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
import json
import logging

@cocotb.test()
async def test_linear(dut):
    # Set up logging
    log_file = "linear_log.txt"
    logging.basicConfig(filename=log_file, level=logging.DEBUG)

    # Load input data and weights from JSON files
    with open("fromcmvn.json", "r") as file:
        input_data = json.load(file)
    with open("linear1724.json", "r") as file:
        weights_data = json.load(file)["linear_subsampling"]["ls1_linear_weight"]

    # Set up clock and reset
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1

    # Apply input data bit by bit
    for i in range(0, len(input_data), 20):
        for j in range(20):
            for k in range(32):  # Iterate over each bit
                dut.input_data[i // 20][j][k].value = (input_data[i + j] >> k) & 1

    # Apply weights
    for i in range(len(weights_data)):
        for j in range(len(weights_data[i])):
            dut.weight[i][j].value = weights_data[i][j]

    # Start the Linear module
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    # Wait for the Linear module to complete
    await Timer(1000, units="ns")  # Timeout of 1000ns
    while dut.done.value == 0:
        await RisingEdge(dut.clk)

    # Read the output data
    output_data = []
    for i in range(len(dut.output_data)):
        row_data = []
        for j in range(len(dut.output_data[i])):
            value = dut.output_data[i][j].value.integer
            row_data.append(value)
            logging.debug(f"Output[{i}][{j}]: {value}")
        output_data.append(row_data)

    # Save the output data to a JSON file
    with open("linear_output.json", "w") as file:
        json.dump(output_data, file)

    # Check the 'done' signal
    assert dut.done.value == 1, "Linear module did not complete"
