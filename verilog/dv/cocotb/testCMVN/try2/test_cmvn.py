import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ReadWrite
import json
import numpy as np

@cocotb.test()
async def test_cmvn(dut):
    # Load input data from test1.json
    with open("test1.json", "r") as file:
        data = json.load(file)
    input_data = np.array(data["fbank"], dtype=np.int32)

    # Create a clock
    clock = Clock(dut.clk, 10, units="ns")  # Adjust the clock period as needed
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Create an array to store the output data
    output_data = np.zeros((input_data.shape[0], input_data.shape[1]), dtype=np.int32)

    # Iterate over each input data point
    for i in range(input_data.shape[0]):
        for j in range(input_data.shape[1]):
            await ReadWrite()
            dut.cmvn_en.value = 1
            dut.input_data.value = int(input_data[i][j])
            await RisingEdge(dut.clk)
            dut.cmvn_en.value = 0

            # Wait for a valid output value
            while 'x' in dut.output_data.value.binstr:
                await RisingEdge(dut.clk)

            await ReadWrite()
            if 'x' not in dut.output_data.value.binstr:
                output_data[i][j] = int(dut.output_data.value)
                print(f"Input: {input_data[i][j]}, Output: {output_data[i][j]}")
            else:
                print(f"Input: {input_data[i][j]}, Output: Unresolvable 'x' bit")

        # Wait for the done signal
        while not dut.done.value:
            await RisingEdge(dut.clk)

    # Save the output data to a file
    output_dict = {
        "key": data["key"],
        "label": data["label"],
        "fbank": output_data.tolist()
    }
    with open("output.json", "w") as file:
        json.dump(output_dict, file)

    # Timeout after a larger number of clock cycles
    await Timer(10000, 'ns')

    # Generate the VCD file for waveform dumping
    dut._log.info("Enabling VCD dumping")
    cocotb.start_soon(cocotb.utils.dump_vcd("cmvn_dump.vcd"))
