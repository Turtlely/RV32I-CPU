`timescale 1ns/1ps
/* Module: if_id_reg_tb
 * Purpose: Verify IF/ID capture, hold, flush, reset, and control priority.
 * Inputs/Outputs: None; stimulus and checks are internal.
 */
module if_id_reg_tb;
 reg clk=0,rst,stall,flush; reg [31:0] instr_in,pc_in,pc_plus_4_in; wire [31:0] instr_out,pc_out,pc_plus_4_out; integer errors=0;
 always #5 clk=~clk; if_id_reg dut(.*);
 task tick; begin @(posedge clk); #1; end endtask
 task check_values(input [31:0] i,p,p4); begin if(instr_out!==i||pc_out!==p||pc_plus_4_out!==p4)begin $error("IF/ID mismatch");errors=errors+1;end end endtask
 initial begin rst=1;stall=0;flush=0;instr_in=1;pc_in=2;pc_plus_4_in=6;tick;check_values(32'h13,0,0);rst=0;tick;check_values(1,2,6);
  stall=1;instr_in=9;pc_in=10;pc_plus_4_in=14;tick;check_values(1,2,6);flush=1;tick;check_values(32'h13,0,0);rst=1;tick;check_values(32'h13,0,0);
  if(errors==0)$display("PASS: if_id_reg_tb");else $fatal(1,"FAIL: %0d errors",errors);$finish;end
endmodule
