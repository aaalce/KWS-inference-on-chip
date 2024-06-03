// SPDX-FileCopyrightText: 2024 Efabless Corporation and its Licensors, All Rights Reserved
// ========================================================================================
//
//  This software is protected by copyright and other intellectual property
//  rights. Therefore, reproduction, modification, translation, compilation, or
//  representation of this software in any manner other than expressly permitted
//  is strictly prohibited.
//
//  You may access and use this software, solely as provided, solely for the purpose of
//  integrating into semiconductor chip designs that you create as a part of the
//  of Efabless shuttles or Efabless managed production programs (and solely for use and
//  fabrication as a part of Efabless production purposes and for no other purpose.  You
//  may not modify or convey the software for any other purpose.
//
//  Disclaimer: EFABLESS AND ITS LICENSORS MAKE NO WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, WITH REGARD TO THIS MATERIAL, AND EXPRESSLY DISCLAIM
//  ANY AND ALL WARRANTIES OF ANY KIND INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//  PURPOSE. Efabless reserves the right to make changes without further
//  notice to the materials described herein. Neither Efabless nor any of its licensors
//  assume any liability arising out of the application or use of any product or
//  circuit described herein. Efabless's products described herein are
//  not authorized for use as components in life-support devices.
// SPDX-FileCopyrightText: 2024 Efabless Corporation and its Licensors, All Rights Reserved
// ========================================================================================
// ...

`ifdef USE_POWER_PINS
`define USE_PG_PIN
`endif

module SRAM_1024x32 (
  `ifdef USE_POWER_PINS
  inout VPWR,
  inout VGND,
  `endif

  // Wishbone Slave ports (WB MI A)
  input wb_clk_i,
  input wb_rst_i,
  input wbs_stb_i,
  input wbs_cyc_i,
  input wbs_we_i,
  input [3:0] wbs_sel_i,
  input [31:0] wbs_dat_i,
  input [31:0] wbs_adr_i,
  output reg wbs_ack_o,
  output reg [31:0] wbs_dat_o
);

  // SRAM memory array
  reg [31:0] mem [0:1023];

  // Initialize the memory with the contents of weights_init_0.mem
  initial begin
    $readmemh("weights_init_0.mem", mem);
  end

  // ram ports
  wire [31:0] DO;
  wire [31:0] DI;
  wire [31:0] BEN;
  wire [9:0] AD;
  wire EN;
  wire R_WB;
  wire CLKin;

  // Acknowledgment and data output signals
  reg ack_o;
  reg [31:0] dat_o;

  ram_controller #(.AW(10)) ram_controller(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(ack_o),
    .wbs_dat_o(dat_o),
    .DO(DO),
    .DI(DI),
    .BEN(BEN),
    .AD(AD),
    .EN(EN),
    .R_WB(R_WB),
    .CLKin(CLKin)
  );

  // Assign the read data from the memory array
  assign DO = mem[AD];

  // Generate read acknowledgment signal
  // In the always block, assign the values directly
  always @(posedge wb_clk_i) begin
      if (wbs_stb_i && wbs_cyc_i && !wbs_we_i) begin
          wbs_ack_o <= 1'b1;
          wbs_dat_o <= DO;
      end else begin
          wbs_ack_o <= 1'b0;
          wbs_dat_o <= 32'h00000000;
      end
  end

  EF_SRAM_1024x32_wrapper SRAM_0 (
    `ifdef USE_POWER_PINS
    .vgnd(VGND),
    .vnb(VGND),
    .vpb(VPWR),
    .vpwra(VPWR),
    .vpwrm(VPWR),
    .vpwrp(VPWR),
    `endif
    .vpwrac(1'b1),
    .vpwrpc(1'b1),
    // access ports
    .DO(DO),
    .DI(DI),
    .BEN(BEN),
    .AD(AD),
    .EN(EN),
    .R_WB(R_WB),
    .CLKin(CLKin),
    // scan ports
    .TM(1'b0),
    .SM(1'b0),
    .ScanInCC(1'b0),
    .ScanInDL(1'b0),
    .ScanInDR(1'b0),
    .ScanOutCC(),
    .WLBI(1'b0),
    .WLOFF(1'b0)
  );

endmodule