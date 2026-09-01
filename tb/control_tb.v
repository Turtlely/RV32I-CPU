`timescale 1ns/1ps

/*
 * Module: control_tb
 * Purpose: Verify control outputs for every implemented RV32I instruction encoding.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module control_tb;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire       branch;
    wire       jump;
    wire       alu_a_src;
    wire       alu_b_src;
    wire [3:0] alu_op;
    wire [1:0] wb_sel;
    integer errors;
    integer op;

    control dut (.*);

    task automatic check;
        input [6:0] op_code;
        input [2:0] fn3;
        input [6:0] fn7;
        input exp_reg_write;
        input exp_mem_read;
        input exp_mem_write;
        input exp_branch;
        input exp_jump;
        input exp_a_src;
        input exp_b_src;
        input [3:0] exp_alu_op;
        input [1:0] exp_wb_sel;
        begin
            opcode = op_code;
            funct3 = fn3;
            funct7 = fn7;
            #1;
            if ({reg_write, mem_read, mem_write, branch, jump, alu_a_src, alu_b_src, alu_op, wb_sel} !==
                {exp_reg_write, exp_mem_read, exp_mem_write, exp_branch, exp_jump,
                 exp_a_src, exp_b_src, exp_alu_op, exp_wb_sel}) begin
                $error("Control opcode=%b funct3=%b funct7=%b got=%b%b%b%b%b%b%b_%b_%b",
                       opcode, funct3, funct7, reg_write, mem_read, mem_write, branch,
                       jump, alu_a_src, alu_b_src, alu_op, wb_sel);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        // OP-IMM arithmetic and shifts.
        check(7'b0010011, 3'b000, 7'b0000000, 1,0,0,0,0,0,1, 4'b0000, 2'b00);
        check(7'b0010011, 3'b010, 7'b0000000, 1,0,0,0,0,0,1, 4'b1000, 2'b00);
        check(7'b0010011, 3'b011, 7'b0000000, 1,0,0,0,0,0,1, 4'b1001, 2'b00);
        check(7'b0010011, 3'b100, 7'b0000000, 1,0,0,0,0,0,1, 4'b0100, 2'b00);
        check(7'b0010011, 3'b110, 7'b0000000, 1,0,0,0,0,0,1, 4'b0011, 2'b00);
        check(7'b0010011, 3'b111, 7'b0000000, 1,0,0,0,0,0,1, 4'b0010, 2'b00);
        check(7'b0010011, 3'b001, 7'b0000000, 1,0,0,0,0,0,1, 4'b0101, 2'b00);
        check(7'b0010011, 3'b101, 7'b0000000, 1,0,0,0,0,0,1, 4'b0110, 2'b00);
        check(7'b0010011, 3'b101, 7'b0100000, 1,0,0,0,0,0,1, 4'b0111, 2'b00);

        // All load/store widths share address-generation controls.
        check(7'b0000011, 3'b000, 0, 1,1,0,0,0,0,1, 4'b0000, 2'b01);
        check(7'b0000011, 3'b001, 0, 1,1,0,0,0,0,1, 4'b0000, 2'b01);
        check(7'b0000011, 3'b010, 0, 1,1,0,0,0,0,1, 4'b0000, 2'b01);
        check(7'b0000011, 3'b100, 0, 1,1,0,0,0,0,1, 4'b0000, 2'b01);
        check(7'b0000011, 3'b101, 0, 1,1,0,0,0,0,1, 4'b0000, 2'b01);
        check(7'b0100011, 3'b000, 0, 0,0,1,0,0,0,1, 4'b0000, 2'b00);
        check(7'b0100011, 3'b001, 0, 0,0,1,0,0,0,1, 4'b0000, 2'b00);
        check(7'b0100011, 3'b010, 0, 0,0,1,0,0,0,1, 4'b0000, 2'b00);

        // Branches.
        check(7'b1100011, 3'b000, 0, 0,0,0,1,0,0,0, 4'b0001, 2'b00);
        check(7'b1100011, 3'b001, 0, 0,0,0,1,0,0,0, 4'b0001, 2'b00);
        check(7'b1100011, 3'b100, 0, 0,0,0,1,0,0,0, 4'b1000, 2'b00);
        check(7'b1100011, 3'b101, 0, 0,0,0,1,0,0,0, 4'b1000, 2'b00);
        check(7'b1100011, 3'b110, 0, 0,0,0,1,0,0,0, 4'b1001, 2'b00);
        check(7'b1100011, 3'b111, 0, 0,0,0,1,0,0,0, 4'b1001, 2'b00);

        // Upper immediates and jumps.
        check(7'b0110111, 0, 0, 1,0,0,0,0,0,0, 4'b0000, 2'b11);
        check(7'b0010111, 0, 0, 1,0,0,0,0,1,1, 4'b0000, 2'b00);
        check(7'b1101111, 0, 0, 1,0,0,0,1,1,1, 4'b0000, 2'b10);
        check(7'b1100111, 0, 0, 1,0,0,0,1,0,1, 4'b0000, 2'b10);

        // OP register-register variants.
        check(7'b0110011, 3'b000, 7'b0000000, 1,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0110011, 3'b000, 7'b0100000, 1,0,0,0,0,0,0, 4'b0001, 2'b00);
        check(7'b0110011, 3'b001, 7'b0000000, 1,0,0,0,0,0,0, 4'b0101, 2'b00);
        check(7'b0110011, 3'b010, 7'b0000000, 1,0,0,0,0,0,0, 4'b1000, 2'b00);
        check(7'b0110011, 3'b011, 7'b0000000, 1,0,0,0,0,0,0, 4'b1001, 2'b00);
        check(7'b0110011, 3'b100, 7'b0000000, 1,0,0,0,0,0,0, 4'b0100, 2'b00);
        check(7'b0110011, 3'b101, 7'b0000000, 1,0,0,0,0,0,0, 4'b0110, 2'b00);
        check(7'b0110011, 3'b101, 7'b0100000, 1,0,0,0,0,0,0, 4'b0111, 2'b00);
        check(7'b0110011, 3'b110, 7'b0000000, 1,0,0,0,0,0,0, 4'b0011, 2'b00);
        check(7'b0110011, 3'b111, 7'b0000000, 1,0,0,0,0,0,0, 4'b0010, 2'b00);

        // Unknown opcodes must leave all controls inactive.
        for (op = 0; op < 128; op = op + 1)
            if (op != 7'b0010011 && op != 7'b0000011 && op != 7'b1100111 &&
                op != 7'b0100011 && op != 7'b1100011 && op != 7'b0110111 &&
                op != 7'b0010111 && op != 7'b1101111 && op != 7'b0110011)
                check(op[6:0], 3'b010, 7'b1010101, 0,0,0,0,0,0,0, 4'b0000, 2'b00);

        // Reserved encodings must not create architectural side effects.
        check(7'b1100111, 3'b001, 7'b0000000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0000011, 3'b011, 7'b0000000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0000011, 3'b110, 7'b0000000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0100011, 3'b011, 7'b0000000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b1100011, 3'b010, 7'b0000000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b1100011, 3'b011, 7'b0000000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0010011, 3'b001, 7'b0100000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0010011, 3'b101, 7'b0010000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0110011, 3'b000, 7'b0000001, 0,0,0,0,0,0,0, 4'b0000, 2'b00);
        check(7'b0110011, 3'b111, 7'b0100000, 0,0,0,0,0,0,0, 4'b0000, 2'b00);

        if (errors == 0) $display("PASS: control_tb");
        else $fatal(1, "FAIL: control_tb had %0d errors", errors);
        $finish;
    end
endmodule
