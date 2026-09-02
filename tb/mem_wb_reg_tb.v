`timescale 1ns/1ps
/* Module: mem_wb_reg_tb
 * Purpose: Verify MEM/WB payload/control capture, hold, and reset.
 * Inputs/Outputs: None; stimulus and checks are internal.
 */
module mem_wb_reg_tb;
 reg clk=0,rst,stall; reg [31:0] alu_result_in,mem_read_data_in,pc_plus_4_in,imm_in;reg [4:0] rd_in;reg reg_write_in;reg [1:0] wb_sel_in;wire [31:0] alu_result_out,mem_read_data_out,pc_plus_4_out,imm_out;wire [4:0] rd_out;wire reg_write_out;wire [1:0] wb_sel_out;integer errors=0;
 always #5 clk=~clk;mem_wb_reg dut(.*);task tick;begin @(posedge clk);#1;end endtask task check_live(input live);begin if(alu_result_out!==(live?32'hAA:0)||rd_out!==(live?5'd4:0)||reg_write_out!==live)begin $error("MEM/WB mismatch");errors=errors+1;end end endtask
 initial begin rst=1;stall=0;alu_result_in='hAA;mem_read_data_in='hBB;pc_plus_4_in=8;imm_in=3;rd_in=4;reg_write_in=1;wb_sel_in=1;tick;check_live(0);rst=0;tick;check_live(1);stall=1;alu_result_in=0;tick;check_live(1);rst=1;tick;check_live(0);if(errors==0)$display("PASS: mem_wb_reg_tb");else $fatal(1,"FAIL: %0d errors",errors);$finish;end
endmodule
