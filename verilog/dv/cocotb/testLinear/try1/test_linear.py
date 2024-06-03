import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly, with_timeout
from cocotb.utils import get_sim_time
import json

async def debug_output(dut):
    while True:
        await RisingEdge(dut.clk)
        if dut.output_valid.value == 1:
            output_value = dut.output_data.value.signed_integer
            print(f"Debug: Output data at time {get_sim_time(units='ns')}: {output_value}")

@cocotb.test()
async def test_linear(dut):
    # Load input data from fromcmvn.json
    with open("fromcmvn.json", "r") as file:
        input_data = json.load(file)

    # Initialize input signals
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.linear_en.value = 0
    dut.input_data.value = 0
    dut.input_addr.value = 0
    dut.systolic_en.value = 0
    dut.systolic_op.value = 0

    # Create a clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset the module
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # Start the linear operation
    await RisingEdge(dut.clk)
    dut.linear_en.value = 1
    dut.systolic_en.value = 1
    dut.systolic_op.value = 0

    # Feed input data
    for i in range(len(input_data)):
        dut.input_data.value = int(input_data[i])  # Assuming input data is already in the correct format
        dut.input_addr.value = i % 20
        await RisingEdge(dut.clk)

    # Wait for the output to be ready
    try:
        await with_timeout(RisingEdge(dut.output_valid), 1000, 'ns')
    except Exception as e:
        print("Error: Timed out waiting for output_valid to go high")
        raise e

    # Start the debug output monitor
    cocotb.start_soon(debug_output(dut))

    # Read and store the output data
    output_data = []
    for _ in range(20):
        await RisingEdge(dut.clk)
        output_value = dut.output_data.value.signed_integer
        output_data.append(output_value)

    # Print debug information
    print("Input Data:")
    print(input_data)
    print("Output Data:")
    print(output_data)

    # Save output data to output.json
    with open("output.json", "w") as file:
        json.dump(output_data, file)

    # Timeout after 1000 clock cycles
    await Timer(1000, units="ns")

    # End the simulation
    dut.linear_en.value = 0
    dut.systolic_en.value = 0