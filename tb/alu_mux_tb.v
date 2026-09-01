`timescale 1ns/1ps

/*
 * Module: alu_mux_tb
 * Purpose: Verify every ALU operand-selection combination with directed and random data.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module alu_mux_tb;
    reg         alu_a_src;
    reg         alu_b_src;
    reg  [31:0] rs1_data;
    reg  [31:0] pc;
    reg  [31:0] rs2_data;
    reg  [31:0] imm;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    integer errors;
    integer i;
    integer sel;

    alu_mux dut (.*);

    task automatic check;
        input a_sel;
        input b_sel;
        input [31:0] r1;
        input [31:0] pc_value;
        input [31:0] r2;
        input [31:0] immediate;
        begin
            alu_a_src = a_sel;
            alu_b_src = b_sel;
            rs1_data = r1;
            pc = pc_value;
            rs2_data = r2;
            imm = immediate;
            #1;
            if (alu_a !== (a_sel ? pc_value : r1)) begin
                $error("alu_a select failed: sel=%b expected=%h got=%h", a_sel, a_sel ? pc_value : r1, alu_a);
                errors = errors + 1;
            end
            if (alu_b !== (b_sel ? immediate : r2)) begin
                $error("alu_b select failed: sel=%b expected=%h got=%h", b_sel, b_sel ? immediate : r2, alu_b);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        for (sel = 0; sel < 4; sel = sel + 1)
            check(sel[1], sel[0], 32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444);
        for (i = 0; i < 500; i = i + 1)
            check($urandom_range(1, 0), $urandom_range(1, 0), $urandom, $urandom, $urandom, $urandom);

        if (errors == 0) $display("PASS: alu_mux_tb");
        else $fatal(1, "FAIL: alu_mux_tb had %0d errors", errors);
        $finish;
    end
endmodule
