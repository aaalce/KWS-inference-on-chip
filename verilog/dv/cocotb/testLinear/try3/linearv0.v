module linear (
  input wire clk,
  input wire rst_n,
  input wire linear_en,
  input wire cmvn_input_valid,
  input wire [1:0] linear_mode, // 00: CMVN input, 01: ReLU input
  input wire signed [31:0] cmvn_input_data,
  input wire [4:0] cmvn_input_addr,
  input wire signed [31:0] relu_input_data,
  input wire [4:0] relu_input_addr,
  output reg signed [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid
);

  // Debug signals
  reg signed [31:0] debug_input_data;
  reg signed [31:0] debug_multiply_result;
  reg signed [31:0] debug_accumulate_result;

  // Register file to store Linear weights (1.7.24 format)
  reg signed [31:0] linear_weights [0:399];

  // Intermediate registers (1.7.24 format)
  reg signed [31:0] input_data;
  reg signed [63:0] multiply_result;
  reg signed [31:0] accumulate_result;

  // Counter for input data
  reg [5:0] input_counter;

  // State machine states
  localparam IDLE = 2'b00;
  localparam READ_INPUT = 2'b01;
  localparam MULTIPLY_ACCUMULATE = 2'b10;
  localparam OUTPUT_RESULT = 2'b11;

  reg [1:0] current_state;
  reg [1:0] next_state;
  
  // Debug file handle
  integer debug_file;

  // Initialize Linear weights (example values in 1.7.24 format)
  initial begin
    linear_weights[0] = $signed(32'h01800000); // 1.5
    linear_weights[1] = $signed(32'h00C00000); // 0.75
    // ... Initialize other weights
    linear_weights[399] = $signed(32'h00400000); // 0.25
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
    case (current_state)
      IDLE: begin
        if (linear_en) begin
          next_state = READ_INPUT;
        end else begin
          next_state = IDLE;
        end
      end
      READ_INPUT: begin
        if (cmvn_input_valid || current_state == MULTIPLY_ACCUMULATE) begin
          next_state = MULTIPLY_ACCUMULATE;
        end else begin
          next_state = READ_INPUT;
        end
      end
      MULTIPLY_ACCUMULATE: begin
        if (input_counter < 400) begin
          next_state = READ_INPUT;
        end else begin
          next_state = OUTPUT_RESULT;
        end
      end
      OUTPUT_RESULT: begin
        next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  // Input selection logic
  always @(*) begin
    case (linear_mode)
      2'b00: begin // CMVN input
        input_data = cmvn_input_data;
      end
      2'b01: begin // ReLU input
        input_data = relu_input_data;
      end
      default: begin
        input_data = 32'h00000000;
      end
    endcase
  end

  // Multiply-accumulate logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      multiply_result <= 64'h0000000000000000;
      accumulate_result <= 32'h00000000;
    end else if (current_state == MULTIPLY_ACCUMULATE) begin
      multiply_result <= $signed(input_data) * $signed(linear_weights[input_counter]);
      accumulate_result <= $signed(accumulate_result) + $signed(multiply_result[55:24]); // Truncate to 1.7.24 format
      debug_input_data <= input_data; // Debug: store input_data
      debug_multiply_result <= multiply_result[55:24]; // Debug: store multiply_result
      debug_accumulate_result <= accumulate_result; // Debug: store accumulate_result
    end else if (current_state == READ_INPUT) begin
      if (input_counter == 399) begin
        accumulate_result <= 32'h00000000;
        input_counter <= 0;
      end
    end
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
        READ_INPUT: begin
          input_counter <= input_counter + 1;
        end
        MULTIPLY_ACCUMULATE: begin
          // Do nothing
        end
        OUTPUT_RESULT: begin
          output_data <= accumulate_result;
          output_addr <= input_counter[4:0];
          output_valid <= 1'b1;
        end
        default: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
        end
      endcase
      if (current_state == READ_INPUT) begin
        input_counter <= input_counter + 1;
      end
    end
  end   

  // Debug module
  always @(posedge clk) begin
    if (current_state == MULTIPLY_ACCUMULATE) begin
      $fwrite(debug_file, "Debug: Multiply-Accumulate\n");
      $fwrite(debug_file, "  input_data = %d\n", debug_input_data);
      $fwrite(debug_file, "  linear_weights[%d] = %d\n", input_counter, linear_weights[input_counter]);
      $fwrite(debug_file, "  multiply_result = %d\n", debug_multiply_result);
      $fwrite(debug_file, "  accumulate_result = %d\n", debug_accumulate_result);
    end
  end

  // Open debug file
  initial begin
    debug_file = $fopen("debug_log.txt", "w");
  end

  // Close debug file
  final begin
    $fclose(debug_file);
  end

endmodule