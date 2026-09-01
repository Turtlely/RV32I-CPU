/*
 * Module: control
 * Purpose: Decode an RV32I instruction into datapath control signals.
 *
 * Inputs:
 *   opcode - Instruction opcode field.
 *   funct3 - Instruction funct3 field.
 *   funct7 - Instruction funct7 field.
 *
 * Outputs:
 *   reg_write - Enables writing to the register file.
 *   mem_read  - Enables a data-memory read.
 *   mem_write - Enables a data-memory write.
 *   branch    - Identifies a conditional branch instruction.
 *   jump      - Selects a jump target for the next PC.
 *   alu_a_src - Selects rs1 or PC as ALU operand A.
 *   alu_b_src - Selects rs2 or the immediate as ALU operand B.
 *   alu_op    - Selects the ALU operation.
 *   wb_sel    - Selects the register write-back source.
 */

module control (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,

    output reg       reg_write,  // 0: no write to rd; 1: write to rd
    output reg       mem_read,   // 0: no memory read; 1: read at ALU result
    output reg       mem_write,  // 0: memory write disabled; 1: enabled
    output reg       branch,     // 0: no branch; 1: check ALU result
    output reg       jump,       // 0: PC + 4; 1: PC updates from ALU
    output reg       alu_a_src,  // 0: rs1; 1: PC
    output reg       alu_b_src,  // 0: rs2; 1: immediate
    output reg [3:0] alu_op,
    output reg [1:0] wb_sel      // 00: ALU; 01: memory; 10: PC + 4; 11: immediate
);

always @(*) begin
    reg_write = 1'b0;
    mem_read  = 1'b0;
    mem_write = 1'b0;
    branch    = 1'b0;
    jump      = 1'b0;
    alu_a_src = 1'b0;
    alu_b_src = 1'b0;
    alu_op    = 4'b0000;
    wb_sel    = 2'b00;

    case (opcode)
        7'b0010011: begin  // I-type (arithmetic)
            if (funct3 == 3'b000) begin // ADDI
                alu_op = 4'b0000;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b010) begin // SLTI
                alu_op = 4'b1000;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b011) begin // SLTIU
                alu_op = 4'b1001;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b100) begin // XORI
                alu_op = 4'b0100;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b110) begin // ORI
                alu_op = 4'b0011;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b111) begin // ANDI
                alu_op = 4'b0010;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b001 && funct7 == 7'b0000000) begin // SLLI
                alu_op = 4'b0101;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b101 && funct7 == 7'b0000000) begin // SRLI
                alu_op = 4'b0110;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
            if (funct3 == 3'b101 && funct7 == 7'b0100000) begin // SRAI
                alu_op = 4'b0111;
                reg_write = 1'b1;
                alu_b_src = 1'b1;
            end
        end
        7'b0000011: begin  // I-type (load)
            if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 || funct3 == 3'b100 || funct3 == 3'b101) begin // LB, LH, LW, LBU, LHU
                reg_write = 1'b1;
                alu_b_src = 1'b1;
                mem_read = 1'b1;
                wb_sel = 2'b01;
            end
        end
        7'b1100111: begin  // I-type (JALR)
            if (funct3 == 3'b000) begin // JALR
                reg_write = 1'b1;
                alu_b_src = 1'b1;
                alu_op = 4'b0000;
                wb_sel = 2'b10;
                jump = 1'b1;
            end
        end
        7'b0100011: begin  // S-type
            if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010) begin // SB, SH, SW
                alu_b_src = 1'b1;
                alu_op = 4'b0000;
                mem_write = 1'b1;
            end
        end
        7'b1100011: begin  // B-type
            if (funct3 == 3'b000) begin // BEQ
                alu_op = 4'b0001;
                branch = 1'b1;
            end
            if (funct3 == 3'b001) begin // BNE
                alu_op = 4'b0001;
                branch = 1'b1;
            end
            if (funct3 == 3'b100) begin // BLT
                alu_op = 4'b1000;
                branch = 1'b1;
            end
            if (funct3 == 3'b101) begin // BGE
                alu_op = 4'b1000;
                branch = 1'b1;
            end
            if (funct3 == 3'b110) begin // BLTU
                alu_op = 4'b1001;
                branch = 1'b1;
            end
            if (funct3 == 3'b111) begin // BGEU
                alu_op = 4'b1001;
                branch = 1'b1;
            end
        end

        7'b0110111: begin  // U-type (LUI)
            reg_write = 1'b1;
            wb_sel = 2'b11;
        end
        7'b0010111: begin  // U-type (AUIPC)
            reg_write = 1'b1;
            alu_a_src = 1'b1;
            alu_b_src = 1'b1;
            alu_op = 4'b0000;
        end
        7'b1101111: begin  // J-type (JAL)
            reg_write = 1'b1;
            wb_sel = 2'b10;
            alu_a_src = 1'b1;
            alu_b_src = 1'b1;
            alu_op = 4'b0000;
            jump = 1'b1;
        end
        7'b0110011: begin  // R-type
            if (funct3 == 3'b000 && funct7 == 7'b0000000) begin // ADD
                alu_op = 4'b0000;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b000 && funct7 == 7'b0100000) begin // SUB
                alu_op = 4'b0001;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b001 && funct7 == 7'b0000000) begin // SLL
                alu_op = 4'b0101;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b010 && funct7 == 7'b0000000) begin // SLT
                alu_op = 4'b1000;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b011 && funct7 == 7'b0000000) begin // SLTU
                alu_op = 4'b1001;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b100 && funct7 == 7'b0000000) begin // XOR
                alu_op = 4'b0100;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b101 && funct7 == 7'b0000000) begin // SRL
                alu_op = 4'b0110;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b101 && funct7 == 7'b0100000) begin // SRA
                alu_op = 4'b0111;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b110 && funct7 == 7'b0000000) begin // OR
                alu_op = 4'b0011;
                reg_write = 1'b1;
            end
            if (funct3 == 3'b111 && funct7 == 7'b0000000) begin // AND
                alu_op = 4'b0010;
                reg_write = 1'b1;
            end
        end
    endcase
end

endmodule
