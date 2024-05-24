`timescale 1ns / 1ps
module relu (
  input wire clk,
  input wire rst_n,
  input wire relu_en,
  input wire [31:0] input_data,
  input wire [4:0] input_addr,
  output reg [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid
);

  // Intermediate registers (1.7.24 format)
  reg signed [31:0] relu_data;

  // State machine states
  localparam IDLE = 2'b00;
  localparam PROCESS = 2'b01;
  localparam OUTPUT = 2'b10;

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
    case (current_state)
      IDLE: begin
        if (relu_en) begin
          next_state = PROCESS;
        end else begin
          next_state = IDLE;
        end
      end
      PROCESS: next_state = OUTPUT;
      OUTPUT: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  // ReLU processing logic
  always @(*) begin
    case (current_state)
      IDLE: relu_data = 32'h00000000;
      PROCESS: begin
        if ($signed(input_data) > 0) begin
          relu_data = input_data;
        end else begin
          relu_data = 32'h00000000;
        end
      end
      OUTPUT: relu_data = relu_data;
      default: relu_data = 32'h00000000;
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
        PROCESS: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
        end
        OUTPUT: begin
          output_data <= relu_data;
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