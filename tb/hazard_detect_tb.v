`timescale 1ns/1ps
/* Module: hazard_detect_tb
 * Purpose: Verify load-use stalls, source-use qualification, and x0 handling.
 * Inputs/Outputs: None; stimulus and checks are internal.
 */
module hazard_detect_tb;
    reg id_ex_mem_read, uses_rs1, uses_rs2;
    reg [4:0] id_ex_rd, id_rs1, id_rs2;
    wire stall;
    integer errors;
    hazard_detect dut (.*);
    task check(input expected);
        begin #1; if (stall !== expected) begin
            $error("stall expected=%b got=%b", expected, stall); errors=errors+1;
        end end
    endtask
    initial begin
        errors=0; id_ex_mem_read=0; id_ex_rd=5; id_rs1=5; id_rs2=5; uses_rs1=1; uses_rs2=1; check(0);
        id_ex_mem_read=1; check(1);
        uses_rs1=0; id_rs2=0; check(0);
        uses_rs2=1; id_rs2=5; check(1);
        uses_rs2=0; check(0);
        id_ex_rd=0; id_rs1=0; uses_rs1=1; check(0);
        id_ex_rd=7; id_rs1=6; id_rs2=8; uses_rs2=1; check(0);
        if(errors==0) $display("PASS: hazard_detect_tb"); else $fatal(1,"FAIL: %0d errors",errors); $finish;
    end
endmodule
