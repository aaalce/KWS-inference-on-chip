`timescale 1ns / 1ps
module batch_normalize (
  input wire clk,
  input wire rst_n,
  input wire batch_norm_en,
  input wire [31:0] input_data,
  input wire [4:0] input_addr,
  output reg [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid
);

  // Register file to store batch normalization parameters (1.7.24 format)
  reg signed [31:0] bn_gamma [0:19];
  reg signed [31:0] bn_beta [0:19];
  reg signed [31:0] bn_mean [0:19];
  reg signed [31:0] bn_var [0:19];

  // Intermediate registers (1.7.24 format)
  reg signed [31:0] subtracted_data;
  reg signed [63:0] normalized_data;
  reg signed [63:0] scaled_data;
  reg signed [63:0] shifted_data;

  // Counter for input data
  reg [5:0] input_counter;

  // State machine states
  localparam IDLE = 2'b00;
  localparam SUBTRACT_MEAN = 2'b01;
  localparam NORMALIZE = 2'b10;
  localparam SCALE_AND_SHIFT = 2'b11;

  reg [1:0] current_state;
  reg [1:0] next_state;

  // Initialize batch normalization parameters (example values in 1.7.24 format)
  initial begin
    // Initialize bn_gamma, bn_beta, bn_mean, bn_var with appropriate values
    // ...
  end

  // State transition logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // Next state logic
  
  always @(*) begin
    subtracted_data = 32'h00000000; // Default value
    normalized_data = 64'h0000000000000000; // Default value
    shifted_data = 64'h0000000000000000; // Default value
    scaled_data = 64'h0000000000000000; // Default value

    case (current_state)
      IDLE: begin
        if (batch_norm_en) begin
          next_state = SUBTRACT_MEAN;
        end else begin
          next_state = IDLE;
        end
      end
      SUBTRACT_MEAN: begin
        next_state = NORMALIZE;
        subtracted_data = $signed(input_data) - $signed(bn_mean[input_addr]);
      end
      NORMALIZE: begin
        next_state = SCALE_AND_SHIFT;
        normalized_data = $signed(subtracted_data) / $signed(bn_var[input_addr]);
      end
      SCALE_AND_SHIFT: begin
        if (input_counter < 50) begin
          next_state = SUBTRACT_MEAN;
        end else begin
          next_state = IDLE;
        end
        scaled_data = $signed(normalized_data) * $signed(bn_gamma[input_addr]);
        shifted_data = $signed(scaled_data) + $signed(bn_beta[input_addr]);
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  // Output logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      output_data <= 32'h00000000;
      output_addr <= 5'h00;
      output_valid <= 1'b0;
      input_counter <= 6'h00;
    end else begin
      case (current_state)
        IDLE: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
          input_counter <= 6'h00;
        end
        SUBTRACT_MEAN: begin
          // Do nothing
        end
        NORMALIZE: begin
          // Do nothing
        end
        SCALE_AND_SHIFT: begin
          output_data <= shifted_data[31:0]; // Extract the 32-bit result
          output_addr <= input_addr;
          output_valid <= 1'b1;
          input_counter <= input_counter + 1;
        end
        default: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
        end
      endcase
    end
  end

endmodule