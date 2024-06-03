module linear_weights (
  input wire clk,
  input wire [8:0] addr,
  output reg signed [31:0] data
);

  // Register file to store Linear weights (1.7.24 format)
  reg signed [31:0] weights [0:399];

  // Initialize Linear weights
  initial begin
    // TODO: Initialize the weights with actual trained values
    // Example initialization:
    weights[0] = $signed(32'h01800000); // 1.5
    weights[1] = $signed(32'h00C00000); // 0.75
    // ... Initialize other weights
    weights[399] = $signed(32'h00400000); // 0.25
  end

  // Read weights based on input address
  always @(posedge clk) begin
    data <= weights[addr];
  end

endmodule