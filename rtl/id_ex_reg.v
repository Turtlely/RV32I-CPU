/*
 * Module: id_ex_reg
 * Purpose: Hold decoded operands and control signals between ID and EX.
 *
 * Inputs:
 *   clk, rst, stall, flush - Pipeline-register sequencing controls.
 *   rs1_data_in, rs2_data_in - Register operands decoded in ID.
 *   pc_in, pc_plus_4_in, imm_in - PC and immediate values from ID.
 *   rd_in, rs1_in, rs2_in, funct3_in - Register and function fields.
 *   reg_write_in, mem_read_in, mem_write_in - Architectural side effects.
 *   branch_in, jump_in - Control-transfer indicators.
 *   alu_a_src_in, alu_b_src_in, alu_op_in - ALU control signals.
 *   wb_sel_in - Write-back source selection.
 *
 * Outputs:
 *   Corresponding *_out signals presented to the EX stage.
 */

module id_ex_reg (
    input clk,
    input rst,
    input stall,
    input flush,

    input [31:0] rs1_data_in,
    input [31:0] rs2_data_in,
    input [31:0] pc_in,
    input [31:0] pc_plus_4_in,
    input [31:0] imm_in,
    input [4:0]  rd_in,
    input [2:0]  funct3_in,

    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input branch_in,
    input jump_in,
    input alu_a_src_in,
    input alu_b_src_in,
    input [3:0] alu_op_in,
    input [1:0] wb_sel_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,

    input uses_rs1_in,
    input uses_rs2_in,


    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg jump_out,
    output reg alu_a_src_out,
    output reg alu_b_src_out,
    output reg [3:0] alu_op_out,
    output reg [1:0] wb_sel_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,

    output reg uses_rs1_out,
    output reg uses_rs2_out
);

always @ (posedge clk) begin
    if (rst || flush) begin
        // bubble: zero every control signal so this "instruction" does nothing
        rs1_data_out  <= 32'b0;
        rs2_data_out  <= 32'b0;
        pc_out        <= 32'b0;
        pc_plus_4_out <= 32'b0;
        imm_out       <= 32'b0;
        rd_out        <= 5'b0;
        funct3_out    <= 3'b0;

        reg_write_out <= 1'b0;
        mem_read_out  <= 1'b0;
        mem_write_out <= 1'b0;
        branch_out    <= 1'b0;
        jump_out      <= 1'b0;
        alu_a_src_out <= 1'b0;
        alu_b_src_out <= 1'b0;
        alu_op_out    <= 4'b0;
        wb_sel_out    <= 2'b0;
        rs1_out       <= 5'b0;
        rs2_out       <= 5'b0;

        uses_rs1_out <= 1'b0;
        uses_rs2_out <= 1'b0;

    end
    else if (stall) begin
        // do nothing — hold current values
    end
    else begin
        rs1_data_out  <= rs1_data_in;
        rs2_data_out  <= rs2_data_in;
        pc_out        <= pc_in;
        pc_plus_4_out <= pc_plus_4_in;
        imm_out       <= imm_in;
        rd_out        <= rd_in;
        funct3_out    <= funct3_in;

        reg_write_out <= reg_write_in;
        mem_read_out  <= mem_read_in;
        mem_write_out <= mem_write_in;
        branch_out    <= branch_in;
        jump_out      <= jump_in;
        alu_a_src_out <= alu_a_src_in;
        alu_b_src_out <= alu_b_src_in;
        alu_op_out    <= alu_op_in;
        wb_sel_out    <= wb_sel_in;
        rs1_out       <= rs1_in;
        rs2_out       <= rs2_in;

        uses_rs1_out <= uses_rs1_in;
        uses_rs2_out <= uses_rs2_in;
    end
end

endmodule
