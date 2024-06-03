import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_relu(dut):
    # Create a clock
    clock = Clock(dut.clk, 10, units="ns")  # Adjust the clock period as needed
    cocotb.start_soon(clock.start())

    # Reset the module
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # Define the input matrix
    input_matrix = [
        [1, 2, -3, 4],
        [-1, 6, 7, 0],
        [9, -9, 0, 12]
    ]

    # Flatten the input matrix
    flattened_input = [value for row in input_matrix for value in row]

    # Assign the flattened input to the module
    for i in range(len(flattened_input)):
        dut.x[i].value = flattened_input[i]
        await RisingEdge(dut.clk)

    # Wait for a few clock cycles
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Check the output matrix
    expected_output = [
        [1, 2, 0, 4],
        [0, 6, 7, 0],
        [9, 0, 0, 12]
    ]

    # Store the output matrix in a text file
    with open("output_matrix.txt", "w") as file:
        for i in range(3):
            for j in range(4):
                file.write(str(dut.y[i*4+j].value.signed_integer) + " ")
            file.write("\n")

    # Flatten the expected output
    flattened_expected = [value for row in expected_output for value in row]

    # Check the flattened output against the flattened expected output
    for i in range(len(flattened_expected)):
        assert dut.y[i].value == flattened_expected[i], f"Expected {flattened_expected[i]}, but got {dut.y[i].value} at index {i}"

    # End the test
    await Timer(10, units="ns")
