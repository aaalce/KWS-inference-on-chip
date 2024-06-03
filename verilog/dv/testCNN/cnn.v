module cnn (
  input wire clk,
  input wire rst_n,
  input wire cnn_en,
  input wire [31:0] input_data,
  input wire [4:0] input_addr,
  output reg [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid
);

  // CNN parameters (1.7.24 format)
  reg signed [31:0] cnn_weight [0:24];
  reg signed [31:0] cnn_bias;

  // Intermediate registers (1.7.24 format)
  reg signed [31:0] conv_data;
  reg signed [63:0] accumulated_data;

  // Counter for input data
  reg [5:0] input_counter;

  // State machine states
  localparam IDLE = 2'b00;
  localparam CONV = 2'b01;
  localparam ACCUMULATE = 2'b10;
  localparam OUTPUT = 2'b11;

  reg [1:0] current_state;
  reg [1:0] next_state;

  // Initialize CNN parameters (example values in 1.7.24 format)
  initial begin
    cnn_weight[0] = $signed(32'h01800000); // 1.5
    cnn_weight[1] = $signed(32'h00400000); // 0.25
    // ...
    cnn_weight[24] = $signed(32'h00C00000); // 0.75
    cnn_bias = $signed(32'h00200000); // 0.125
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
        if (cnn_en) begin
          next_state = CONV;
        end else begin
          next_state = IDLE;
        end
      end
      CONV: begin
        next_state = ACCUMULATE;
        conv_data = $signed(input_data) * $signed(cnn_weight[input_addr]);
      end
      ACCUMULATE: begin
        if (input_counter < 25) begin
          next_state = CONV;
          accumulated_data = $signed(accumulated_data) + $signed(conv_data);
        end else begin
          next_state = OUTPUT;
          accumulated_data = $signed(accumulated_data) + $signed(cnn_bias);
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
      output_addr <= 5'h00;
      output_valid <= 1'b0;
      input_counter <= 6'h00;
      accumulated_data <= 64'h0000000000000000;
    end else begin
      case (current_state)
        IDLE: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
          input_counter <= 6'h00;
          accumulated_data <= 64'h0000000000000000;
        end
        CONV: begin
          // Do nothing, already processed in next state logic
        end
        ACCUMULATE: begin
          input_counter <= input_counter + 1;
        end
        OUTPUT: begin
          output_data <= accumulated_data[55:24]; // Extract the 32-bit result
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