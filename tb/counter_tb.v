`timescale 1ns/1ps

/* Module: counter_tb
 * Purpose: Verify counter reset, incrementing, rollover, and repeated resets.
 * Inputs/Outputs: None; all stimulus and checks are internal.
 */
module counter_tb;
    reg clk, rst;
    wire [7:0] count;
    integer errors, i;
    reg [7:0] expected;

    counter dut (.*);
    initial clk = 0;
    always #5 clk = ~clk;

    task automatic step_and_check;
        begin
            @(posedge clk); #1;
            if (count !== expected) begin
                $error("Counter expected=%h got=%h rst=%b", expected, count, rst);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; rst = 1; expected = 0;
        step_and_check(); step_and_check();
        @(negedge clk); rst = 0;
        for (i = 0; i < 300; i = i + 1) begin
            expected = expected + 1'b1;
            step_and_check();
        end
        @(negedge clk); rst = 1; expected = 0; step_and_check();
        @(negedge clk); rst = 0; expected = 1; step_and_check();
        if (errors == 0) $display("PASS: counter_tb");
        else $fatal(1, "FAIL: counter_tb had %0d errors", errors);
        $finish;
    end
endmodule
