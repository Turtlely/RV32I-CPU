/*
 * Module: pc_mux
 * Purpose: Select the next PC from a jump target, branch target, or PC + 4.
 *
 * Inputs:
 *   alu_result    - ALU-computed jump target.
 *   jump          - Selects the jump target.
 *   take_branch   - Selects the conditional-branch target when asserted.
 *   branch_target - PC-relative conditional-branch target.
 *   pc_plus_4     - Address of the next sequential instruction.
 *
 * Outputs:
 *   next_pc - Selected next program-counter value.
 */

module pc_mux (
    input [31:0] alu_result,
    input jump,
    input take_branch,
    input [31:0] branch_target,
    input [31:0] pc_plus_4,

    output [31:0] next_pc

);
    wire [31:0] jump_target = alu_result & ~32'b1;

    assign next_pc = jump ? jump_target : 
                        take_branch ? branch_target :
                            pc_plus_4;

endmodule

