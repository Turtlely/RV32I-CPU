/*
 * Module: counter
 * Purpose: Provide an 8-bit synchronous counter for environment testing.
 *
 * Inputs:
 *   clk - Clock signal.
 *   rst - Active-high synchronous reset.
 *
 * Outputs:
 *   count - Current 8-bit counter value.
 */

module counter (
    input            clk,
    input            rst,
    output reg [7:0] count
);

    always @(posedge clk) begin
        if (rst)
            count <= 8'b0;
        else
            count <= count + 1'b1;
    end

endmodule
