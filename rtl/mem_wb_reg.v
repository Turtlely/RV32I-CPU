/*
 * Module: mem_wb_reg
 * Purpose: Hold memory-stage results and controls between MEM and WB.
 *
 * Inputs:
 *   clk, rst, stall - Pipeline-register sequencing controls.
 *   alu_result_in, mem_read_data_in - Candidate ALU and memory results.
 *   pc_plus_4_in, imm_in - Additional write-back candidates.
 *   rd_in, reg_write_in - Destination register and write enable.
 *   wb_sel_in - Write-back source selection.
 *
 * Outputs:
 *   Corresponding *_out signals presented to the WB stage.
 */

module mem_wb_reg (
    input clk,
    input rst,
    input stall,

    input  [31:0] alu_result_in,
    input  [31:0] mem_read_data_in,
    input  [31:0] pc_plus_4_in,
    input  [31:0] imm_in,
    input  [4:0]  rd_in,
    input reg_write_in,
    input [1:0]  wb_sel_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] mem_read_data_out,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rd_out,
    output reg reg_write_out,
    output reg [1:0]  wb_sel_out
);

always @ (posedge clk) begin
    if (rst) begin
        alu_result_out    <= 32'b0;
        mem_read_data_out <= 32'b0;
        pc_plus_4_out      <= 32'b0;
        imm_out            <= 32'b0;
        rd_out             <= 5'b0;
        reg_write_out      <= 1'b0;
        wb_sel_out         <= 2'b0;
    end
    else if (stall) begin
        // do nothing — hold current values
    end
    else begin
        alu_result_out    <= alu_result_in;
        mem_read_data_out <= mem_read_data_in;
        pc_plus_4_out      <= pc_plus_4_in;
        imm_out            <= imm_in;
        rd_out             <= rd_in;
        reg_write_out      <= reg_write_in;
        wb_sel_out         <= wb_sel_in;
    end
end

endmodule
