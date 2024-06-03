import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadOnly, ClockCycles
import json
import random

# Read input data from test1.json file
with open("test1.json", "r") as file:
    data = json.load(file)

# Extract the fbank data from the input
fbank_data = data["fbank"]

# Convert the input data to fixed-point format (1.7.24)
def to_fixed_point(value):
    return int(value * (1 << 24))

@cocotb.test()
async def test_cmvn(dut):
    # Create a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # 10ns period, i.e., 100MHz
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Create an empty list to store the output values
    output_values = []

    try:
        # Iterate over the input data
        for i in range(len(fbank_data)):
            for j in range(len(fbank_data[i])):
                # Wait for the rising edge of the clock
                await RisingEdge(dut.clk)

                # Set the input data and address
                input_value = to_fixed_point(fbank_data[i][j])
                if input_value > 2**31 - 1 or input_value < -2**31:
                    raise ValueError(f"Input value {input_value} is out of range for a 32-bit signal")
                dut.input_data.value = input_value
                dut.input_addr.value = j
                dut.cmvn_en.value = 1

                # Wait for the output to be valid
                await RisingEdge(dut.output_valid)

                # Read the output data
                output_value = dut.output_data.value.signed_integer

                # Print the input and output values for debugging
                print(f"Input: {fbank_data[i][j]}, Output: {output_value}")

                # Append the fixed-point value to the output list
                output_values.append(output_value)

            # Disable the CMVN module
            dut.cmvn_en.value = 0

    except ValueError as e:
        print(f"Error: {str(e)}")
        raise

    # Wait for a few clock cycles before ending the test
    await ClockCycles(dut.clk, 5)

    # Write the output values to a JSON file
    with open("output.json", "w") as file:
        json.dump(output_values, file, indent=2)

# Timeout for the test
@cocotb.test(expect_error=True)
async def test_timeout(dut):
    # Wait for the timeout to occur
    await Timer(10000, units="ns")
    assert False, "Test timed out"
