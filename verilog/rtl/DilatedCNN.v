`timescale 1ns / 1ps
module DilatedCNN (
  input wire clk,
  input wire rst_n,
  input wire [19:0] input_data,
  input wire input_valid,
  output reg [19:0] output_data,
  output reg output_valid,
  output reg sram_en,
  output reg [9:0] sram_addr,
  input wire [31:0] sram_rdata,
  output reg [31:0] sram_wdata,
  output reg sram_we
);

  // FSM states
  localparam IDLE = 3'b000;
  localparam LOAD_WEIGHTS = 3'b001;
  localparam COMPUTE = 3'b010;
  localparam STORE_RESULT = 3'b011;

  reg [2:0] current_state;
  reg [2:0] next_state;

  reg [999:0] input_buffer;
  reg [9:0] input_counter;
  reg [9:0] output_counter;
  reg [1919:0] weight_buffer [3:0];
  reg [1:0] network_counter;

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
        if (input_valid) begin
          next_state = LOAD_WEIGHTS;
        end else begin
          next_state = IDLE;
        end
      end
      LOAD_WEIGHTS: begin
        if (sram_addr == 10'd239) begin
          next_state = COMPUTE;
        end else begin
          next_state = LOAD_WEIGHTS;
        end
      end
      COMPUTE: begin
        if (output_counter == 10'd49) begin
          next_state = STORE_RESULT;
        end else begin
          next_state = COMPUTE;
        end
      end
      STORE_RESULT: begin
        next_state = IDLE;
      end
      default: next_state = IDLE;
    endcase
  end

  // Output logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sram_en <= 1'b0;
      sram_addr <= 10'd0;
      sram_wdata <= 32'd0;
      sram_we <= 1'b0;
      output_valid <= 1'b0;
      output_data <= 20'd0;
      input_counter <= 10'd0;
      output_counter <= 10'd0;
      network_counter <= 2'd0;
    end else begin
      case (current_state)
        IDLE: begin
          sram_en <= 1'b0;
          sram_addr <= 10'd0;
          sram_wdata <= 32'd0;
          sram_we <= 1'b0;
          output_valid <= 1'b0;
          output_data <= 20'd0;
          input_counter <= 10'd0;
          output_counter <= 10'd0;
          network_counter <= 2'd0;
        end
        LOAD_WEIGHTS: begin
          sram_en <= 1'b1;
          sram_addr <= sram_addr + 10'd1;
          sram_wdata <= 32'd0;
          sram_we <= 1'b0;
          output_valid <= 1'b0;
          weight_buffer[network_counter][sram_addr[5:0]] <= sram_rdata;
          if (sram_addr == 10'd239) begin
            network_counter <= network_counter + 2'd1;
          end
        end
        COMPUTE: begin
          sram_en <= 1'b0;
          sram_addr <= 10'd0;
          sram_wdata <= 32'd0;
          sram_we <= 1'b0;
          output_valid <= 1'b0;
          if (input_valid) begin
            input_buffer[input_counter] <= input_data;
            input_counter <= input_counter + 10'd1;
          end else begin
            input_counter <= 10'd0;
          end
          if (input_counter == 10'd49) begin
            // Perform dilated convolution
            output_data <= dilated_convolution(input_buffer, weight_buffer[network_counter]);
            output_counter <= output_counter + 10'd1;
          end
        end
        STORE_RESULT: begin
          sram_en <= 1'b0;
          sram_addr <= 10'd0;
          sram_wdata <= 32'd0;
          sram_we <= 1'b0;
          output_valid <= 1'b1;
          output_data <= output_data;
          output_counter <= 10'd0;
        end
      endcase
    end
  end

  function [19:0] dilated_convolution(
    input [999:0] input_buffer,
    input [1919:0] weight_buffer
  );
    integer i, j;
    reg [43:0] sum;
    begin
      sum = 44'd0;
      for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 20; j = j + 1) begin
          sum = sum + input_buffer[i*20+j] * weight_buffer[i*60+j];
        end
      end
      dilated_convolution = sum[43:24]; // 1.7.24 fixed-point format
    end
  endfunction

endmodule