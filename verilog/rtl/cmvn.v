`timescale 1ns / 1ps
module cmvn (
  input wire clk,
  input wire rst_n,
  input wire cmvn_en,
  input wire [31:0] input_data,
  input wire [4:0] input_addr,
  output reg [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid
);

  // Register file to store CMVN parameters (1.7.24 format)
  reg signed [31:0] cmvn_mean [0:19];
  reg signed [31:0] cmvn_istd [0:19];

  // Intermediate registers (1.7.24 format)
  reg signed [31:0] subtracted_data;
  reg signed [63:0] normalized_data;

  // Counter for input data
  reg [5:0] input_counter;

  // Debug signals
  reg [31:0] debug_subtracted_data;
  reg [63:0] debug_normalized_data;

  // State machine states
  localparam IDLE = 2'b00;
  localparam SUBTRACT_MEAN = 2'b01;
  localparam MULTIPLY_ISTD = 2'b10;
  localparam OUTPUT = 2'b11;

  reg [1:0] current_state;
  reg [1:0] next_state;

  // Initialize CMVN parameters
  initial begin
    cmvn_mean[0] = $signed(32'd241192656);
    cmvn_mean[1] = $signed(32'd268649632);
    cmvn_mean[2] = $signed(32'd276675136);
    cmvn_mean[3] = $signed(32'd283695040);
    cmvn_mean[4] = $signed(32'd281664064);
    cmvn_mean[5] = $signed(32'd276283232);
    cmvn_mean[6] = $signed(32'd273964992);
    cmvn_mean[7] = $signed(32'd273919648);
    cmvn_mean[8] = $signed(32'd279167136);
    cmvn_mean[9] = $signed(32'd286963904);
    cmvn_mean[10] = $signed(32'd289749824);
    cmvn_mean[11] = $signed(32'd291469152);
    cmvn_mean[12] = $signed(32'd293973344);
    cmvn_mean[13] = $signed(32'd294496448);
    cmvn_mean[14] = $signed(32'd294786208);
    cmvn_mean[15] = $signed(32'd294155456);
    cmvn_mean[16] = $signed(32'd290103104);
    cmvn_mean[17] = $signed(32'd285622848);
    cmvn_mean[18] = $signed(32'd283800096);
    cmvn_mean[19] = $signed(32'd274944832);

    cmvn_istd[0] = $signed(32'd2730620);
    cmvn_istd[1] = $signed(32'd2558343);
    cmvn_istd[2] = $signed(32'd2517505);
    cmvn_istd[3] = $signed(32'd2456001);
    cmvn_istd[4] = $signed(32'd2513680);
    cmvn_istd[5] = $signed(32'd2642344);
    cmvn_istd[6] = $signed(32'd2746480);
    cmvn_istd[7] = $signed(32'd2793599);
    cmvn_istd[8] = $signed(32'd2784816);
    cmvn_istd[9] = $signed(32'd2747354);
    cmvn_istd[10] = $signed(32'd2753689);
    cmvn_istd[11] = $signed(32'd2760341);
    cmvn_istd[12] = $signed(32'd2757260);
    cmvn_istd[13] = $signed(32'd2790595);
    cmvn_istd[14] = $signed(32'd2817463);
    cmvn_istd[15] = $signed(32'd2839905);
    cmvn_istd[16] = $signed(32'd2892185);
    cmvn_istd[17] = $signed(32'd2942343);
    cmvn_istd[18] = $signed(32'd2964351);
    cmvn_istd[19] = $signed(32'd3003108);
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
    debug_subtracted_data = 32'h00000000; // Default value
    debug_normalized_data = 64'h0000000000000000; // Default value

    case (current_state)
      IDLE: begin
        if (cmvn_en) begin
          next_state = SUBTRACT_MEAN;
        end else begin
          next_state = IDLE;
        end
      end
      SUBTRACT_MEAN: begin
        next_state = MULTIPLY_ISTD;
        subtracted_data = $signed(input_data) - $signed(cmvn_mean[input_addr]);
        debug_subtracted_data = subtracted_data;
      end
      MULTIPLY_ISTD: begin
        next_state = OUTPUT;
        normalized_data = $signed(subtracted_data) * $signed(cmvn_istd[input_addr]);
        normalized_data = normalized_data >>> 24;
        debug_normalized_data = normalized_data;
      end
      OUTPUT: begin
        if (input_counter < 19) begin
          next_state = SUBTRACT_MEAN;
        end else begin
          next_state = IDLE;
        end
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
        MULTIPLY_ISTD: begin
          // Do nothing
        end
        OUTPUT: begin
          output_data <= normalized_data[31:0];
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

  // Debug module
  always @(posedge clk) begin
    if (current_state == SUBTRACT_MEAN) begin
      $display("Debug: After SUBTRACT_MEAN");
      $display("  input_data = %d", input_data);
      $display("  cmvn_mean[%d] = %d", input_addr, cmvn_mean[input_addr]);
      $display("  subtracted_data = %d", debug_subtracted_data);
    end
    if (current_state == MULTIPLY_ISTD) begin
      $display("Debug: After MULTIPLY_ISTD");
      $display("  subtracted_data = %d", debug_subtracted_data);
      $display("  cmvn_istd[%d] = %d", input_addr, cmvn_istd[input_addr]);
      $display("  normalized_data = %d", debug_normalized_data);
    end
  end  

endmodule