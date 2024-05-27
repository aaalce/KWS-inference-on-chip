

00 Designing a KWS Inference Accelerator for Caravel Harness SoC

X:
hiya, I'm trying to design a KWS inference accelerator inside a Caravel Harness SoC user project area. I have a pretrained model in python, which included a dilated CNN. I have obtained the parameters. Given the pipeline and parameters file(pipeline&para), and the original python code(kws_hhz), can you give me an simple ISA and some idea about the macro architecture please?

Claude:
Based on the provided pipeline, parameters, and the original Python code, here's a suggestion for a simple ISA (Instruction Set Architecture) and macro architecture for your KWS (Keyword Spotting) inference accelerator:
ISA:
CMVN (Cepstral Mean and Variance Normalization)
Instruction: CMVN
Operands: input_data, cmvn_mean, cmvn_istd
Description: Applies CMVN normalization to the input data using the pre-computed mean and inverse standard deviation.
LINEAR
Instruction: LINEAR
Operands: input_data, linear_weight, linear_bias
Description: Performs a linear transformation on the input data using the provided weight matrix and bias vector.
RELU
Instruction: RELU
Operands: input_data
Description: Applies the ReLU activation function to the input data.
DILATED_CNN
Instruction: DILATED_CNN
Operands: input_data, dilation, kernel_size, cnn_weight, cnn_bias
Description: Performs a dilated convolution operation on the input data using the provided dilation rate, kernel size, weight tensor, and bias vector.
BATCH_NORM
Instruction: BATCH_NORM
Operands: input_data, bn_gamma, bn_beta, bn_mean, bn_var
Description: Applies batch normalization to the input data using the pre-computed gamma, beta, running mean, and running variance.
SIGMOID
Instruction: SIGMOID
Operands: input_data
Description: Applies the sigmoid activation function to the input data.
Macro Architecture:
Input Buffer: A memory buffer to store the input features.
Parameter Memory: A memory unit to store the pre-trained model parameters such as weights, biases, means, and variances.
Instruction Decoder: Decodes the instructions from the ISA and generates control signals for the execution units.
Execution Units:
CMVN Unit: Performs CMVN normalization on the input data.
Linear Unit: Performs linear transformations using matrix-vector multiplication and addition.
ReLU Unit: Applies the ReLU activation function to the input data.
Dilated CNN Unit: Performs dilated convolution operations on the input data.
Batch Normalization Unit: Applies batch normalization to the input data.
Sigmoid Unit: Applies the sigmoid activation function to the input data.
Output Buffer: A memory buffer to store the output results.
Control Unit: Orchestrates the overall execution flow and manages the data movement between the input buffer, parameter memory, execution units, and output buffer.
The macro architecture would follow the pipeline sequence:
Input Buffer -> CMVN Unit -> Linear Unit -> ReLU Unit -> Dilated CNN Unit -> Batch Normalization Unit -> ReLU Unit -> ... -> Linear Unit -> Sigmoid Unit -> Output Buffer
The execution flow would be controlled by the Control Unit, which fetches instructions from the instruction memory, decodes them using the Instruction Decoder, and triggers the appropriate execution units. The necessary parameters for each operation would be read from the Parameter Memory.
This is a simplified ISA and macro architecture based on the provided information. You can further refine and optimize it based on your specific requirements, such as data precision, memory bandwidth, and performance targets. Additionally, you may need to consider the interface with the Caravel Harness SoC and ensure proper integration with the user project area.


X:
The accelerator interfaces with a RISC-V core on Caravel Harness management area via wishbone bus. I would need to load input data and parameters from the RISC-V core and send out output too, can you include some instructions for this?
The other thing I need you to be aware of is there are two process that’s using the convolution functionality, the Dilated CNN and CNN, which Dilated CNN would require an extra step of padding. Hence I would like to have two instructions: CNN and Padding instead of Dilated CNN
Can you update the ISA accordingly?

Claude:
Certainly! Here's an updated ISA that includes instructions for loading input data and parameters from the RISC-V core, sending output back, and separate instructions for CNN and Padding:
ISA:
LOAD_INPUT
Instruction: LOAD_INPUT
Operands: input_address, input_size
Description: Loads the input data from the specified address in the RISC-V core's memory via the Wishbone bus into the accelerator's input buffer.
LOAD_PARAM
Instruction: LOAD_PARAM
Operands: param_address, param_size
Description: Loads the model parameters (weights, biases, means, variances) from the specified address in the RISC-V core's memory via the Wishbone bus into the accelerator's parameter memory.
STORE_OUTPUT
Instruction: STORE_OUTPUT
Operands: output_address
Description: Stores the output results from the accelerator's output buffer to the specified address in the RISC-V core's memory via the Wishbone bus.
CMVN
Instruction: CMVN
Operands: input_data, cmvn_mean, cmvn_istd
Description: Applies CMVN normalization to the input data using the pre-computed mean and inverse standard deviation.
LINEAR
Instruction: LINEAR
Operands: input_data, linear_weight, linear_bias
Description: Performs a linear transformation on the input data using the provided weight matrix and bias vector.
RELU
Instruction: RELU
Operands: input_data
Description: Applies the ReLU activation function to the input data.
PADDING
Instruction: PADDING
Operands: input_data, padding_size
Description: Applies padding to the input data by adding zeros around the edges. The padding size specifies the number of zeros to add on each side.
CNN
Instruction: CNN
Operands: input_data, kernel_size, cnn_weight, cnn_bias
Description: Performs a convolution operation on the input data using the provided kernel size, weight tensor, and bias vector.
BATCH_NORM
Instruction: BATCH_NORM
Operands: input_data, bn_gamma, bn_beta, bn_mean, bn_var
Description: Applies batch normalization to the input data using the pre-computed gamma, beta, running mean, and running variance.
SIGMOID
Instruction: SIGMOID
Operands: input_data
Description: Applies the sigmoid activation function to the input data.
The macro architecture would remain similar to the previous description, with the addition of the Wishbone bus interface for communication with the RISC-V core. The execution flow would be as follows:
The RISC-V core loads the input data into the accelerator's input buffer using the LOAD_INPUT instruction via the Wishbone bus.
The RISC-V core loads the model parameters into the accelerator's parameter memory using the LOAD_PARAM instruction via the Wishbone bus.
The accelerator executes the pipeline sequence: Input Buffer -> CMVN -> LINEAR -> RELU -> PADDING (for Dilated CNN) -> CNN -> BATCH_NORM -> RELU -> ... -> LINEAR -> SIGMOID -> Output Buffer
The RISC-V core retrieves the output results from the accelerator's output buffer using the STORE_OUTPUT instruction via the Wishbone bus.
The Padding instruction is used specifically for the Dilated CNN operation to add the necessary padding to the input data before performing the convolution. The CNN instruction is used for both the Dilated CNN (after padding) and the regular CNN operations.
The Wishbone bus interface in the accelerator would handle the communication and data transfer between the RISC-V core and the accelerator's memory units (input buffer, parameter memory, output buffer).




X
I would like to have a finite state machine as my controller. Systolic architecture for my calculation area.

Claude:
Great! Here's an updated macro architecture that incorporates a finite state machine (FSM) as the controller and a systolic array for the calculation area:
Macro Architecture:
Input Buffer: A memory buffer to store the input features.
Parameter Memory: A memory unit to store the pre-trained model parameters such as weights, biases, means, and variances.
Systolic Array:
A 2D array of processing elements (PEs) that performs the main computations.
Each PE consists of a multiplier, an adder, and a register.
The systolic array is used for the following operations:
Linear transformation (matrix-vector multiplication)
Convolution (CNN)
Batch Normalization
Activation Function Units:
ReLU Unit: Applies the ReLU activation function to the input data.
Sigmoid Unit: Applies the sigmoid activation function to the input data.
Output Buffer: A memory buffer to store the output results.
Finite State Machine (FSM) Controller:
A control unit that manages the overall execution flow of the accelerator.
The FSM consists of states and transitions between the states based on the instructions and control signals.
The FSM generates control signals for the systolic array, activation function units, and memory units.
Wishbone Bus Interface:
Handles the communication and data transfer between the RISC-V core and the accelerator's memory units (input buffer, parameter memory, output buffer).
Implements the necessary Wishbone bus protocols for reading and writing data.
Execution Flow:
Initialization:
The RISC-V core loads the input data into the accelerator's input buffer using the LOAD_INPUT instruction via the Wishbone bus.
The RISC-V core loads the model parameters into the accelerator's parameter memory using the LOAD_PARAM instruction via the Wishbone bus.
FSM Controller:
The FSM starts in an idle state and waits for the start signal from the RISC-V core.
Once the start signal is received, the FSM transitions to the execution states based on the pipeline sequence.
Execution States:
CMVN State: The systolic array performs CMVN normalization on the input data.
Linear State: The systolic array performs linear transformation using matrix-vector multiplication.
ReLU State: The ReLU unit applies the ReLU activation function to the output of the linear transformation.
Padding State: The systolic array applies padding to the input data for the Dilated CNN operation.
CNN State: The systolic array performs convolution operation on the padded or non-padded input data.
Batch Norm State: The systolic array performs batch normalization on the output of the CNN operation.
Sigmoid State: The Sigmoid unit applies the sigmoid activation function to the final output.
Output:
The final output is stored in the output buffer.
The RISC-V core retrieves the output results from the accelerator's output buffer using the STORE_OUTPUT instruction via the Wishbone bus.
The FSM controller orchestrates the transitions between the execution states based on the completion of each operation. It generates the necessary control signals for the systolic array, activation function units, and memory units to perform the required computations.
The systolic array architecture allows for efficient matrix-vector multiplications and convolutions by exploiting data reuse and parallel processing. The PEs in the systolic array communicate with their neighboring PEs to exchange data and perform the computations in a synchronized manner.
The Wishbone bus interface facilitates the communication between the RISC-V core and the accelerator, allowing the core to control and monitor the accelerator's operation and exchange data.
By combining the FSM controller, systolic array, activation function units, and memory units, the accelerator can efficiently execute the KWS inference pipeline while leveraging the benefits of systolic architecture for improved performance and resource utilization.



X
Perfect! Can you come up with a formal ISA including opcodes and descriptions?

Claude:
Certainly! Here's a formal ISA with opcodes and descriptions for the KWS inference accelerator:
Opcode
Instruction
Operands
Description
0x00
LOAD_INPUT
input_address, input_size
Loads the input data from the RISC-V core's memory to the accelerator's input buffer.
0x01
LOAD_PARAM
param_address, param_size
Loads the model parameters from the RISC-V core's memory to the accelerator's parameter memory.
0x02
STORE_OUTPUT
output_address
Stores the output results from the accelerator's output buffer to the RISC-V core's memory.
0x03
CMVN
input_data, cmvn_mean, cmvn_istd
Applies CMVN normalization to the input data.
0x04
LINEAR
input_data, linear_weight, linear_bias
Performs a linear transformation on the input data.
0x05
RELU
input_data
Applies the ReLU activation function to the input data.
0x06
PADDING
input_data, padding_size
Applies padding to the input data by adding zeros around the edges.
0x07
CNN
input_data, kernel_size, cnn_weight, cnn_bias
Performs a convolution operation on the input data.
0x08
BATCH_NORM
input_data, bn_gamma, bn_beta, bn_mean, bn_var
Applies batch normalization to the input data.
0x09
SIGMOID
input_data
Applies the sigmoid activation function to the input data.
0x0A
START
-
Starts the execution of the accelerator.
0x0B
STOP
-
Stops the execution of the accelerator.
Instruction Format:
Each instruction is 32 bits wide.
The opcode is represented by the first 4 bits (bits 31-28).
The remaining 28 bits (bits 27-0) are used for operands, which can include memory addresses, data sizes, or immediate values depending on the instruction.
Operand Format:
input_address, param_address, output_address: 32-bit memory addresses pointing to the respective data in the RISC-V core's memory.
input_size, param_size: 32-bit unsigned integers specifying the size of the input data and model parameters, respectively.
input_data, cmvn_mean, cmvn_istd, linear_weight, linear_bias, kernel_size, cnn_weight, cnn_bias, bn_gamma, bn_beta, bn_mean, bn_var: 32-bit immediate values or memory addresses pointing to the respective data in the accelerator's memory.
padding_size: 32-bit unsigned integer specifying the size of padding to be applied.
Execution Flow:
The RISC-V core sends the LOAD_INPUT and LOAD_PARAM instructions to load the input data and model parameters into the accelerator's memory.
The RISC-V core sends the START instruction to begin the execution of the accelerator.
The accelerator's FSM controller starts executing the pipeline sequence based on the received instructions.
The accelerator performs the specified operations using the systolic array and activation function units.
Upon completion, the accelerator stores the output results in its output buffer.
The RISC-V core sends the STORE_OUTPUT instruction to retrieve the output results from the accelerator's output buffer.
The RISC-V core sends the STOP instruction to halt the execution of the accelerator.
This ISA provides a set of instructions for loading data, performing KWS inference operations, and storing the output results. The opcode field identifies the specific instruction, while the operands provide the necessary data or memory addresses for each instruction.
The accelerator's FSM controller interprets these instructions and generates the appropriate control signals to orchestrate the execution flow within the accelerator's systolic array and activation function units.



X
I'm trying to save storage, so all my data will be in 16 bits format, will you be able to update the instructions and operand?

Claude:
Certainly! Here's the updated ISA with 16-bit instructions and operands:
Opcode
Instruction
Operands
Description
0x0
LOAD_INPUT
input_address_high, input_address_low, input_size
Loads the input data from the RISC-V core's memory to the accelerator's input buffer.
0x1
LOAD_PARAM
param_address_high, param_address_low, param_size
Loads the model parameters from the RISC-V core's memory to the accelerator's parameter memory.
0x2
STORE_OUTPUT
output_address_high, output_address_low
Stores the output results from the accelerator's output buffer to the RISC-V core's memory.
0x3
CMVN
cmvn_mean_address, cmvn_istd_address
Applies CMVN normalization to the input data.
0x4
LINEAR
linear_weight_address, linear_bias_address
Performs a linear transformation on the input data.
0x5
RELU
-
Applies the ReLU activation function to the input data.
0x6
PADDING
padding_size
Applies padding to the input data by adding zeros around the edges.
0x7
CNN
kernel_size, cnn_weight_address, cnn_bias_address
Performs a convolution operation on the input data.
0x8
BATCH_NORM
bn_gamma_address, bn_beta_address, bn_mean_address, bn_var_address
Applies batch normalization to the input data.
0x9
SIGMOID
-
Applies the sigmoid activation function to the input data.
0xA
START
-
Starts the execution of the accelerator.
0xB
STOP
-
Stops the execution of the accelerator.
Instruction Format:
Each instruction is 16 bits wide.
The opcode is represented by the first 4 bits (bits 15-12).
The remaining 12 bits (bits 11-0) are used for operands, which can include memory addresses, data sizes, or immediate values depending on the instruction.
Operand Format:
Memory addresses are split into two 16-bit parts: address_high (bits 15-0) and address_low (bits 15-0). The full 32-bit memory address is formed by concatenating address_high and address_low.
input_address_high, input_address_low, param_address_high, param_address_low, output_address_high, output_address_low: 16-bit parts of the respective 32-bit memory addresses pointing to the data in the RISC-V core's memory.
input_size, param_size, padding_size, kernel_size: 16-bit unsigned integers specifying the sizes or immediate values.
cmvn_mean_address, cmvn_istd_address, linear_weight_address, linear_bias_address, cnn_weight_address, cnn_bias_address, bn_gamma_address, bn_beta_address, bn_mean_address, bn_var_address: 16-bit memory addresses pointing to the respective data in the accelerator's memory.
Execution Flow:
The execution flow remains the same as previously described, with the RISC-V core sending instructions and data to the accelerator, and the accelerator's FSM controller orchestrating the execution of the pipeline sequence.
Note:
The input data, model parameters, and output results are assumed to be 16-bit values to align with the 16-bit data format.
The accelerator's internal memory (input buffer, parameter memory, output buffer) should be designed to accommodate 16-bit data.
The systolic array and activation function units should be adapted to operate on 16-bit data.
By using 16-bit instructions and operands, the storage requirements for the ISA and data can be reduced compared to the 32-bit version. However, it's important to ensure that the 16-bit data format provides sufficient precision for the KWS inference task and to make necessary adjustments in the accelerator's internal components to handle 16-bit data accurately.
