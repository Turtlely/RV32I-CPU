/*
 * Module: alu_mux
 * Purpose: Select the two operands supplied to the RV32I ALU.
 *
 * Inputs:
 *   alu_a_src - Selects PC or rs1_data for ALU operand A.
 *   alu_b_src - Selects imm or rs2_data for ALU operand B.
 *   rs1_data  - Value read from source register rs1.
 *   pc        - Current program-counter value.
 *   rs2_data  - Value read from source register rs2.
 *   imm       - Decoded instruction immediate.
 *
 * Outputs:
 *   alu_a - Selected ALU operand A.
 *   alu_b - Selected ALU operand B.
 */

module alu_mux (
    input alu_a_src,
    input alu_b_src,
    input [31:0] rs1_data,
    input [31:0] pc,
    input [31:0] rs2_data,
    input [31:0] imm,

    output [31:0] alu_a,
    output [31:0] alu_b
);

assign alu_a = alu_a_src ? pc : rs1_data;
assign alu_b = alu_b_src ? imm : rs2_data;

endmodule
