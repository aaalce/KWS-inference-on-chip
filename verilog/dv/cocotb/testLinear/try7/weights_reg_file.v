module weights_reg_file (
  input wire clk,
  input wire rst_n,
  input wire [4:0] row_addr,
  input wire [4:0] col_addr,
  output wire [31:0] data_out
);

// Define the register file to store the 20x20 weight matrix
reg [31:0] weights [0:19][0:19];

// Initialize the weights from the JSON file
initial begin
  $readmemh("weights.mem", weights);
end

// Assign the weight value based on the row and column addresses
assign data_out = weights[row_addr][col_addr];

endmodule