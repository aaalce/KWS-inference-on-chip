import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, with_timeout
import json

# Debug module
@cocotb.coroutine
async def debug_monitor(dut, log_file):
    while True:
        await RisingEdge(dut.clk)
        log_file.write(f"Time: {cocotb.utils.get_sim_time()}, State: {dut.current_state.value}, Input: {dut.input_data.value}, Output: {dut.output_data.value}\n")
        await RisingEdge(dut.clk)  # Add an extra await to synchronize with the main test

@cocotb.test()
async def test_relu(dut):
    # Create a clock signal
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)

    # Read input data from JSON file
    with open("fromlinear.json", "r") as file:
        input_data = json.load(file)

    # Open log file for debug information
    with open("relu_debug.log", "w") as log_file:
        # Start the debug monitor
        debug_task = cocotb.start_soon(debug_monitor(dut, log_file))

        # Open output file for storing the results
        with open("relu_output.json", "w") as output_file:
            output_data = []

            # Iterate over input data and perform ReLU operation
            for i in range(1000):
                data = input_data[i % len(input_data)]  # Wrap around input data if needed
                dut.relu_en.value = 1
                dut.input_data.value = data
                dut.input_addr.value = i % 32  # Ensure input_addr is within valid range
                await FallingEdge(dut.clk)
                await FallingEdge(dut.clk)  # Wait for one clock cycle
                dut.relu_en.value = 0

                # Wait for output_valid signal with a timeout
                try:
                    await with_timeout(RisingEdge(dut.output_valid), timeout_time=100, timeout_unit="ns")
                    output_value = int(dut.output_data.value)  # Convert BinaryValue to int
                    output_addr = int(dut.output_addr.value)   # Convert BinaryValue to int
                    log_file.write(f"Input: {data}, Output: {output_value}, Address: {output_addr}\n")
                    output_data.append(output_value)
                except cocotb.result.SimTimeoutError:
                    log_file.write(f"Timed out waiting for output_valid signal at input {data}\n")
                    break

            # Write the output data to the output file
            json.dump(output_data, output_file)

        # Wait for a few clock cycles before ending the test
        await Timer(100, units="ns")

        # Cancel the debug monitor task
        debug_task.kill()