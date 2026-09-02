/*
 * Module: ex_mem_reg
 * Purpose: Hold execution results and control signals between EX and MEM.
 *
 * Inputs:
 *   clk, rst, stall, flush - Pipeline-register sequencing controls.
 *   alu_result_in, rs2_data_in - ALU result and store data from EX.
 *   pc_plus_4_in, imm_in - Values retained for write-back selection.
 *   rd_in, funct3_in - Destination register and memory operation field.
 *   reg_write_in, mem_read_in, mem_write_in - Architectural side effects.
 *   wb_sel_in - Write-back source selection.
 *
 * Outputs:
 *   Corresponding *_out signals presented to the MEM stage.
 */

module ex_mem_reg (
    input clk,
    input rst,
    input stall,
    input flush,

    input  [31:0] alu_result_in,
    input  [31:0] rs2_data_in,
    input  [31:0] pc_plus_4_in,
    input  [31:0] imm_in,
    input  [4:0]  rd_in,
    input  [2:0]  funct3_in,

    input reg_write_in,
    input mem_read_in,
    input mem_write_in,
    input [1:0] wb_sel_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rd_out,
    output reg [2:0]  funct3_out,

    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg [1:0] wb_sel_out
);

always @ (posedge clk) begin
    if (rst || flush) begin
        alu_result_out <= 32'b0;
        rs2_data_out   <= 32'b0;
        pc_plus_4_out  <= 32'b0;
        imm_out        <= 32'b0;
        rd_out         <= 5'b0;
        funct3_out     <= 3'b0;

        reg_write_out  <= 1'b0;
        mem_read_out   <= 1'b0;
        mem_write_out  <= 1'b0;
        wb_sel_out     <= 2'b0;
    end
    else if (stall) begin
        // do nothing — hold current values
    end
    else begin
        alu_result_out <= alu_result_in;
        rs2_data_out   <= rs2_data_in;
        pc_plus_4_out  <= pc_plus_4_in;
        imm_out        <= imm_in;
        rd_out         <= rd_in;
        funct3_out     <= funct3_in;

        reg_write_out  <= reg_write_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        wb_sel_out     <= wb_sel_in;
    end
end

endmodule
