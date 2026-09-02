`timescale 1ns/1ps
/* Module: forward_unit_tb
 * Purpose: Verify forwarding selection, priority, disabled writes, and x0 handling.
 * Inputs/Outputs: None; stimulus and checks are internal.
 */
module forward_unit_tb;
    reg [4:0] id_ex_rs1,id_ex_rs2,ex_mem_rd,mem_wb_rd;
    reg ex_mem_reg_write,mem_wb_reg_write,uses_rs1,uses_rs2;
    wire [1:0] fwd_a_sel,fwd_b_sel; integer errors;
    forward_unit dut(.*);
    task check(input [1:0] a,input [1:0] b); begin #1;
        if(fwd_a_sel!==a || fwd_b_sel!==b) begin $error("expected %b/%b got %b/%b",a,b,fwd_a_sel,fwd_b_sel); errors=errors+1; end
    end endtask
    initial begin errors=0; id_ex_rs1=1; id_ex_rs2=2; ex_mem_rd=0; mem_wb_rd=0; ex_mem_reg_write=0; mem_wb_reg_write=0; uses_rs1=1; uses_rs2=1; check(0,0);
        ex_mem_rd=1; ex_mem_reg_write=1; check(2,0); ex_mem_rd=2; check(0,2);
        ex_mem_reg_write=0; mem_wb_rd=1; mem_wb_reg_write=1; check(1,0); mem_wb_rd=2; check(0,1);
        ex_mem_rd=1; ex_mem_reg_write=1; mem_wb_rd=1; check(2,0);
        uses_rs1=0; check(0,0); uses_rs1=1; uses_rs2=0; ex_mem_rd=2; check(1,0);
        id_ex_rs1=0; ex_mem_rd=0; mem_wb_rd=0; check(0,0);
        if(errors==0)$display("PASS: forward_unit_tb");else $fatal(1,"FAIL: %0d errors",errors);$finish; end
endmodule
