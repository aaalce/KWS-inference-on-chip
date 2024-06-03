import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import json

def fixed_to_float(fixed_val, int_bits, frac_bits):
    if fixed_val & (1 << (int_bits + frac_bits)):
        fixed_val = fixed_val - (1 << (int_bits + frac_bits + 1))
    return fixed_val / (2 ** frac_bits)

@cocotb.test()
async def test_linear(dut):
    # Create a clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Read input data from fromcmvn.json
    with open('fromcmvn.json', 'r') as f:
        input_data = json.load(f)

    # Initialize input data
    output_data_fixed = []
    output_data_float = []

    # Create a log file to store multiplication and accumulation details
    log_file = open('log.txt', 'w')

    # Set timeout value (in nanoseconds)
    timeout = 100000  # Adjust the timeout value as needed

    # Run the test
    for i in range(len(input_data)):
        dut.linear_en.value = 1
        dut.input_addr.value = i

        # Provide input data
        dut.input_data.value = input_data[i]

        await RisingEdge(dut.clk)
        await Timer(1, units='ns')  # Wait for 1 ns

        # Write input details to the log file
        log_file.write(f"Input Address: {i}, Input Data: {input_data[i]}\n")

        # Wait for output to be valid or timeout
        start_time = cocotb.utils.get_sim_time(units='ns')
        while not dut.output_valid.value:
            await RisingEdge(dut.clk)
            current_time = cocotb.utils.get_sim_time(units='ns')
            if current_time - start_time > timeout:
                log_file.write(f"Timeout reached at Input Address: {i}, Input Data: {input_data[i]}\n")
                log_file.close()
                raise cocotb.test.timeout.SimTimeoutError

        # Get the 32-bit fixed-point output data
        output_fixed_point = dut.output_data.value.integer

        output_data_fixed.append(output_fixed_point)

        # Convert 32-bit fixed-point format to float
        output_float = fixed_to_float(output_fixed_point, 7, 24)
        output_data_float.append(output_float)

        # Write output details to the log file
        log_file.write(f"Output Address: {dut.output_addr.value}, Output Data (Fixed): {output_fixed_point}, Output Data (Float): {output_float}\n")

        # Log multiplication and accumulation details
        for j in range(20):
            mult_result = dut.mult_result.value.signed_integer
            weight = dut.weight_data.value.integer
            acc_result = dut.acc_result.value.signed_integer
            log_file.write(f"Input: {input_data[i]}, Weight: {weight}, Multiplication Result: {mult_result}, Accumulation Result: {acc_result}\n")
            await RisingEdge(dut.clk)

    # Close the log file
    log_file.close()

    # Write fixed-point output data to output_fixed.json
    with open('output_fixed.json', 'w') as f:
        json.dump(output_data_fixed, f)

    # Write float output data to output_float.json
    with open('output_float.json', 'w') as f:
        json.dump(output_data_float, f)
