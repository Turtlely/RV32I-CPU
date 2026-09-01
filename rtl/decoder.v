/*
 * Module: decoder
 * Purpose: Extract RV32I instruction fields and construct the immediate value.
 *
 * Inputs:
 *   instr - 32-bit encoded instruction.
 *
 * Outputs:
 *   opcode - Instruction opcode field.
 *   rd     - Destination-register address.
 *   funct3 - Instruction funct3 field.
 *   rs1    - First source-register address.
 *   rs2    - Second source-register address.
 *   funct7 - Instruction funct7 field.
 *   imm    - Decoded and sign-extended immediate value.
 */

module decoder (
    input [31:0] instr,

    output     [6:0]  opcode,
    output     [4:0]  rd,
    output     [2:0]  funct3,
    output     [4:0]  rs1,
    output     [4:0]  rs2,
    output     [6:0]  funct7,
    output reg [31:0] imm
);

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // Decode immediate.
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: // I-type (arithmetic, load, JALR)
                imm = {{21{instr[31]}}, instr[30:25], instr[24:21], instr[20]};
            7'b0100011:                         // S-type
                imm = {{21{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
            7'b1100011:                         // B-type
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b0110111, 7'b0010111:             // U-type (LUI, AUIPC)
                imm = {instr[31], instr[30:20], instr[19:12], 12'b0};
            7'b1101111:                         // J-type (JAL)
                imm = {
                    {12{instr[31]}}, instr[19:12], instr[20],
                    instr[30:25], instr[24:21], 1'b0
                };
            default:                            // R-type
                imm = 32'hDEADBEEF;
        endcase
    end

endmodule
