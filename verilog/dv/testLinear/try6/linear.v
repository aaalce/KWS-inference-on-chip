module linear (
  input wire clk,
  input wire rst_n,
  input wire linear_en,
  input wire [31:0] input_data,
  input wire [9:0] input_addr,
  output reg [31:0] output_data,
  output reg [9:0] output_addr,
  output reg output_valid
);

  // Instantiate the SRAM module
  wire [31:0] DO;
  wire [31:0] DI;
  wire [3:0] BEN;
  wire [9:0] AD;
  wire EN;
  wire R_WB;
  wire CLKin;

  // Wishbone Slave ports (WB MI A)
  wire wb_clk_i;
  wire wb_rst_i;
  reg wbs_stb_i;
  reg wbs_cyc_i;
  reg wbs_we_i;
  reg [3:0] wbs_sel_i;
  reg [31:0] wbs_adr_i;
  wire [31:0] wbs_dat_i;
  wire wbs_ack_o;
  wire [31:0] wbs_dat_o;

  // Instantiate the SRAM_1024x32 module
  SRAM_1024x32 SRAM_inst (
    `ifdef USE_POWER_PINS
    .VPWR(VPWR),
    .VGND(VGND),
    `endif
    .wb_clk_i(clk),
    .wb_rst_i(rst_n),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o)
  );

  // Intermediate registers
  reg signed [63:0] mult_result;
  reg signed [31:0] acc_result;

  // Counter for input data
  reg [4:0] input_counter;
  reg [9:0] cycle_counter;

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
        // Calculate the starting address of the linear weights
        wbs_adr_i <= {22'h000000, input_addr[4:0] * 5'd20};
  
        // Read linear weight from SRAM
        wbs_stb_i <= 1'b1;
        wbs_cyc_i <= 1'b1;
        wbs_we_i <= 1'b0;
        wbs_sel_i <= 4'b1111;
  
        // Wait for SRAM read acknowledgment
        if (wbs_ack_o) begin
          mult_result <= $signed(input_data) * $signed(wbs_dat_o);
          $display("Debug: MULTIPLY - Input data: %d, Weight: %d, Multiplication result: %d", input_data, wbs_dat_o, mult_result);
          wbs_stb_i <= 1'b0;
          wbs_cyc_i <= 1'b0;
          next_state = ACCUMULATE;
        end else begin
          $display("Debug: MULTIPLY - Waiting for SRAM read acknowledgment");
          next_state = MULTIPLY;
        end
      end
      ACCUMULATE: begin
        if (input_counter < 19) begin
          next_state = MULTIPLY;
        end else begin
          next_state = OUTPUT;
        end
      end
      OUTPUT: begin
        if (cycle_counter >= 20) begin
          next_state = IDLE;
        end else begin
          next_state = OUTPUT;
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
      output_addr <= 10'h000;
      output_valid <= 1'b0;
      input_counter <= 5'h00;
      cycle_counter <= 10'h000;
      acc_result <= 32'h00000000;
      wbs_stb_i <= 1'b0;
      wbs_cyc_i <= 1'b0;
      wbs_we_i <= 1'b0;
      wbs_sel_i <= 4'b0000;
      wbs_adr_i <= 32'h00000000;
    end else begin
      case (current_state)
        IDLE: begin
          output_data <= 32'h00000000;
          output_addr <= 10'h000;
          output_valid <= 1'b0;
          input_counter <= 5'h00;
          cycle_counter <= 10'h000;
          acc_result <= 32'h00000000;
          wbs_stb_i <= 1'b0;
          wbs_cyc_i <= 1'b0;
          wbs_we_i <= 1'b0;
          wbs_sel_i <= 4'b0000;
          wbs_adr_i <= 32'h00000000;
        end
        MULTIPLY: begin
          // Read linear weight from SRAM
          wbs_stb_i <= 1'b1;
          wbs_cyc_i <= 1'b1;
          wbs_we_i <= 1'b0;
          wbs_sel_i <= 4'b1111;
          wbs_adr_i <= {22'h000000, input_addr[4:0], input_counter}; // Use input_addr[4:0] as the column index and input_counter as the offset
          
          // Wait for SRAM read acknowledgment
          if (wbs_ack_o) begin
            mult_result <= $signed(input_data) * $signed(wbs_dat_o);
            $display("Debug: MULTIPLY - Input data: %d, Weight: %d, Multiplication result: %d", input_data, wbs_dat_o, mult_result);
            wbs_stb_i <= 1'b0;
            wbs_cyc_i <= 1'b0;
          end else begin
            $display("Debug: MULTIPLY - Waiting for SRAM read acknowledgment");
          end
        end
        ACCUMULATE: begin
          acc_result <= $signed(acc_result) + $signed(mult_result[31:0]); // Truncate to 1.7.24 format
          input_counter <= input_counter + 1;
          $display("Debug: ACCUMULATE - Accumulation result: %d", acc_result);
        end
        OUTPUT: begin
          cycle_counter <= cycle_counter + 1;
          case (cycle_counter)
            20: begin
              output_data <= acc_result;
              output_addr <= 10'h000;
              output_valid <= 1'b1;
              $display("Debug: OUTPUT - Output data: %d, Output address: %d", output_data, output_addr);
            end
            40: begin
              output_data <= acc_result;
              output_addr <= 10'h001;
              output_valid <= 1'b1;
              $display("Debug: OUTPUT - Output data: %d, Output address: %d", output_data, output_addr);
            end
            60: begin
              output_data <= acc_result;
              output_addr <= 10'h002;
              output_valid <= 1'b1;
              $display("Debug: OUTPUT - Output data: %d, Output address: %d", output_data, output_addr);
            end
            // Add more cases for subsequent addresses
            default: begin
              output_valid <= 1'b0;
            end
          endcase
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