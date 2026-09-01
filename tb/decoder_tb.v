`timescale 1ns/1ps

/*
 * Module: decoder_tb
 * Purpose: Verify instruction-field extraction and every RV32I immediate format.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module decoder_tb;
    reg  [31:0] instr;
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  funct7;
    wire [31:0] imm;
    integer errors;
    integer i;
    integer kind;
    reg [31:0] expected_imm;

    decoder dut (.*);

    function automatic [31:0] reference_imm;
        input [31:0] instruction;
        begin
            case (instruction[6:0])
                7'b0010011, 7'b0000011, 7'b1100111:
                    reference_imm = {{20{instruction[31]}}, instruction[31:20]};
                7'b0100011:
                    reference_imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                7'b1100011:
                    reference_imm = {{19{instruction[31]}}, instruction[31], instruction[7],
                                     instruction[30:25], instruction[11:8], 1'b0};
                7'b0110111, 7'b0010111:
                    reference_imm = {instruction[31:12], 12'b0};
                7'b1101111:
                    reference_imm = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                                     instruction[20], instruction[30:21], 1'b0};
                default:
                    reference_imm = 32'hDEADBEEF;
            endcase
        end
    endfunction

    task automatic check_instruction;
        input [31:0] value;
        begin
            instr = value;
            #1;
            expected_imm = reference_imm(value);
            if (opcode !== value[6:0] || rd !== value[11:7] || funct3 !== value[14:12] ||
                rs1 !== value[19:15] || rs2 !== value[24:20] || funct7 !== value[31:25]) begin
                $error("Field decode failed for instr=%h", value);
                errors = errors + 1;
            end
            if (imm !== expected_imm) begin
                $error("Immediate decode instr=%h expected=%h got=%h", value, expected_imm, imm);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        // Directed positive and negative limits for each immediate format.
        check_instruction(32'h7FF00093); // ADDI x1, x0, 2047
        check_instruction(32'h80000093); // ADDI x1, x0, -2048
        check_instruction(32'h7E102FA3); // S-type field stress
        check_instruction(32'h80102023); // S-type negative limit
        check_instruction(32'h7E000FE3); // B-type positive field stress
        check_instruction(32'h80000063); // B-type negative limit
        check_instruction(32'hABCDE0B7); // LUI
        check_instruction(32'h80000097); // AUIPC
        check_instruction(32'h7FFFF0EF); // JAL positive field stress
        check_instruction(32'h800000EF); // JAL negative limit
        check_instruction(32'h00B50533); // R-type/default immediate

        // Randomized field and immediate verification across all formats.
        for (i = 0; i < 2000; i = i + 1) begin
            instr = $urandom;
            kind = $urandom_range(8, 0);
            case (kind)
                0: instr[6:0] = 7'b0010011;
                1: instr[6:0] = 7'b0000011;
                2: instr[6:0] = 7'b1100111;
                3: instr[6:0] = 7'b0100011;
                4: instr[6:0] = 7'b1100011;
                5: instr[6:0] = 7'b0110111;
                6: instr[6:0] = 7'b0010111;
                7: instr[6:0] = 7'b1101111;
                default: instr[6:0] = 7'b0110011;
            endcase
            check_instruction(instr);
        end

        if (errors == 0) $display("PASS: decoder_tb");
        else $fatal(1, "FAIL: decoder_tb had %0d errors", errors);
        $finish;
    end
endmodule
