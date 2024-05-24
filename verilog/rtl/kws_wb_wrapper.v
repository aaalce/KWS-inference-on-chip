`default_nettype none

module kws_wb_wrapper (
`ifdef USE_POWER_PINS
    inout vccd1,   // User area 1 1.8V power
    inout vssd1,   // User area 1 digital ground
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
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // CMVN input from RISC-V core
    input [31:0] cmvn_input_data,
    input [4:0] cmvn_input_addr,
    input cmvn_input_valid
);

    wire valid;
    wire write_enable;
    wire read_enable;

    reg wbs_ack_o_reg;
    reg [31:0] wbs_dat_o_reg;

    assign valid = wbs_cyc_i && wbs_stb_i;
    assign write_enable = wbs_we_i && valid;
    assign read_enable = ~wbs_we_i && valid;
    assign wbs_dat_o = wbs_dat_o_reg;

    // Instantiate CMVN module
    wire cmvn_en;
    wire [31:0] cmvn_output_data;
    wire [4:0] cmvn_output_addr;
    wire cmvn_output_valid;

    cmvn cmvn_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .cmvn_en(cmvn_en),
        .input_data(cmvn_input_data),
        .input_addr(cmvn_input_addr),
        .output_valid(cmvn_output_valid),
        .output_data(cmvn_output_data),
        .output_addr(cmvn_output_addr)
    );

    // Instantiate KWS FSM module
    reg start;
    reg [3:0] opcode;
    wire linear_en;
    wire relu_en;
    wire padding_en;
    wire cnn_en;
    wire batch_norm_en;
    wire sigmoid_en;
    wire systolic_en;
    wire [1:0] systolic_op;
    wire done;

    kws_fsm kws_fsm_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .start(start),
        .opcode(opcode),
        .cmvn_en(cmvn_en),
        .linear_en(linear_en),
        .relu_en(relu_en),
        .padding_en(padding_en),
        .cnn_en(cnn_en),
        .batch_norm_en(batch_norm_en),
        .sigmoid_en(sigmoid_en),
        .systolic_en(systolic_en),
        .systolic_op(systolic_op),
        .done(done)
    );

    // Instantiate Linear module
    wire [31:0] linear_output_data;
    wire [4:0] linear_output_addr;
    wire linear_output_valid;

    linear linear_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .linear_en(linear_en),
        .input_data(cmvn_output_data),
        .input_addr(cmvn_output_addr),
        .output_data(linear_output_data),
        .output_addr(linear_output_addr),
        .output_valid(linear_output_valid)
    );

    // Instantiate SRAM module for Linear weights
//    wire [31:0] sram_rdata;

//    SRAM_1024x32 mprj (
//        `ifdef USE_POWER_PINS
//        .VPWR(vccd1),   // User area 1 1.8V power
//        .VGND(vssd1),   // User area 1 digital ground
//        `endif
//        .wb_clk_i(wb_clk_i),
//        .wb_rst_i(wb_rst_i),
//        .wbs_cyc_i(wbs_cyc_i),
//        .wbs_stb_i(wbs_stb_i),
//        .wbs_we_i(wbs_we_i),
//        .wbs_sel_i(wbs_sel_i),
//        .wbs_adr_i(wbs_adr_i),
//        .wbs_dat_i(wbs_dat_i),
//        .wbs_ack_o(wbs_ack_o),
//        .wbs_dat_o(sram_rdata)
//    );

    // Instantiate ReLU module
    wire [31:0] relu_output_data;
    wire [4:0] relu_output_addr;
    wire relu_output_valid;

    relu relu_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .relu_en(relu_en),
        .input_data(linear_output_data),
        .input_addr(linear_output_addr),
        .output_data(relu_output_data),
        .output_addr(relu_output_addr),
        .output_valid(relu_output_valid)
    );

    // Instantiate Batch Normalize module
    wire [31:0] batch_norm_output_data;
    wire [4:0] batch_norm_output_addr;
    wire batch_norm_output_valid;

    batch_normalize batch_norm_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .batch_norm_en(batch_norm_en),
        .input_data(relu_output_data),
        .input_addr(relu_output_addr),
        .output_data(batch_norm_output_data),
        .output_addr(batch_norm_output_addr),
        .output_valid(batch_norm_output_valid)
    );

    // Instantiate Dilated CNN module
    wire [19:0] cnn_input_data;
    wire cnn_input_valid;
    wire [19:0] cnn_output_data;
    wire cnn_output_valid;
    wire cnn_sram_en;
    wire [9:0] cnn_sram_addr;
    wire [31:0] cnn_sram_rdata;
    wire [31:0] cnn_sram_wdata;
    wire cnn_sram_we;

    DilatedCNN cnn_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .input_data(cnn_input_data),
        .input_valid(cnn_input_valid),
        .output_data(cnn_output_data),
        .output_valid(cnn_output_valid),
        .sram_en(cnn_sram_en),
        .sram_addr(cnn_sram_addr),
        .sram_rdata(cnn_sram_rdata),
        .sram_wdata(cnn_sram_wdata),
        .sram_we(cnn_sram_we)
    );

    // Instantiate Sigmoid module
    wire [31:0] sigmoid_output_data;
    wire [4:0] sigmoid_output_addr;
    wire sigmoid_output_valid;

    sigmoid sigmoid_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .sigmoid_en(sigmoid_en),
        .input_data(linear_output_data),
        .input_addr(linear_output_addr),
        .output_data(sigmoid_output_data),
        .output_addr(sigmoid_output_addr),
        .output_valid(sigmoid_output_valid)
    );

    // Wishbone write logic
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            // Reset logic
            start <= 1'b0;
            opcode <= 4'b0;
        end else if (write_enable) begin
            case (wbs_adr_i[7:2])
                6'h00: start <= wbs_dat_i[0];
                6'h01: opcode <= wbs_dat_i[3:0];
                // Add more write cases for other signals
                default: begin
                    start <= start;
                    opcode <= opcode;
                end
            endcase
        end
    end

    // Wishbone read logic
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            // Reset logic
            wbs_dat_o_reg <= 32'b0;
            wbs_ack_o_reg <= 1'b0;
        end else if (read_enable) begin
            case (wbs_adr_i[7:2])
                6'h10: wbs_dat_o_reg <= {31'b0, done};
                6'h11: wbs_dat_o_reg <= cmvn_output_data;
                6'h12: wbs_dat_o_reg <= {27'b0, cmvn_output_addr};
                6'h13: wbs_dat_o_reg <= linear_output_data;
                6'h14: wbs_dat_o_reg <= {27'b0, linear_output_addr};
                6'h15: wbs_dat_o_reg <= relu_output_data;
                6'h16: wbs_dat_o_reg <= {27'b0, relu_output_addr};
                6'h17: wbs_dat_o_reg <= batch_norm_output_data;
                6'h18: wbs_dat_o_reg <= {27'b0, batch_norm_output_addr};
                6'h19: wbs_dat_o_reg <= {12'b0, cnn_output_data};
                6'h1A: wbs_dat_o_reg <= {31'b0, cnn_output_valid};
                6'h1B: wbs_dat_o_reg <= sigmoid_output_data;
                6'h1C: wbs_dat_o_reg <= {27'b0, sigmoid_output_addr};
                // Add more read cases for other signals
                default: wbs_dat_o_reg <= 32'b0;
            endcase
            wbs_ack_o_reg <= 1'b1;
        end else begin
            wbs_ack_o_reg <= 1'b0;
        end
    end

    assign wbs_ack_o = wbs_ack_o_reg;

endmodule

`default_nettype none