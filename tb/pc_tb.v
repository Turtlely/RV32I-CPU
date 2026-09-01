`timescale 1ns/1ps

/* Module: pc_tb
 * Purpose: Verify synchronous reset, loading, persistence, and edge behavior of the PC.
 * Inputs/Outputs: None; all stimulus and checks are internal.
 */
module pc_tb;
    reg clk, rst;
    reg [31:0] next_pc;
    wire [31:0] pc;
    integer errors, i;

    pc dut (.*);
    initial clk = 0;
    always #5 clk = ~clk;

    task automatic clock_and_check(input [31:0] expected);
        begin
            @(posedge clk); #1;
            if (pc !== expected) begin
                $error("PC expected=%h got=%h rst=%b next_pc=%h", expected, pc, rst, next_pc);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; rst = 1; next_pc = 32'hDEADBEEF;
        clock_and_check(0); clock_and_check(0);
        @(negedge clk); rst = 0; next_pc = 32'h00000100;
        clock_and_check(32'h00000100);
        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk); next_pc = $urandom; clock_and_check(next_pc);
        end
        @(negedge clk); rst = 1; next_pc = 32'hFFFFFFFF;
        clock_and_check(0);
        if (errors == 0) $display("PASS: pc_tb");
        else $fatal(1, "FAIL: pc_tb had %0d errors", errors);
        $finish;
    end
endmodule
