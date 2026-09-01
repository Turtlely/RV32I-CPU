`timescale 1ns/1ps

/*
 * Module: pc_mux_tb
 * Purpose: Verify sequential, branch, and jump PC selection and priority.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module pc_mux_tb;
    reg  [31:0] alu_result;
    reg         jump;
    reg         take_branch;
    reg  [31:0] branch_target;
    reg  [31:0] pc_plus_4;
    wire [31:0] next_pc;
    integer errors;
    integer i;
    integer controls;
    reg [31:0] expected;

    pc_mux dut (.*);

    initial begin
        errors = 0;
        for (i = 0; i < 500; i = i + 1) begin
            alu_result = $urandom;
            branch_target = $urandom;
            pc_plus_4 = $urandom;
            for (controls = 0; controls < 4; controls = controls + 1) begin
                jump = controls[1];
                take_branch = controls[0];
                #1;
                expected = jump ? (alu_result & ~32'b1) :
                           take_branch ? branch_target : pc_plus_4;
                if (next_pc !== expected) begin
                    $error("jump=%b branch=%b expected=%h got=%h", jump, take_branch, expected, next_pc);
                    errors = errors + 1;
                end
            end
        end
        if (errors == 0) $display("PASS: pc_mux_tb");
        else $fatal(1, "FAIL: pc_mux_tb had %0d errors", errors);
        $finish;
    end
endmodule
