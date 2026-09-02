/*
 * Module: control
 * Purpose: Decode an RV32I instruction into ID-stage datapath controls.
 *
 * Source-use outputs describe true register dependencies. Hazard detection and
 * forwarding use them to ignore instruction fields that are not operands.
 */

module control (
    input      [6:0] opcode,
    input      [2:0] funct3,
    input      [6:0] funct7,
    output reg       reg_write, // 0: do not write to a register, 1: write to a register
    output reg       mem_read,  // 0: do not read from memory, 1: read from memory
    output reg       mem_write, // 0: do not write to memory, 1: do write to memory
    output reg       branch,    // 0: no branch is possible, 1: a branch is possible
    output reg       jump,      // 0: do not jump, 1: do jump
    output reg       alu_a_src, // 0: alu_a comes from rs1, 1: alu_a comes from PC
    output reg       alu_b_src, // 0: alu_b comes from rs2, 1: alu_b comes from immediate
    output reg [3:0] alu_op,    
    output reg [1:0] wb_sel,    // writeback source is 00: ALU, 01: memory, 10: PC+4, 11: immediate
    output reg       uses_rs1,  // 0: does not use rs1, 1: uses rs1
    output reg       uses_rs2   // 0: does not use rs2, 1: uses rs2
);

    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_IMM    = 7'b0010011;
    localparam [6:0] OP_AUIPC  = 7'b0010111;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_REG    = 7'b0110011;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_JAL    = 7'b1101111;

    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b0001;
    localparam [3:0] ALU_AND  = 4'b0010;
    localparam [3:0] ALU_OR   = 4'b0011;
    localparam [3:0] ALU_XOR  = 4'b0100;
    localparam [3:0] ALU_SLL  = 4'b0101;
    localparam [3:0] ALU_SRL  = 4'b0110;
    localparam [3:0] ALU_SRA  = 4'b0111;
    localparam [3:0] ALU_SLT  = 4'b1000;
    localparam [3:0] ALU_SLTU = 4'b1001;

    always @(*) begin
        // Safe defaults make unsupported encodings behave like bubbles.
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;
        alu_a_src = 1'b0;
        alu_b_src = 1'b0;
        alu_op    = ALU_ADD;
        wb_sel    = 2'b00;
        uses_rs1  = 1'b0;
        uses_rs2  = 1'b0;

        case (opcode)
            OP_IMM: begin
                alu_b_src = 1'b1; // all immediate instr. use immediates for alu_b
                uses_rs1  = 1'b1; // all immediate instr. use the rs1 field
                case (funct3)
                    // all instr. funct3 variants write to a register rd
                    // we verify that funct3 and funct7 are correct setting reg_write flag
                    // TODO move everything into individual switch cases?
                    3'b000: begin alu_op = ALU_ADD;  reg_write = 1'b1; end // ADDI
                    3'b010: begin alu_op = ALU_SLT;  reg_write = 1'b1; end // SLTI
                    3'b011: begin alu_op = ALU_SLTU; reg_write = 1'b1; end // SLTIU
                    3'b100: begin alu_op = ALU_XOR;  reg_write = 1'b1; end // XORI
                    3'b110: begin alu_op = ALU_OR;   reg_write = 1'b1; end // ORI
                    3'b111: begin alu_op = ALU_AND;  reg_write = 1'b1; end // ANDI
                    3'b001: if (funct7 == 7'b0000000) begin
                        alu_op = ALU_SLL; reg_write = 1'b1;                 // SLLI
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_SRL; reg_write = 1'b1;             // SRLI
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = ALU_SRA; reg_write = 1'b1;             // SRAI
                        end
                    end
                endcase
                if (!reg_write) begin
                    alu_b_src = 1'b0;
                    uses_rs1 = 1'b0;
                end
            end

            OP_REG: begin
                // These instructions use both registers rs1 and rs2 and write to a destination register rd
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case ({funct7, funct3})
                    10'b0000000_000: begin alu_op = ALU_ADD;  reg_write = 1'b1; end
                    10'b0100000_000: begin alu_op = ALU_SUB;  reg_write = 1'b1; end
                    10'b0000000_001: begin alu_op = ALU_SLL;  reg_write = 1'b1; end
                    10'b0000000_010: begin alu_op = ALU_SLT;  reg_write = 1'b1; end
                    10'b0000000_011: begin alu_op = ALU_SLTU; reg_write = 1'b1; end
                    10'b0000000_100: begin alu_op = ALU_XOR;  reg_write = 1'b1; end
                    10'b0000000_101: begin alu_op = ALU_SRL;  reg_write = 1'b1; end
                    10'b0100000_101: begin alu_op = ALU_SRA;  reg_write = 1'b1; end
                    10'b0000000_110: begin alu_op = ALU_OR;   reg_write = 1'b1; end
                    10'b0000000_111: begin alu_op = ALU_AND;  reg_write = 1'b1; end
                    default: ;
                endcase
                if (!reg_write) begin
                    uses_rs1 = 1'b0;
                    uses_rs2 = 1'b0;
                end
            end

            OP_LOAD: begin
                if (funct3 == 3'b000 || funct3 == 3'b001 ||
                    funct3 == 3'b010 || funct3 == 3'b100 || funct3 == 3'b101) begin
                    reg_write = 1'b1;
                    mem_read  = 1'b1;
                    alu_b_src = 1'b1;
                    wb_sel    = 2'b01;
                    uses_rs1  = 1'b1;
                end
            end

            OP_STORE: begin
                if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010) begin
                    mem_write = 1'b1;
                    alu_b_src = 1'b1;
                    uses_rs1  = 1'b1;
                    uses_rs2  = 1'b1;
                end
            end

            OP_BRANCH: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000, 3'b001: begin alu_op = ALU_SUB;  branch = 1'b1; end
                    3'b100, 3'b101: begin alu_op = ALU_SLT;  branch = 1'b1; end
                    3'b110, 3'b111: begin alu_op = ALU_SLTU; branch = 1'b1; end
                    default: ;
                endcase
                if (!branch) begin
                    uses_rs1 = 1'b0;
                    uses_rs2 = 1'b0;
                end
            end

            OP_LUI: begin
                reg_write = 1'b1;
                wb_sel    = 2'b11;
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_a_src = 1'b1;
                alu_b_src = 1'b1;
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_a_src = 1'b1;
                alu_b_src = 1'b1;
                wb_sel    = 2'b10;
            end

            OP_JALR: begin
                if (funct3 == 3'b000) begin
                    reg_write = 1'b1;
                    jump      = 1'b1;
                    alu_b_src = 1'b1;
                    wb_sel    = 2'b10;
                    uses_rs1  = 1'b1;
                end
            end
            default: ;
        endcase
    end

endmodule
