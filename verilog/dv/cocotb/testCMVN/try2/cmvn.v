module cmvn (
  input wire clk,
  input wire rst_n,
  input wire cmvn_en,
  input wire signed [31:0] input_data,
  output reg signed [31:0] output_data,
  output reg done
);

  // CMVN parameters
  reg signed [31:0] cmvn_mean [0:19];
  reg signed [31:0] cmvn_istd [0:19];

  // Counter for input data
  reg [10:0] counter;

  // Registers for intermediate calculations
  reg signed [63:0] diff;
  reg signed [63:0] prod;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset registers and outputs
      counter <= 11'b0;
      output_data <= 32'b0;
      done <= 1'b0;
    end else if (cmvn_en) begin
      if (counter < 1000) begin // 50 * 20 = 1000
        // Perform CMVN calculation
        diff <= $signed(input_data) - $signed(cmvn_mean[counter % 20]);
        prod <= diff * $signed(cmvn_istd[counter % 20]);
        output_data <= prod[55:24];
        counter <= counter + 1;
      end else begin
        // Set done signal when all input data is processed
        done <= 1'b1;
      end
    end else begin
      // Reset counter and done signal
      counter <= 11'b0;
      done <= 1'b0;
    end
  end

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

endmodule