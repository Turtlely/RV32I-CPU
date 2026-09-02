/*
 * Module: if_id_reg
 * Purpose: Hold instruction-fetch outputs between the IF and ID stages.
 *
 * Inputs:
 *   clk          - Clock signal.
 *   rst          - Active-high synchronous reset.
 *   stall        - Holds the current pipeline-register contents.
 *   flush        - Replaces the current instruction with a NOP.
 *   instr_in     - Instruction fetched by the IF stage.
 *   pc_in        - PC associated with the fetched instruction.
 *   pc_plus_4_in - Sequential PC associated with the fetched instruction.
 *
 * Outputs:
 *   instr_out     - Instruction presented to the ID stage.
 *   pc_out        - Instruction PC presented to the ID stage.
 *   pc_plus_4_out - Sequential PC presented to the ID stage.
 */

module if_id_reg(
    input clk,
    input rst,
    input stall,
    input flush,

    input [31:0] instr_in,
    input [31:0] pc_in,
    input [31:0] pc_plus_4_in,

    output reg [31:0] instr_out,
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus_4_out
);

always @ (posedge clk) begin
    if (rst || flush) begin
        instr_out <= 32'h00000013;
        pc_out <= 32'b0;
        pc_plus_4_out <= 32'b0;
    end
    else if (stall) begin
        // do nothing
    end
    else begin
        instr_out <= instr_in;
        pc_out <= pc_in;
        pc_plus_4_out <= pc_plus_4_in;
    end
end

endmodule
