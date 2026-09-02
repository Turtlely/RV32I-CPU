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
    // ensures jump_target is even
    wire [31:0] jump_target = alu_result & ~32'b1;

    /*
    If we are going to jump, then next_pc = jump_target
    If we are going to take a branch, then next_pc = branch_target
    otherwise, next_pc = pc+4 (increment to next instruction in sequence like normal)
    */
    assign next_pc = jump ? jump_target : 
                        take_branch ? branch_target :
                            pc_plus_4;

endmodule

