`timescale 1ns/1ps

/*
 * Module: wb_mux_tb
 * Purpose: Verify all register write-back source selections.
 * Inputs: None. Testbench signals are generated internally.
 * Outputs: None. Failures are reported with assertions and a final summary.
 */
module wb_mux_tb;
    reg  [1:0]  wb_sel;
    reg  [31:0] alu_result;
    reg  [31:0] mem_read_data;
    reg  [31:0] pc_plus_4;
    reg  [31:0] imm;
    wire [31:0] write_data;
    integer errors;
    integer i;
    integer sel;
    reg [31:0] expected;

    wb_mux dut (.*);

    initial begin
        errors = 0;
        for (i = 0; i < 500; i = i + 1) begin
            alu_result = $urandom;
            mem_read_data = $urandom;
            pc_plus_4 = $urandom;
            imm = $urandom;
            for (sel = 0; sel < 4; sel = sel + 1) begin
                wb_sel = sel[1:0];
                #1;
                case (sel)
                    0: expected = alu_result;
                    1: expected = mem_read_data;
                    2: expected = pc_plus_4;
                    3: expected = imm;
                endcase
                if (write_data !== expected) begin
                    $error("wb_sel=%b expected=%h got=%h", wb_sel, expected, write_data);
                    errors = errors + 1;
                end
            end
        end
        if (errors == 0) $display("PASS: wb_mux_tb");
        else $fatal(1, "FAIL: wb_mux_tb had %0d errors", errors);
        $finish;
    end
endmodule
