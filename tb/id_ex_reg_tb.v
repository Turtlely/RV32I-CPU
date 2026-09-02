`timescale 1ns/1ps
/* Module: id_ex_reg_tb
 * Purpose: Verify ID/EX payload/control capture, hold, bubble, and reset priority.
 * Inputs/Outputs: None; stimulus and checks are internal.
 */
module id_ex_reg_tb;
 reg clk=0,rst,stall,flush; reg [31:0] rs1_data_in,rs2_data_in,pc_in,pc_plus_4_in,imm_in; reg [4:0] rd_in,rs1_in,rs2_in; reg [2:0] funct3_in; reg reg_write_in,mem_read_in,mem_write_in,branch_in,jump_in,alu_a_src_in,alu_b_src_in,uses_rs1_in,uses_rs2_in; reg [3:0] alu_op_in; reg [1:0] wb_sel_in;
 wire [31:0] rs1_data_out,rs2_data_out,pc_out,pc_plus_4_out,imm_out; wire [4:0] rd_out,rs1_out,rs2_out; wire [2:0] funct3_out; wire reg_write_out,mem_read_out,mem_write_out,branch_out,jump_out,alu_a_src_out,alu_b_src_out,uses_rs1_out,uses_rs2_out; wire [3:0] alu_op_out; wire [1:0] wb_sel_out; integer errors=0;
 always #5 clk=~clk; id_ex_reg dut(.*); task tick;begin @(posedge clk);#1;end endtask
 task check_live(input live);begin if(reg_write_out!==live||mem_read_out!==live||mem_write_out!==live||branch_out!==live||jump_out!==live||uses_rs1_out!==live||uses_rs2_out!==live||rd_out!==(live?5'd7:5'd0)||rs1_data_out!==(live?32'h11:0))begin $error("ID/EX mismatch");errors=errors+1;end end endtask
 initial begin rst=1;stall=0;flush=0;rs1_data_in='h11;rs2_data_in='h22;pc_in=4;pc_plus_4_in=8;imm_in=12;rd_in=7;funct3_in=3;reg_write_in=1;mem_read_in=1;mem_write_in=1;branch_in=1;jump_in=1;alu_a_src_in=1;alu_b_src_in=1;uses_rs1_in=1;uses_rs2_in=1;alu_op_in=9;wb_sel_in=2;rs1_in=1;rs2_in=2;tick;check_live(0);rst=0;tick;check_live(1);stall=1;rs1_data_in=0;uses_rs1_in=0;uses_rs2_in=0;tick;check_live(1);flush=1;tick;check_live(0);if(errors==0)$display("PASS: id_ex_reg_tb");else $fatal(1,"FAIL: %0d errors",errors);$finish;end
endmodule
