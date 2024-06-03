module linear (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg done,
    input wire signed [31:0] input_data[49:0][19:0],
    input wire signed [31:0] weight[19:0][19:0],
    output reg signed [31:0] output_data[49:0][19:0]
);

    localparam IDLE = 2'b00;
    localparam MULTIPLY = 2'b01;
    localparam ACCUMULATE = 2'b10;

    reg [1:0] state;
    reg [5:0] row_counter;
    reg [4:0] col_counter;
    reg [5:0] mult_counter;
    
    // Extended to 64 bits to hold multiplication results
    reg signed [63:0] mult_result_ext;
    reg signed [63:0] acc_result_ext; 

    // State Transition Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if (start) 
                        state <= MULTIPLY;
                MULTIPLY: 
                    if (mult_counter == 18) // Transition when the counter reaches 18
                        state <= ACCUMULATE;
                ACCUMULATE:
                    if (col_counter == 19 && row_counter == 49)
                        state <= IDLE;
                    else
                        state <= MULTIPLY;
                default:
                    state <= IDLE;
            endcase
        end
    end

    // Counter and Calculation Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_counter <= 0;
            col_counter <= 0;
            mult_counter <= 0;
            done <= 0;
            mult_result_ext <= 64'd0;
            acc_result_ext <= 64'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                end
                MULTIPLY: begin
                    mult_result_ext <= input_data[row_counter][mult_counter] * weight[mult_counter][col_counter];
                    mult_counter <= mult_counter + 1; // Increment after the multiplication
                end
                ACCUMULATE: begin
                    acc_result_ext <= acc_result_ext + mult_result_ext;
                    if (mult_counter == 19) begin // Check after the last multiplication
                        // Right shift and saturation using conditional operator
                        output_data[row_counter][col_counter] <= $signed(
                            acc_result_ext > 32'h7FFFFFFF ? 32'h7FFFFFFF : 
                            acc_result_ext < -32'h80000000 ? -32'h80000000 : 
                            acc_result_ext >>> 24 
                        );
                        acc_result_ext <= 64'd0;

                        if (col_counter == 19) begin
                            col_counter <= 0;
                            row_counter <= row_counter + 1;
                            if (row_counter == 49) begin
                                done <= 1;
                            end
                        end else begin
                            col_counter <= col_counter + 1;
                        end
                        mult_counter <= 0;
                    end
                end
            endcase
        end
    end
endmodule