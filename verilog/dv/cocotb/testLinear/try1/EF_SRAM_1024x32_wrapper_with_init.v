module EF_SRAM_1024x32_wrapper_with_init (
  input wire clk,
  input wire rst_n,
  input wire [9:0] address,
  output wire [31:0] data_out
);

  reg [31:0] memory [0:399];

  initial begin
    $readmemh("weights_init_0.mem", memory);
  end

  wire [31:0] sram_data_out;

  EF_SRAM_1024x32_wrapper sram_inst (
    .DO(sram_data_out),
    .DI(32'b0),
    .BEN(32'hFFFFFFFF),
    .AD(address),
    .EN(1'b1),
    .R_WB(1'b1),
    .CLKin(clk),
    .TM(1'b0),
    .SM(1'b0),
    .ScanInCC(1'b0),
    .ScanInDL(1'b0),
    .ScanInDR(1'b0),
    .WLBI(1'b0),
    .WLOFF(1'b0),
    .vpwrac(1'b1),
    .vpwrpc(1'b1)
  );

  assign data_out = sram_data_out;

endmodule