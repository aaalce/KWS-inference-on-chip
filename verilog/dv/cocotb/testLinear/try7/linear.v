`timescale 1ns / 1ps
module linear (
  input wire clk,
  input wire rst_n,
  input wire linear_en,
  input wire [31:0] input_data,
  input wire [9:0] input_addr,
  output reg [31:0] output_data,
  output reg [9:0] output_addr,
  output reg output_valid,
  output reg input_req
);

  // Instantiate the weights_reg_file module
  wire [31:0] weight_data;
  weights_reg_file weights_inst (
    .clk(clk),
    .rst_n(rst_n),
    .row_addr(input_addr[9:5]),
    .col_addr(input_addr[4:0]),
    .data_out(weight_data)
  );

  // Intermediate registers
  reg signed [63:0] mult_result;
  reg signed [63:0] acc_result;
  reg [31:0] input_data_reg;
  reg [31:0] weight_data_reg;

  // Counter for input data
  reg [4:0] input_counter;

  // State machine states
  localparam IDLE = 2'b00;
  localparam MULTIPLY = 2'b01;
  localparam ACCUMULATE = 2'b10;
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
    case (current_state)
      IDLE: begin
        if (linear_en) begin
          next_state = MULTIPLY;
        end else begin
          next_state = IDLE;
        end
      end
      MULTIPLY: begin
        mult_result = $signed(input_data_reg) * $signed(weight_data_reg);
        next_state = ACCUMULATE;
      end
      ACCUMULATE: begin
        if (input_counter < 19) begin
          input_req = 1'b1; // Assert input_req to request new input data
          next_state = MULTIPLY;
        end else begin
          input_req = 1'b0; // Deassert input_req when done with accumulation
          next_state = OUTPUT;
        end
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
      output_addr <= 10'h000;
      output_valid <= 1'b0;
      input_counter <= 5'h00;
      acc_result <= 64'h0000000000000000;
      input_data_reg <= 32'h00000000;
      weight_data_reg <= 32'h00000000;
    end else begin
      case (current_state)
        IDLE: begin
          output_data <= 32'h00000000;
          output_addr <= 10'h000;
          output_valid <= 1'b0;
          input_counter <= 5'h00;
          acc_result <= 64'h0000000000000000;
          input_data_reg <= input_data;
          weight_data_reg <= weight_data;
        end
        MULTIPLY: begin
          // No action needed, multiplication is done in the next state logic
        end
        ACCUMULATE: begin
          acc_result <= acc_result + mult_result[55:24]; // Truncate to 1.7.24 format
          input_counter <= input_counter + 1;
          input_data_reg <= input_data;
          weight_data_reg <= weight_data;
          $display("Debug: ACCUMULATE - Accumulation result: %d", acc_result + mult_result[55:24]);
        end
        OUTPUT: begin
          output_data <= acc_result[55:24]; // Truncate to 32 bits
          output_addr <= input_addr;
          output_valid <= 1'b1;
          $display("Debug: OUTPUT - Output data: %d", output_data);
        end
        default: begin
          output_data <= 32'h00000000;
          output_addr <= 10'h000;
          output_valid <= 1'b0;
        end
      endcase
    end
  end

endmodule