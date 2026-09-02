/*
 * Module: forward_unit
 * Purpose: Select EX/MEM or MEM/WB forwarding for both EX-stage operands.
 *
 * Inputs:
 *   id_ex_rs1, id_ex_rs2 - Source registers needed by the EX stage.
 *   ex_mem_rd, ex_mem_reg_write - MEM-stage destination and write enable.
 *   mem_wb_rd, mem_wb_reg_write - WB-stage destination and write enable.
 *
 * Outputs:
 *   fwd_a_sel - Forwarding selection for source operand A.
 *   fwd_b_sel - Forwarding selection for source operand B.
 */

module forward_unit (
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,

    input [4:0] ex_mem_rd,
    input ex_mem_reg_write,

    input [4:0] mem_wb_rd,
    input mem_wb_reg_write,

    input uses_rs1,
    input uses_rs2,

    output reg [1:0] fwd_a_sel,
    output reg [1:0] fwd_b_sel
);

always @ (*) begin
    if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1) && uses_rs1)
        fwd_a_sel = 2'b10;
    else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1) && uses_rs1)
        fwd_a_sel = 2'b01;
    else
        fwd_a_sel = 2'b00;
    
    // Operand B (rs2)
    if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2) && uses_rs2)
        fwd_b_sel = 2'b10;
    else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2) && uses_rs2)
        fwd_b_sel = 2'b01;
    else
        fwd_b_sel = 2'b00;
end
endmodule
