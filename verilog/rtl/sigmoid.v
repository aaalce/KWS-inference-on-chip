`timescale 1ns / 1ps
module sigmoid (
  input wire clk,
  input wire rst_n,
  input wire sigmoid_en,
  input wire [31:0] input_data,
  input wire [4:0] input_addr,
  output reg [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid
);

  // Intermediate registers (1.7.24 format)
  reg signed [31:0] exp_input;
  reg signed [63:0] exp_result;
  reg signed [31:0] sigmoid_result;

  // Constants (1.7.24 format)
  localparam ONE = 32'h01000000;
  localparam NEG_ONE = 32'hFF000000;

  // State machine states
  localparam IDLE = 2'b00;
  localparam CALCULATE_EXP = 2'b01;
  localparam CALCULATE_SIGMOID = 2'b10;
  localparam OUTPUT = 2'b11;

  reg [1:0] current_state;
  reg [1:0] next_state;

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
    exp_input = 32'h00000000; // Default value
    exp_result = 64'h0000000000000000; // Default value
    sigmoid_result = 32'h00000000; // Default value
    
    case (current_state)
      IDLE: begin
        if (sigmoid_en) begin
          next_state = CALCULATE_EXP;
        end else begin
          next_state = IDLE;
        end
      end
      CALCULATE_EXP: begin
        next_state = CALCULATE_SIGMOID;
        exp_input = -input_data; // Negate input for exp(-x)
        exp_result = ONE; // Initialize exp_result to 1
        
        // Perform exp(x) approximation using Taylor series
        exp_result = exp_result + (exp_input >> 0);
        exp_result = exp_result + ((exp_input * exp_input) >> 25);
        exp_result = exp_result + (((exp_input * exp_input * exp_input) >> 50) + 32'h00000001);
      end
      CALCULATE_SIGMOID: begin
        next_state = OUTPUT;
        sigmoid_result = ONE / (ONE + exp_result[55:24]); // 1 / (1 + exp(-x))
      end
      OUTPUT: begin
        next_state = IDLE;
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
    end else begin
      case (current_state)
        IDLE: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
        end
        CALCULATE_EXP: begin
          // Do nothing
        end
        CALCULATE_SIGMOID: begin
          // Do nothing
        end
        OUTPUT: begin
          output_data <= sigmoid_result;
          output_addr <= input_addr;
          output_valid <= 1'b1;
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