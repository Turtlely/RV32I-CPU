/*
 * Module: pc
 * Purpose: Store and synchronously update the 32-bit program counter.
 *
 * Inputs:
 *   clk     - Clock signal.
 *   rst     - Active-high synchronous reset.
 *   next_pc - Program-counter value to load on the next clock edge.
 *
 * Outputs:
 *   pc - Current program-counter value.
 */

module pc (
    input clk,
    input rst,
    input [31:0] next_pc,
    output reg [31:0] pc
);

always @ (posedge clk) begin
    if (rst)
        pc <= 32'b0;
    else
        pc <= next_pc;
end

endmodule

