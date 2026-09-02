/*
 * Module: cpu
 * Purpose: Connect the five stages of the RV32I pipeline and resolve data and
 *          control hazards with stalling, flushing, and operand forwarding.
 *
 * Pipeline: IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
 * Inputs:   clk - pipeline clock; rst - active-high synchronous reset.
 * Outputs:  None. Architectural state is stored in rf, imem, and dmem.
 */

module cpu (
    input clk,
    input rst
);

    // ---------------------------------------------------------------------
    // Pipeline coordination
    // ---------------------------------------------------------------------
    wire stall_pipeline;
    wire flush_younger_stages;
    wire [1:0] forward_a_select;
    wire [1:0] forward_b_select;

    // ---------------------------------------------------------------------
    // IF stage signals
    // ---------------------------------------------------------------------
    wire [31:0] pc_if;
    wire [31:0] next_pc_if;
    wire [31:0] pc_plus_4_if;
    wire [31:0] instruction_if;

    // ---------------------------------------------------------------------
    // ID stage signals (outputs of IF/ID)
    // ---------------------------------------------------------------------
    wire [31:0] pc_id;
    wire [31:0] pc_plus_4_id;
    wire [31:0] instruction_id;
    wire [6:0]  opcode_id;
    wire [4:0]  destination_id;
    wire [4:0]  source_1_id;
    wire [4:0]  source_2_id;
    wire [2:0]  funct3_id;
    wire [6:0]  funct7_id;
    wire [31:0] immediate_id;
    wire [31:0] source_1_value_id;
    wire [31:0] source_2_value_id;
    wire        reg_write_id;
    wire        mem_read_id;
    wire        mem_write_id;
    wire        branch_id;
    wire        jump_id;
    wire        alu_a_is_pc_id;
    wire        alu_b_is_immediate_id;
    wire [3:0]  alu_operation_id;
    wire [1:0]  writeback_select_id;
    wire        uses_source_1_id;
    wire        uses_source_2_id;

    // ---------------------------------------------------------------------
    // EX stage signals (outputs of ID/EX)
    // ---------------------------------------------------------------------
    wire [31:0] pc_ex;
    wire [31:0] pc_plus_4_ex;
    wire [31:0] immediate_ex;
    wire [31:0] source_1_value_ex;
    wire [31:0] source_2_value_ex;
    wire [4:0]  destination_ex;
    wire [4:0]  source_1_ex;
    wire [4:0]  source_2_ex;
    wire [2:0]  funct3_ex;
    wire        reg_write_ex;
    wire        mem_read_ex;
    wire        mem_write_ex;
    wire        branch_ex;
    wire        jump_ex;
    wire        alu_a_is_pc_ex;
    wire        alu_b_is_immediate_ex;
    wire [3:0]  alu_operation_ex;
    wire [1:0]  writeback_select_ex;
    wire        uses_source_1_ex;
    wire        uses_source_2_ex;
    wire [31:0] forwarded_source_1_ex;
    wire [31:0] forwarded_source_2_ex;
    wire [31:0] alu_operand_a_ex;
    wire [31:0] alu_operand_b_ex;
    wire [31:0] alu_result_ex;
    wire        alu_zero_ex;
    wire        branch_taken_ex;
    wire [31:0] branch_target_ex;
    // ---------------------------------------------------------------------
    // MEM stage signals (outputs of EX/MEM)
    // ---------------------------------------------------------------------
    wire [31:0] alu_result_mem;
    wire [31:0] store_value_mem;
    wire [31:0] pc_plus_4_mem;
    wire [31:0] immediate_mem;
    wire [4:0]  destination_mem;
    wire [2:0]  funct3_mem;
    wire        reg_write_mem;
    wire        mem_read_mem;
    wire        mem_write_mem;
    wire [1:0]  writeback_select_mem;
    wire [31:0] memory_read_value_mem;
    wire [31:0] forward_value_mem;

    // ---------------------------------------------------------------------
    // WB stage signals (outputs of MEM/WB)
    // ---------------------------------------------------------------------
    wire [31:0] alu_result_wb;
    wire [31:0] memory_read_value_wb;
    wire [31:0] pc_plus_4_wb;
    wire [31:0] immediate_wb;
    wire [4:0]  destination_wb;
    wire        reg_write_wb;
    wire [1:0]  writeback_select_wb;
    wire [31:0] writeback_value_wb;

    assign pc_plus_4_if = pc_if + 32'd4;
    assign flush_younger_stages = jump_ex || branch_taken_ex;
    assign branch_target_ex = pc_ex + immediate_ex;

    // =====================================================================
    // IF: choose a PC and fetch one instruction
    // =====================================================================
    pc pc_reg (
        .clk(clk),
        .rst(rst),
        .en(!stall_pipeline),
        .next_pc(next_pc_if),
        .pc(pc_if)
    );

    pc_mux next_pc_mux (
        .alu_result(alu_result_ex),
        .jump(jump_ex),
        .take_branch(branch_taken_ex),
        .branch_target(branch_target_ex),
        .pc_plus_4(pc_plus_4_if),
        .next_pc(next_pc_if)
    );

    mem imem (
        .clk(clk),
        .rst(rst),
        .funct3(3'b010), // Load a full word (32-bits) from memory
        .read_addr(pc_if),
        .read_data(instruction_if),
        .write_en(1'b0), // Instruction memory is read-only
        .write_addr(32'b0),
        .write_data(32'b0) 
    );

    // =====================================================================
    // IF/ID: hold fetch during a stall; discard it after a control transfer
    // =====================================================================
    if_id_reg if_id (
        .clk(clk),
        .rst(rst),
        .stall(stall_pipeline),
        .flush(flush_younger_stages),
        .instr_in(instruction_if),
        .pc_in(pc_if),
        .pc_plus_4_in(pc_plus_4_if),
        .instr_out(instruction_id),
        .pc_out(pc_id),
        .pc_plus_4_out(pc_plus_4_id)
    );

    // =====================================================================
    // ID: decode fields, generate control, and read source registers
    // =====================================================================
    decoder instruction_decoder (
        .instr(instruction_id),
        .opcode(opcode_id),
        .rd(destination_id),
        .funct3(funct3_id),
        .rs1(source_1_id),
        .rs2(source_2_id),
        .funct7(funct7_id),
        .imm(immediate_id)
    );

    control control_decoder (
        .opcode(opcode_id),
        .funct3(funct3_id),
        .funct7(funct7_id),
        .reg_write(reg_write_id),
        .mem_read(mem_read_id),
        .mem_write(mem_write_id),
        .branch(branch_id),
        .jump(jump_id),
        .alu_a_src(alu_a_is_pc_id),
        .alu_b_src(alu_b_is_immediate_id),
        .alu_op(alu_operation_id),
        .wb_sel(writeback_select_id),
        .uses_rs1(uses_source_1_id),
        .uses_rs2(uses_source_2_id)
    );

    regfile rf (
        .clk(clk),
        .rst(rst),
        .read_addr_A(source_1_id),
        .read_data_A(source_1_value_id),
        .read_addr_B(source_2_id),
        .read_data_B(source_2_value_id),
        .write_addr(destination_wb),
        .write_data(writeback_value_wb),
        .write_en(reg_write_wb)
    );

    hazard_detect load_use_hazard_detector (
        .id_ex_mem_read(mem_read_ex),
        .id_ex_rd(destination_ex),
        .id_rs1(source_1_id),
        .id_rs2(source_2_id),
        .uses_rs1(uses_source_1_id),
        .uses_rs2(uses_source_2_id),
        .stall(stall_pipeline)
    );

    // =====================================================================
    // ID/EX: insert a bubble for a load-use hazard or control transfer
    // =====================================================================
    id_ex_reg id_ex (
        .clk(clk), .rst(rst), .stall(1'b0),
        .flush(stall_pipeline || flush_younger_stages),
        .rs1_data_in(source_1_value_id), .rs2_data_in(source_2_value_id),
        .pc_in(pc_id), .pc_plus_4_in(pc_plus_4_id), .imm_in(immediate_id),
        .rd_in(destination_id), .funct3_in(funct3_id),
        .reg_write_in(reg_write_id), .mem_read_in(mem_read_id),
        .mem_write_in(mem_write_id), .branch_in(branch_id), .jump_in(jump_id),
        .alu_a_src_in(alu_a_is_pc_id), .alu_b_src_in(alu_b_is_immediate_id),
        .alu_op_in(alu_operation_id), .wb_sel_in(writeback_select_id),
        .rs1_in(source_1_id), .rs2_in(source_2_id),
        .uses_rs1_in(uses_source_1_id), .uses_rs2_in(uses_source_2_id),
        .rs1_data_out(source_1_value_ex), .rs2_data_out(source_2_value_ex),
        .pc_out(pc_ex), .pc_plus_4_out(pc_plus_4_ex), .imm_out(immediate_ex),
        .rd_out(destination_ex), .funct3_out(funct3_ex),
        .reg_write_out(reg_write_ex), .mem_read_out(mem_read_ex),
        .mem_write_out(mem_write_ex), .branch_out(branch_ex), .jump_out(jump_ex),
        .alu_a_src_out(alu_a_is_pc_ex), .alu_b_src_out(alu_b_is_immediate_ex),
        .alu_op_out(alu_operation_ex), .wb_sel_out(writeback_select_ex),
        .rs1_out(source_1_ex), .rs2_out(source_2_ex),
        .uses_rs1_out(uses_source_1_ex), .uses_rs2_out(uses_source_2_ex)
    );

    // =====================================================================
    // EX: forward operands, execute the ALU, and resolve branches
    // =====================================================================
    assign forward_value_mem =
        (writeback_select_mem == 2'b11) ? immediate_mem :
        (writeback_select_mem == 2'b10) ? pc_plus_4_mem : alu_result_mem;

    forward_unit forwarding_control (
        .id_ex_rs1(source_1_ex), .id_ex_rs2(source_2_ex),
        .ex_mem_rd(destination_mem), .ex_mem_reg_write(reg_write_mem),
        .mem_wb_rd(destination_wb), .mem_wb_reg_write(reg_write_wb),
        .uses_rs1(uses_source_1_ex), .uses_rs2(uses_source_2_ex),
        .fwd_a_sel(forward_a_select), .fwd_b_sel(forward_b_select)
    );

    assign forwarded_source_1_ex =
        (forward_a_select == 2'b10) ? forward_value_mem :
        (forward_a_select == 2'b01) ? writeback_value_wb : source_1_value_ex;
    assign forwarded_source_2_ex =
        (forward_b_select == 2'b10) ? forward_value_mem :
        (forward_b_select == 2'b01) ? writeback_value_wb : source_2_value_ex;

    alu_mux operand_mux (
        .alu_a_src(alu_a_is_pc_ex), .alu_b_src(alu_b_is_immediate_ex),
        .rs1_data(forwarded_source_1_ex), .pc(pc_ex),
        .rs2_data(forwarded_source_2_ex), .imm(immediate_ex),
        .alu_a(alu_operand_a_ex), .alu_b(alu_operand_b_ex)
    );

    alu execute_alu (
        .a(alu_operand_a_ex), .b(alu_operand_b_ex),
        .alu_op(alu_operation_ex), .result(alu_result_ex), .zero(alu_zero_ex)
    );

    branch_cond branch_condition (
        .branch(branch_ex), .funct3(funct3_ex), .alu_zero(alu_zero_ex),
        .alu_result0(alu_result_ex[0]), .take_branch(branch_taken_ex)
    );

    // =====================================================================
    // EX/MEM
    // =====================================================================
    ex_mem_reg ex_mem (
        .clk(clk), .rst(rst), .stall(1'b0), .flush(1'b0),
        .alu_result_in(alu_result_ex), .rs2_data_in(forwarded_source_2_ex),
        .pc_plus_4_in(pc_plus_4_ex), .imm_in(immediate_ex),
        .rd_in(destination_ex), .funct3_in(funct3_ex),
        .reg_write_in(reg_write_ex), .mem_read_in(mem_read_ex),
        .mem_write_in(mem_write_ex), .wb_sel_in(writeback_select_ex),
        .alu_result_out(alu_result_mem), .rs2_data_out(store_value_mem),
        .pc_plus_4_out(pc_plus_4_mem), .imm_out(immediate_mem),
        .rd_out(destination_mem), .funct3_out(funct3_mem),
        .reg_write_out(reg_write_mem), .mem_read_out(mem_read_mem),
        .mem_write_out(mem_write_mem), .wb_sel_out(writeback_select_mem)
    );

    // =====================================================================
    // MEM: access byte-addressable data memory
    // =====================================================================
    mem dmem (
        .clk(clk), .rst(rst), .funct3(funct3_mem),
        .read_addr(alu_result_mem), .read_data(memory_read_value_mem),
        .write_en(mem_write_mem), .write_addr(alu_result_mem),
        .write_data(store_value_mem)
    );

    // =====================================================================
    // MEM/WB
    // =====================================================================
    mem_wb_reg mem_wb (
        .clk(clk), .rst(rst), .stall(1'b0),
        .alu_result_in(alu_result_mem), .mem_read_data_in(memory_read_value_mem),
        .pc_plus_4_in(pc_plus_4_mem), .imm_in(immediate_mem),
        .rd_in(destination_mem), .reg_write_in(reg_write_mem),
        .wb_sel_in(writeback_select_mem), .alu_result_out(alu_result_wb),
        .mem_read_data_out(memory_read_value_wb), .pc_plus_4_out(pc_plus_4_wb),
        .imm_out(immediate_wb), .rd_out(destination_wb),
        .reg_write_out(reg_write_wb), .wb_sel_out(writeback_select_wb)
    );

    // =====================================================================
    // WB: choose the value written to rd
    // =====================================================================
    wb_mux writeback_mux (
        .wb_sel(writeback_select_wb), .alu_result(alu_result_wb),
        .mem_read_data(memory_read_value_wb), .pc_plus_4(pc_plus_4_wb),
        .imm(immediate_wb), .write_data(writeback_value_wb)
    );

endmodule
