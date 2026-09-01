/*
 * Module: wb_mux
 * Purpose: Select the value written back to an RV32I destination register.
 *
 * Inputs:
 *   wb_sel        - Selects the register write-back source.
 *   alu_result    - Result produced by the ALU.
 *   mem_read_data - Value returned from data memory.
 *   pc_plus_4     - Address of the instruction following the current one.
 *   imm           - Decoded immediate value used by LUI.
 *
 * Outputs:
 *   write_data - Selected register write-back value.
 */

module wb_mux (
    input [1:0] wb_sel,
    input [31:0] alu_result,
    input [31:0] mem_read_data,
    input [31:0] pc_plus_4,
    input [31:0] imm,

    output reg [31:0] write_data
);

always @ (*) begin
    case (wb_sel)
        2'b00: write_data = alu_result;
        2'b01: write_data = mem_read_data;
        2'b10: write_data = pc_plus_4;
        2'b11: write_data = imm;
        default: write_data = 32'hDEADBEEF;
    endcase
end

endmodule

