`default_nettype none

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,    // User area 1 1.8V supply
    inout vssd1,    // User area 1 digital ground
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
    output reg [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output reg [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [BITS-1:0] io_in,
    output reg [BITS-1:0] io_out,
    output reg [BITS-1:0] io_oeb,

    // IRQ
    output reg [2:0] irq
);

    wire clk;
    wire rst;

    // KWS FSM signals
    reg start;
    reg [3:0] opcode;
    wire cmvn_en;
    wire linear_en;
    wire relu_en;
    wire padding_en;
    wire cnn_en;
    wire batch_norm_en;
    wire sigmoid_en;
    wire systolic_en;
    wire [1:0] systolic_op;
    wire done;

    // CMVN signals
    wire [31:0] cmvn_input_data;
    wire [4:0] cmvn_input_addr;
    wire [31:0] cmvn_output_data;
    wire [4:0] cmvn_output_addr;
    wire cmvn_output_valid;

    // Linear signals
    wire [31:0] linear_input_data;
    wire [9:0] linear_input_addr;
    wire [31:0] linear_output_data;
    wire [9:0] linear_output_addr;
    wire linear_output_valid;
    wire linear_input_req;

    // Weights signals
    wire [31:0] weights_data_out;

    // ReLU signals
    wire [31:0] relu_input_data;
    wire [4:0] relu_input_addr;
    wire [31:0] relu_output_data;
    wire [4:0] relu_output_addr;
    wire relu_output_valid;

    // Instantiate the KWS FSM module
    kws_fsm kws_fsm_inst (
        .clk(clk),
        .rst_n(rst),
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

    // Instantiate the CMVN module
    cmvn cmvn_inst (
        .clk(clk),
        .rst_n(rst),
        .cmvn_en(cmvn_en),
        .input_data(cmvn_input_data),
        .input_addr(cmvn_input_addr),
        .output_data(cmvn_output_data),
        .output_addr(cmvn_output_addr),
        .output_valid(cmvn_output_valid)
    );

    // Instantiate the Weights Register File module
    weights_reg_file weights_inst (
        .clk(clk),
        .rst_n(rst),
        .row_addr(linear_input_addr[9:5]),
        .col_addr(linear_input_addr[4:0]),
        .data_out(weights_data_out)
    );

    // Instantiate the Linear module
    linear linear_inst (
        .clk(clk),
        .rst_n(rst),
        .linear_en(linear_en),
        .input_data(linear_input_data),
        .input_addr(linear_input_addr),
        .output_data(linear_output_data),
        .output_addr(linear_output_addr),
        .output_valid(linear_output_valid),
        .input_req(linear_input_req)
    );

    // Instantiate the ReLU module
    relu relu_inst (
        .clk(clk),
        .rst_n(rst),
        .relu_en(relu_en),
        .input_data(relu_input_data),
        .input_addr(relu_input_addr),
        .output_data(relu_output_data),
        .output_addr(relu_output_addr),
        .output_valid(relu_output_valid)
    );

    // Clock and reset assignments
    assign clk = wb_clk_i;
    assign rst = wb_rst_i;

    // Input/output assignments
    assign cmvn_input_data = io_in[31:0];
    assign cmvn_input_addr = io_in[36:32];
    assign linear_input_data = cmvn_output_valid ? cmvn_output_data : relu_output_data;
    assign linear_input_addr = cmvn_output_valid ? {5'b0, cmvn_output_addr} : {5'b0, relu_output_addr};
    assign relu_input_data = linear_output_valid ? linear_output_data : 32'b0;
    assign relu_input_addr = linear_output_valid ? linear_output_addr[4:0] : 5'b0;

    // Output assignments
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            io_out <= {BITS{1'b0}};
            io_oeb <= {BITS{1'b1}}; // Set io_oeb to high-impedance state
            wbs_ack_o <= 1'b0;
            wbs_dat_o <= 32'b0;
            la_data_out <= 128'b0;
            irq <= 3'b0;
        end else begin
            io_out <= {done, {(BITS-1){1'b0}}}; // Assign 'done' to LSB, others to 0
            io_oeb <= {(BITS){1'b0}}; // Enable all output bits
            wbs_ack_o <= wbs_cyc_i & wbs_stb_i; // Generate Wishbone acknowledgment
            wbs_dat_o <= 32'b0; // Assign a default value or provide the appropriate data
            la_data_out <= 128'b0; // Assign a default value or provide the appropriate data
            irq <= 3'b0; // Assign appropriate interrupt request values if needed
        end
    end

    // Control signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start <= 1'b0;
            opcode <= 4'b0;
        end else begin
            // Implement the logic to control the start signal and opcode based on your requirements
            // For example, you can trigger the start signal and set the opcode when certain conditions are met
            // start <= some_condition ? 1'b1 : 1'b0;
            // opcode <= some_condition ? 4'bXXXX : 4'b0;
        end
    end

endmodule

`default_nettype wire