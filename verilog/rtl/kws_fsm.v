module kws_fsm (
  input wire clk,
  input wire rst_n,
  input wire start,
  input wire [3:0] opcode,
  output reg cmvn_en,
  output reg linear_en,
  output reg relu_en,
  output reg padding_en,
  output reg cnn_en,
  output reg batch_norm_en,
  output reg sigmoid_en,
  output reg systolic_en,
  output reg [1:0] systolic_op,
  output reg done
);

  // FSM states
  localparam IDLE = 3'b000;
  localparam CMVN = 3'b001;
  localparam LINEAR = 3'b010;
  localparam RELU = 3'b011;
  localparam PADDING = 3'b100;
  localparam CNN = 3'b101;
  localparam BATCH_NORM = 3'b110;
  localparam SIGMOID = 3'b111;

  reg [2:0] current_state;
  reg [2:0] next_state;

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
        if (start) begin
          case (opcode)
            4'b0011: next_state = CMVN;
            4'b0100: next_state = LINEAR;
            4'b0101: next_state = RELU;
            4'b0110: next_state = PADDING;
            4'b0111: next_state = CNN;
            4'b1000: next_state = BATCH_NORM;
            4'b1001: next_state = SIGMOID;
            default: next_state = IDLE;
          endcase
        end else begin
          next_state = IDLE;
        end
      end
      CMVN: next_state = RELU;
      LINEAR: next_state = RELU;
      RELU: begin
        if (opcode == 4'b0110) begin
          next_state = PADDING;
        end else begin
          next_state = CNN;
        end
      end
      PADDING: next_state = CNN;
      CNN: next_state = BATCH_NORM;
      BATCH_NORM: begin
        if (opcode == 4'b1001) begin
          next_state = SIGMOID;
        end else begin
          next_state = RELU;
        end
      end
      SIGMOID: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  // Output logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cmvn_en <= 1'b0;
      linear_en <= 1'b0;
      relu_en <= 1'b0;
      padding_en <= 1'b0;
      cnn_en <= 1'b0;
      batch_norm_en <= 1'b0;
      sigmoid_en <= 1'b0;
      systolic_en <= 1'b0;
      systolic_op <= 2'b00;
      done <= 1'b0;
    end else begin
      case (current_state)
        IDLE: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b0;
        end
        CMVN: begin
          cmvn_en <= 1'b1;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b0;
        end
        LINEAR: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b1;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b1;
          systolic_op <= 2'b00; // Matrix multiplication
          done <= 1'b0;
        end
        RELU: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b1;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b0;
        end
        PADDING: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b1;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b0;
        end
        CNN: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b1;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b1;
          systolic_op <= 2'b01; // Convolution
          done <= 1'b0;
        end
        BATCH_NORM: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b1;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b0;
        end
        SIGMOID: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b1;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b1;
        end
        default: begin
          cmvn_en <= 1'b0;
          linear_en <= 1'b0;
          relu_en <= 1'b0;
          padding_en <= 1'b0;
          cnn_en <= 1'b0;
          batch_norm_en <= 1'b0;
          sigmoid_en <= 1'b0;
          systolic_en <= 1'b0;
          systolic_op <= 2'b00;
          done <= 1'b0;
        end
      endcase
    end
  end

endmodule
