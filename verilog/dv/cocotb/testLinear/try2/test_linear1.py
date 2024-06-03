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
    input_addr = 0
    output_data_fixed = []
    output_data_float = []

    # Create a log to store multiplication and accumulation details
    log = []

    # Run the test
    for data in input_data:
        dut.linear_en.value = 1
        dut.input_addr.value = input_addr

        # Assign the 32-bit fixed-point 1.7.24 input data directly
        dut.input_data.value = data

        await RisingEdge(dut.clk)
        await Timer(1, units='ns')  # Wait for 1 ns

        # Debug output
        print(f"Input Address: {input_addr}, Input Data: {data}")

        # Wait for output to be valid
        while not dut.output_valid.value:
            await RisingEdge(dut.clk)

        # Get the 32-bit fixed-point 1.7.24 output data
        output_fixed_point = dut.output_data.value.binstr

        # Check for unresolved bits in the output data
        if 'x' in output_fixed_point or 'z' in output_fixed_point:
            print(f"Warning: Unresolved bits in output data at address {input_addr}")
            output_data_fixed.append(None)
            output_data_float.append(None)
        else:
            output_fixed_point = int(output_fixed_point, 2)
            output_data_fixed.append(output_fixed_point)

            # Convert 32-bit fixed-point 1.7.24 format to float
            output_float = fixed_to_float(output_fixed_point, 7, 24)
            output_data_float.append(output_float)

        # Debug output
        print(f"Output Address: {dut.output_addr.value}, Output Data (Fixed): {output_fixed_point}, Output Data (Float): {output_float}")

        # Log multiplication and accumulation details
        mult_log = []
        acc_log = []
        for i in range(20):
            mult_result = dut._linear_inst.mult_result.value.signed_integer
            weight = dut._linear_inst.wbs_dat_o.value.integer
            mult_log.append(f"Input: {data}, Weight: {weight}, Multiplication Result: {mult_result}")
            
            acc_result = dut._linear_inst.acc_result.value.signed_integer
            acc_log.append(f"Accumulation Result: {acc_result}")
            
            await RisingEdge(dut.clk)

        log.append({
            "input_addr": input_addr,
            "input_data": data,
            "mult_log": mult_log,
            "acc_log": acc_log
        })

        input_addr += 1

    # Write fixed-point output data to output_fixed.json
    with open('output_fixed.json', 'w') as f:
        json.dump(output_data_fixed, f)

    # Write float output data to output_float.json
    with open('output_float.json', 'w') as f:
        json.dump(output_data_float, f)

    # Write log to log.json
    with open('log.json', 'w') as f:
        json.dump(log, f, indent=2)

    # Timeout
    await Timer(10000, units='ns')