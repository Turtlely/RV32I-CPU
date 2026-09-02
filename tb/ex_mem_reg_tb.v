`timescale 1ns/1ps
/* Module: ex_mem_reg_tb
 * Purpose: Verify EX/MEM payload/control capture, hold, flush, and reset.
 * Inputs/Outputs: None; stimulus and checks are internal.
 */
module ex_mem_reg_tb;
 reg clk=0,rst,stall,flush; reg [31:0] alu_result_in,rs2_data_in,pc_plus_4_in,imm_in; reg [4:0] rd_in; reg [2:0] funct3_in; reg reg_write_in,mem_read_in,mem_write_in,uses_rs1_in,uses_rs2_in; reg [1:0] wb_sel_in;
 wire [31:0] alu_result_out,rs2_data_out,pc_plus_4_out,imm_out; wire [4:0] rd_out; wire [2:0] funct3_out; wire reg_write_out,mem_read_out,mem_write_out; wire [1:0] wb_sel_out; integer errors=0;
 always #5 clk=~clk; ex_mem_reg dut(.*); task tick;begin @(posedge clk);#1;end endtask task check_live(input live);begin if(alu_result_out!==(live?32'hAA:0)||rd_out!==(live?5'd9:0)||reg_write_out!==live||mem_write_out!==live)begin $error("EX/MEM mismatch");errors=errors+1;end end endtask
 initial begin rst=1;stall=0;flush=0;alu_result_in='hAA;rs2_data_in='hBB;pc_plus_4_in=8;imm_in=3;rd_in=9;funct3_in=2;reg_write_in=1;mem_read_in=1;mem_write_in=1;uses_rs1_in=1;uses_rs2_in=1;wb_sel_in=1;tick;check_live(0);rst=0;tick;check_live(1);stall=1;alu_result_in=0;tick;check_live(1);flush=1;tick;check_live(0);if(errors==0)$display("PASS: ex_mem_reg_tb");else $fatal(1,"FAIL: %0d errors",errors);$finish;end
endmodule
