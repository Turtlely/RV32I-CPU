/*
test file i made to check my dev environment
8-bit counter
*/

module counter (
    input clk,
    input rst,
    output reg [7:0] count
);

always @ (posedge clk) begin
    if (rst)
        count <= 8'b0;
    else
        count <= count + 1'b1;
end

endmodule
