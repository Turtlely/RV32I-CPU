`timescale 1ns/1ps

/*
 * Module: alu_tb
 * Purpose: Self-check every ALU operation with directed edge cases and random vectors.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module alu_tb;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_op;
    wire [31:0] result;
    wire        zero;

    integer errors;
    integer i;
    integer op;
    reg [31:0] expected;

    alu dut (.a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero));

    function automatic [31:0] reference_result;
        input [31:0] lhs;
        input [31:0] rhs;
        input [3:0] operation;
        begin
            case (operation)
                4'b0000: reference_result = lhs + rhs;
                4'b0001: reference_result = lhs - rhs;
                4'b0010: reference_result = lhs & rhs;
                4'b0011: reference_result = lhs | rhs;
                4'b0100: reference_result = lhs ^ rhs;
                4'b0101: reference_result = lhs << rhs[4:0];
                4'b0110: reference_result = lhs >> rhs[4:0];
                4'b0111: reference_result = $signed(lhs) >>> rhs[4:0];
                4'b1000: reference_result = ($signed(lhs) < $signed(rhs)) ? 32'b1 : 32'b0;
                4'b1001: reference_result = (lhs < rhs) ? 32'b1 : 32'b0;
                default: reference_result = 32'hDEADBEEF;
            endcase
        end
    endfunction

    task automatic check;
        input [31:0] lhs;
        input [31:0] rhs;
        input [3:0] operation;
        begin
            a = lhs;
            b = rhs;
            alu_op = operation;
            #1;
            expected = reference_result(lhs, rhs, operation);
            if (result !== expected) begin
                $error("ALU op=%h a=%h b=%h: expected %h, got %h", operation, lhs, rhs, expected, result);
                errors = errors + 1;
            end
            if (zero !== (expected == 32'b0)) begin
                $error("Zero flag op=%h a=%h b=%h: expected %b, got %b", operation, lhs, rhs, expected == 0, zero);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;

        for (op = 0; op < 16; op = op + 1) begin
            check(32'b0, 32'b0, op[3:0]);
            check(32'hFFFFFFFF, 32'b1, op[3:0]);
            check(32'h80000000, 32'h7FFFFFFF, op[3:0]);
            check(32'h7FFFFFFF, 32'h80000000, op[3:0]);
            check(32'hAAAAAAAA, 32'h55555555, op[3:0]);
        end

        for (i = 0; i < 1000; i = i + 1)
            check($urandom, $urandom, $urandom_range(15, 0));

        if (errors == 0)
            $display("PASS: alu_tb");
        else
            $fatal(1, "FAIL: alu_tb had %0d errors", errors);
        $finish;
    end
endmodule
