module linear_tb;
  reg clk, rst_n, linear_en;
  reg [1:0] linear_mode;
  reg signed [31:0] cmvn_input_data;
  reg [4:0] cmvn_input_addr;
  wire signed [31:0] output_data;
  wire [4:0] output_addr;
  wire output_valid;

 // Instantiate the linear module
 linear dut (
   .clk(clk),
   .rst_n(rst_n),
   .linear_en(linear_en),
   .cmvn_input_valid(1'b1),
   .linear_mode(linear_mode),
   .cmvn_input_data(cmvn_input_data),
   .cmvn_input_addr(cmvn_input_addr),
   .relu_input_data(0),
   .relu_input_addr(5'b00000),  // Pass a 5-bit value
   .output_data(output_data),
   .output_addr(output_addr),
   .output_valid(output_valid)
 );

  // Clock generation
  always #5 clk = ~clk;  // 10ns clock period

  // Declare i as a reg variable before the initial block
  reg [9:0] i;

  initial begin
    // Initialize
    clk = 0;
    rst_n = 0;
    linear_en = 0;
    linear_mode = 2'b00;  // CMVN mode
    cmvn_input_data = 0;
    cmvn_input_addr = 0;

    // Dump waveforms
    $dumpfile("waveform.vcd");
    $dumpvars(0, linear_tb);

    // Reset
    #10 rst_n = 1;

    // Start linear operation after reset
    #10 linear_en = 1;
    #10 linear_en = 0;

    // Input data sequence
    for (i = 0; i < 400; i = i + 1) begin
      cmvn_input_data = $signed(i * 1000);
      cmvn_input_addr = i % 20;
      #10;
    end

    #100 $finish;  // End simulation after some time
  end
endmodule