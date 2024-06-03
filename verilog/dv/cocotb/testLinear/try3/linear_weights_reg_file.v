module linear_weights_reg_file (
  input wire clk,
  input wire rst_n,
  input wire [8:0] addr,
  input wire [31:0] din,
  input wire we,
  output reg [31:0] dout
);

  // Register file to store linear weights
  reg [31:0] weights [0:399];

  // Initialize the weights with predetermined values
  initial begin
    $readmemh("linear_weights.mem", weights);
  end

  // Read operation
  always @(posedge clk) begin
    if (!rst_n) begin
      dout <= 32'h00000000;
    end else begin
      dout <= weights[addr];
    end
  end

  // Write operation
  always @(posedge clk) begin
    if (!rst_n) begin
      // Reset all weights to 0
      for (integer i = 0; i < 400; i++) begin
        weights[i] <= 32'h00000000;
      end
    end else if (we) begin
      weights[addr] <= din;
    end
  end

endmodule
