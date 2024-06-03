module relut32int (
    input clk,
    input rst,
    input signed [31:0] x [0:2][0:3],
    output reg signed [31:0] y [0:2][0:3]
);

genvar i, j;

generate
    for (i = 0; i < 3; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    y[i][j] <= 32'b0;
                end else begin
                    y[i][j] <= (x[i][j][31] == 1'b0) ? x[i][j] : 32'b0;
                end
            end
        end
    end
endgenerate

endmodule

