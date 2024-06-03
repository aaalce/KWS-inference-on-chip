module linear (
  input wire clk,
  input wire rst_n,
  input wire linear_en,
  input wire [31:0] input_data,
  input wire [4:0] input_addr,
  output reg [31:0] output_data,
  output reg [4:0] output_addr,
  output reg output_valid,
  input wire systolic_en,
  input wire [1:0] systolic_op
);

  // SRAM instantiation for linear_subsampling weights
  reg [9:0] sram_address;
  wire [31:0] sram_data_out;

  EF_SRAM_1024x32_wrapper_with_init sram_inst (
    .clk(clk),
    .rst_n(rst_n),
    .address(sram_address),
    .data_out(sram_data_out)
  );

  // Register file for classifier weights
  reg signed [31:0] classifier_weight [0:19];

  initial begin
    // Initialize classifier weights in 1.7.24 fixed-point format
    classifier_weight[0] = $signed(32'hE8C00000);  // -0.4453125
    classifier_weight[1] = $signed(32'hAF800000);  // -1.59375
    classifier_weight[2] = $signed(32'hD1000000);  // -0.859375
    classifier_weight[3] = $signed(32'h82000000);  // 0.984375
    classifier_weight[4] = $signed(32'hA4000000);  // -1.78125
    classifier_weight[5] = $signed(32'hB6800000);  // -1.171875
    classifier_weight[6] = $signed(32'hD2000000);  // -0.828125
    classifier_weight[7] = $signed(32'h14000000);  // 0.15625
    classifier_weight[8] = $signed(32'h0E000000);  // 0.109375
    classifier_weight[9] = $signed(32'h44000000);  // 0.515625
    classifier_weight[10] = $signed(32'hCF000000);  // -0.359375
    classifier_weight[11] = $signed(32'h22000000);  // 0.265625
    classifier_weight[12] = $signed(32'h98000000);  // -1.390625
    classifier_weight[13] = $signed(32'hB8000000);  // -1.21875
    classifier_weight[14] = $signed(32'hB9000000);  // -1.234375
    classifier_weight[15] = $signed(32'h1D800000);  // 0.21875
    classifier_weight[16] = $signed(32'hCC000000);  // -0.75
    classifier_weight[17] = $signed(32'hAA000000);  // -1.546875
    classifier_weight[18] = $signed(32'hD8000000);  // -0.640625
    classifier_weight[19] = $signed(32'hB0000000);  // -1.15625
  end

  // Systolic array registers
  reg signed [31:0] systolic_input [0:49];
  reg signed [63:0] systolic_output [0:19];

  // Intermediate registers (1.7.24 format)
  reg signed [63:0] mult_result;

  // Counter for input data and output data
  reg [5:0] input_counter;
  reg [4:0] output_counter;

  // State machine states
  localparam IDLE = 2'b00;
  localparam SYSTOLIC_MULT = 2'b01;
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
        if (linear_en) begin
          next_state = SYSTOLIC_MULT;
        end else begin
          next_state = IDLE;
        end
      end
      SYSTOLIC_MULT: begin
        if (systolic_en && systolic_op == 2'b00) begin
          next_state = OUTPUT;
        end else begin
          next_state = SYSTOLIC_MULT;
        end
      end
      OUTPUT: begin
        if (output_counter < 20) begin
          next_state = OUTPUT;
        end else begin
          next_state = IDLE;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  // Systolic multiplication logic
  always @(posedge clk) begin
    if (current_state == SYSTOLIC_MULT && systolic_en && systolic_op == 2'b00) begin
      for (int i = 0; i < 50; i++) begin
        for (int j = 0; j < 20; j++) begin
          // Calculate SRAM address for weight access
          sram_address = i * 20 + j;

          // Perform the multiplication using the weight from SRAM
          mult_result = $signed(systolic_input[i]) * $signed(sram_data_out);
          systolic_output[j] <= systolic_output[j] + mult_result;
        end
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
      output_counter <= 5'h00;
    end else begin
      case (current_state)
        IDLE: begin
          output_data <= 32'h00000000;
          output_addr <= 5'h00;
          output_valid <= 1'b0;
          input_counter <= 6'h00;
          output_counter <= 5'h00;
          for (int j = 0; j < 20; j++) begin
            systolic_output[j] <= 64'h0000000000000000;
          end
        end
        SYSTOLIC_MULT: begin
          systolic_input[input_counter] <= input_data;
          input_counter <= input_counter + 1;
        end
        OUTPUT: begin
          output_data <= systolic_output[output_counter][55:24];
          output_addr <= output_counter;
          output_valid <= 1'b1;
          output_counter <= output_counter + 1;
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