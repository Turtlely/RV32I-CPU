/*
 * Module: branch_cond
 * Purpose: Evaluate the result of an RV32I conditional branch comparison.
 *
 * Inputs:
 *   branch      - Indicates that the current instruction is a branch.
 *   funct3      - Selects the branch comparison type.
 *   alu_zero    - Indicates that the ALU result is zero.
 *   alu_result0 - Least-significant bit of the ALU comparison result.
 *
 * Outputs:
 *   take_branch - Asserted when the current branch condition is satisfied.
 */

module branch_cond (
    input branch,
    input [2:0] funct3,
    input alu_zero,
    input alu_result0,

    output reg take_branch
);

    always @ (*) begin
        take_branch = 1'b0;

        if (branch) begin
            case (funct3)
                3'b000: take_branch = alu_zero; // BEQ
                3'b001: take_branch = !alu_zero; // BNE
                3'b100: take_branch = alu_result0; // BLT
                3'b101: take_branch = !alu_result0; // BGE
                3'b110: take_branch = alu_result0; // BLTU
                3'b111: take_branch = !alu_result0; // BGEU
                default: ;
            endcase
        end
    end

endmodule

