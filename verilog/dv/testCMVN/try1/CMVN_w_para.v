// Register file for CMVN parameters
module cmvn_param_reg_file (
  input wire clk,
  input wire rst_n,
  output reg [31:0] cmvn_mean [19:0],
  output reg [31:0] cmvn_istd [19:0]
);

  // Initialize the register file with the provided values
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cmvn_mean[0]  <= 32'd241192656;
      cmvn_mean[1]  <= 32'd268649632;
      cmvn_mean[2]  <= 32'd276675136;
      cmvn_mean[3]  <= 32'd283695040;
      cmvn_mean[4]  <= 32'd281664064;
      cmvn_mean[5]  <= 32'd276283232;
      cmvn_mean[6]  <= 32'd273964992;
      cmvn_mean[7]  <= 32'd273919648;
      cmvn_mean[8]  <= 32'd279167136;
      cmvn_mean[9]  <= 32'd286963904;
      cmvn_mean[10] <= 32'd289749824;
      cmvn_mean[11] <= 32'd291469152;
      cmvn_mean[12] <= 32'd293973344;
      cmvn_mean[13] <= 32'd294496448;
      cmvn_mean[14] <= 32'd294786208;
      cmvn_mean[15] <= 32'd294155456;
      cmvn_mean[16] <= 32'd290103104;
      cmvn_mean[17] <= 32'd285622848;
      cmvn_mean[18] <= 32'd283800096;
      cmvn_mean[19] <= 32'd274944832;

      cmvn_istd[0]  <= 32'd2730620;
      cmvn_istd[1]  <= 32'd2558343;
      cmvn_istd[2]  <= 32'd2517505;
      cmvn_istd[3]  <= 32'd2456001;
      cmvn_istd[4]  <= 32'd2513680;
      cmvn_istd[5]  <= 32'd2642344;
      cmvn_istd[6]  <= 32'd2746480;
      cmvn_istd[7]  <= 32'd2793599;
      cmvn_istd[8]  <= 32'd2784816;
      cmvn_istd[9]  <= 32'd2747354;
      cmvn_istd[10] <= 32'd2753689;
      cmvn_istd[11] <= 32'd2760341;
      cmvn_istd[12] <= 32'd2757260;
      cmvn_istd[13] <= 32'd2790595;
      cmvn_istd[14] <= 32'd2817463;
      cmvn_istd[15] <= 32'd2839905;
      cmvn_istd[16] <= 32'd2892185;
      cmvn_istd[17] <= 32'd2942343;
      cmvn_istd[18] <= 32'd2964351;
      cmvn_istd[19] <= 32'd3003108;
    end
  end

endmodule


// Updated CMVN module with VCD dump and debug statements
module cmvn (
  input wire clk,
  input wire rst_n,
  input wire cmvn_en,
  input wire [31:0] input_data,
  input wire [4:0] feature_idx,
  output reg [31:0] output_data,
  output reg cmvn_done
);

  // Instantiate the CMVN parameter register file
  wire [31:0] cmvn_mean [19:0];
  wire [31:0] cmvn_istd [19:0];
  cmvn_param_reg_file cmvn_param_reg_file_inst (
    .clk(clk),
    .rst_n(rst_n),
    .cmvn_mean(cmvn_mean),
    .cmvn_istd(cmvn_istd)
  );

  // Internal registers
  reg [31:0] input_reg;
  reg [63:0] mult_result;

  // VCD dump
  initial begin
    $dumpfile("cmvn.vcd");
    $dumpvars(0, cmvn);
  end

  // Debug statements
  always @(posedge clk) begin
    if (cmvn_en) begin
      $display("CMVN: Input data = %d, Feature index = %d", input_data, feature_idx);
      $display("CMVN: Mean value = %d, Inverse standard deviation = %d", cmvn_mean[feature_idx], cmvn_istd[feature_idx]);
    end
  end

  // CMVN calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_reg <= 32'b0;
      output_data <= 32'b0;
      cmvn_done <= 1'b0;
    end else if (cmvn_en) begin
      input_reg <= input_data;
      mult_result <= ($signed(input_reg - cmvn_mean[feature_idx]) * $signed(cmvn_istd[feature_idx]));
      output_data <= mult_result[55:24]; // Right shift by 24 bits to get the 1.7.24 format result
      cmvn_done <= 1'b1;

      // Debug statements
      $display("CMVN: Input register = %d", input_reg);
      $display("CMVN: Multiplication result = %d", mult_result);
      $display("CMVN: Output data = %d", output_data);
    end else begin
      cmvn_done <= 1'b0;
    end
  end

endmodule