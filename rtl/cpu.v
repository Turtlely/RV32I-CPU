/*
 * Module: cpu
 * Purpose: Integrate the single-cycle RV32I datapath, control, register file,
 *          instruction memory, data memory, and program-counter logic.
 *
 * Inputs:
 *   clk - Clock signal used by sequential CPU state.
 *   rst - Active-high synchronous reset for the PC, register file, and memories.
 *
 * Outputs:
 *   None. Architectural state is held internally.
 */

module cpu (
    input clk,
    input rst
);

    // define the program counter
    wire [31:0] pc_out;
    wire [31:0] next_pc;

    pc pc_reg (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc_out)
    );

    wire [31:0] pc_plus_4 = pc_out + 32'd4;

    // instruction memory
    wire [31:0] instr;

    mem imem (
        .clk(clk),
        .rst(rst),
        .funct3(3'b010),
        .read_addr(pc_out),
        .read_data(instr),
        .write_en(1'b0),
        .write_addr(32'b0),
        .write_data(32'b0)
    );

    // decode
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] imm;


    decoder dec (
        .instr(instr),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .imm(imm)
    );

    // control
    wire reg_write, mem_read, mem_write, branch, jump;
    wire alu_a_src, alu_b_src;
    wire [3:0] alu_op;
    wire [1:0] wb_sel;

    control ctrl (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .alu_a_src(alu_a_src),
        .alu_b_src(alu_b_src),
        .alu_op(alu_op),
        .wb_sel(wb_sel)
    );

    // register file
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] write_data;

    regfile rf (
        .clk(clk),
        .rst(rst),
        .read_addr_A(rs1),
        .read_data_A(rs1_data),
        .read_addr_B(rs2),
        .read_data_B(rs2_data),
        .write_addr(rd),
        .write_data(write_data),
        .write_en(reg_write)
    );

    // ALU mux
    wire [31:0] alu_a, alu_b;

    alu_mux amux (
        .alu_a_src(alu_a_src),
        .alu_b_src(alu_b_src),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .pc(pc_out),
        .imm(imm),
        .alu_a(alu_a),
        .alu_b(alu_b)
    );

    // ALU
    wire [31:0] alu_result;
    wire alu_zero;

    alu alu0 (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    // branch conditions
    wire take_branch;
    branch_cond bcond (
        .branch(branch),
        .funct3(funct3),
        .alu_zero(alu_zero),
        .alu_result0(alu_result[0]),
        .take_branch(take_branch)
    );

    // data memory
    wire [31:0] mem_read_data;

    mem dmem (
        .clk(clk),
        .rst(rst),
        .funct3(funct3),
        .read_addr(alu_result),
        .read_data(mem_read_data),
        .write_en(mem_write),
        .write_addr(alu_result),
        .write_data(rs2_data)
    );

    // writeback mux
    wb_mux wbmux (
        .wb_sel(wb_sel),
        .alu_result(alu_result),
        .mem_read_data(mem_read_data),
        .pc_plus_4(pc_plus_4),
        .imm(imm),
        .write_data(write_data)
    );

    // next pc
    wire [31:0] branch_target = pc_out + imm;

    pc_mux pcmux (
        .alu_result(alu_result),
        .jump(jump),
        .take_branch(take_branch),
        .branch_target(branch_target),
        .pc_plus_4(pc_plus_4),
        .next_pc(next_pc)
    );

endmodule
