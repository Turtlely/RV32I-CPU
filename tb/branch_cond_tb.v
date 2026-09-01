`timescale 1ns/1ps

/*
 * Module: branch_cond_tb
 * Purpose: Exhaustively verify all branch types for every Boolean ALU outcome.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module branch_cond_tb;
    reg        branch;
    reg  [2:0] funct3;
    reg        alu_zero;
    reg        alu_result0;
    wire       take_branch;
    integer errors;
    integer br;
    integer fn;
    integer z;
    integer r;
    reg expected;

    branch_cond dut (.*);

    initial begin
        errors = 0;
        for (br = 0; br < 2; br = br + 1)
            for (fn = 0; fn < 8; fn = fn + 1)
                for (z = 0; z < 2; z = z + 1)
                    for (r = 0; r < 2; r = r + 1) begin
                        branch = br[0];
                        funct3 = fn[2:0];
                        alu_zero = z[0];
                        alu_result0 = r[0];
                        #1;
                        expected = 1'b0;
                        if (branch) begin
                            case (funct3)
                                3'b000: expected = alu_zero;
                                3'b001: expected = !alu_zero;
                                3'b100: expected = alu_result0;
                                3'b101: expected = !alu_result0;
                                3'b110: expected = alu_result0;
                                3'b111: expected = !alu_result0;
                                default: expected = 1'b0;
                            endcase
                        end
                        if (take_branch !== expected) begin
                            $error("branch=%b funct3=%b zero=%b result0=%b expected=%b got=%b",
                                   branch, funct3, alu_zero, alu_result0, expected, take_branch);
                            errors = errors + 1;
                        end
                    end
        if (errors == 0) $display("PASS: branch_cond_tb");
        else $fatal(1, "FAIL: branch_cond_tb had %0d errors", errors);
        $finish;
    end
endmodule
