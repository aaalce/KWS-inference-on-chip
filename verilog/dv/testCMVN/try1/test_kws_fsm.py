import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
import json

@cocotb.test(timeout_time=100000, timeout_unit="ns")  # Set a timeout of 100,000 ns (adjust as needed)
async def test_kws_fsm(dut):
    # Read the test data from the file
    with open("test1.txt", "r") as file:
        test_data = json.load(file)

    # Extract the relevant data from the test data
    fbank = test_data["fbank"]

    # Create a clock signal
    clock = Clock(dut.clk, 10, units="ns")  # Adjust the clock period as needed
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Perform the CMVN calculation for each frame in the fbank data
    output_data = []
    for i in range(len(fbank)):
        for j in range(len(fbank[i])):
            dut.start.value = 1
            dut.opcode.value = 0b0011  # CMVN opcode
            dut.input_data.value = fbank[i][j]
            dut.feature_idx.value = j
            await RisingEdge(dut.clk)
            dut.start.value = 0

            # Wait for the CMVN calculation to complete with a timeout
            timeout_count = 0
            while not dut.done.value:
                await RisingEdge(dut.clk)
                timeout_count += 1
                if timeout_count >= 1000:  # Adjust the timeout count as needed
                    print(f"Timeout occurred while waiting for CMVN calculation to complete at frame {i+1}, feature {j+1}")
                    break

            output_data.append(dut.cmvn_output_data.value.integer)

            # Print debug information
            print(f"Frame {i+1}, Feature {j+1}: Input = {fbank[i][j]}, Output = {dut.cmvn_output_data.value.integer}")

    # Print the input and output data
    print("Input Fbank:")
    for i in range(len(fbank)):
        print(f"  Frame {i+1}: {fbank[i]}")
    print("Output Data:")
    for i in range(len(output_data)):
        print(f"  Output {i+1}: {output_data[i]}")

    # Add any additional assertions or checks here
