`timescale 1ns/1ps

/*
 * Module: program_tb
 * Purpose: Load and execute a bare-metal program while producing debug,
 *          waveform, and machine-readable execution traces.
 *
 * Inputs:
 *   None. Clock, reset, program loading, and run length are generated internally.
 *
 * Outputs:
 *   None. Results are written to the console, VCD, and optional CSV trace.
 */

module program_tb;
    reg clk, rst;
    integer cycle;
    integer max_cycles;
    integer debug_mem_bytes;
    integer reg_index;
    integer mem_index;
    integer trace_fd;

    reg [31:0] trace_pc, trace_instr, trace_next_pc, trace_imm;
    reg [31:0] trace_rs1_data, trace_rs2_data, trace_alu_a, trace_alu_b;
    reg [31:0] trace_alu_result, trace_branch_target, trace_mem_read_data;
    reg [31:0] trace_write_data;
    reg [6:0] trace_opcode, trace_funct7;
    reg [4:0] trace_rd, trace_rs1, trace_rs2;
    reg [3:0] trace_alu_op;
    reg [2:0] trace_funct3;
    reg [1:0] trace_wb_sel;
    reg trace_alu_zero, trace_reg_write, trace_mem_read, trace_mem_write;
    reg trace_branch, trace_jump, trace_alu_a_src, trace_alu_b_src;
    reg trace_take_branch;

    // Debug-only instruction tags. The functional datapath does not need to
    // carry instruction words through MEM and WB, but the trace viewer does.
    reg        valid_id, valid_ex, valid_mem, valid_wb;
    reg [31:0] instr_ex, instr_mem, instr_wb;
    reg [31:0] pc_ex, pc_mem, pc_wb;

    always #5 clk = ~clk;

    cpu dut(.clk(clk),
            .rst(rst));

    task automatic print_debug_state;
        begin
            $display("");
            $display("=============== STATE AFTER CLOCK EDGE %0d ===============", cycle);
            $display("IF  PC   : %08h    INSTR    : %08h    NEXT PC: %08h", dut.pc_if, dut.instruction_if, dut.next_pc_if);
            $display("ID  PC   : %08h    INSTR    : %08h", dut.pc_id, dut.instruction_id);
            $display("EX  PC   : %08h    IMM      : %08h", dut.pc_ex, dut.immediate_ex);
            $display("OPCODE   : %07b      FUNCT3   : %03b      FUNCT7: %07b",
                     dut.opcode_id, dut.funct3_ex, dut.funct7_id);
            $display("RD       : x%0d       RS1      : x%0d       RS2   : x%0d",
                     dut.destination_ex, dut.source_1_ex, dut.source_2_ex);
            $display("RS1 DATA : %08h    RS2 DATA : %08h", dut.forwarded_source_1_ex, dut.forwarded_source_2_ex);
            $display("ALU A    : %08h    ALU B    : %08h", dut.alu_operand_a_ex, dut.alu_operand_b_ex);
            $display("ALU OP   : %04b        RESULT   : %08h    ZERO: %b",
                     dut.alu_operation_ex, dut.alu_result_ex, dut.alu_zero_ex);
            $display("CONTROL  : reg_write=%b mem_read=%b mem_write=%b branch=%b jump=%b",
                     dut.reg_write_ex, dut.mem_read_ex, dut.mem_write_ex, dut.branch_ex, dut.jump_ex);
            $display("MUXES    : alu_a_src=%b alu_b_src=%b wb_sel=%02b",
                     dut.alu_a_is_pc_ex, dut.alu_b_is_immediate_ex, dut.writeback_select_ex);
            $display("BRANCH   : take=%b target=%08h", dut.branch_taken_ex, dut.branch_target_ex);
            $display("MEM/WB   : mem_read=%08h write_data=%08h",
                     dut.memory_read_value_mem, dut.writeback_value_wb);
            $display("REGISTERS:");

            for (reg_index = 0; reg_index < 32; reg_index = reg_index + 1) begin
                $write("x%-2d=%08h", reg_index, dut.rf.regs[reg_index]);
                if ((reg_index % 4) == 3)
                    $write("\n");
                else
                    $write("    ");
            end

            $display("DATA MEMORY (little-endian words):");
            for (mem_index = 0; mem_index < debug_mem_bytes; mem_index = mem_index + 4) begin
                $write("[%03h]=%08h", mem_index,
                       {dut.dmem.mem[mem_index + 3], dut.dmem.mem[mem_index + 2],
                        dut.dmem.mem[mem_index + 1], dut.dmem.mem[mem_index]});
                if ((mem_index % 16) == 12)
                    $write("\n");
                else
                    $write("    ");
            end
            if ((debug_mem_bytes % 16) != 0)
                $write("\n");
            $display("========================================================");
        end
    endtask

    task automatic write_trace_header;
        begin
            $fwrite(trace_fd,
                "cycle,stall,flush,if_pc,if_instr,id_valid,id_pc,id_instr,");
            $fwrite(trace_fd,
                "ex_valid,ex_pc,ex_instr,mem_valid,mem_pc,mem_instr,wb_valid,wb_pc,wb_instr,");
            $fwrite(trace_fd,
                "mem_commit_write,mem_commit_addr,mem_commit_data,wb_commit_write,wb_commit_rd,wb_commit_data,");
            $fwrite(trace_fd,
                "next_pc,opcode,funct3,funct7,rd,rs1,rs2,imm,");
            $fwrite(trace_fd,
                "rs1_data,rs2_data,alu_a,alu_b,alu_op,alu_result,alu_zero,");
            $fwrite(trace_fd,
                "reg_write,mem_read,mem_write,branch,jump,alu_a_src,alu_b_src,");
            $fwrite(trace_fd,
                "wb_sel,take_branch,branch_target,mem_read_data,write_data");
            for (reg_index = 0; reg_index < 32; reg_index = reg_index + 1)
                $fwrite(trace_fd, ",x%0d", reg_index);
            for (mem_index = 0; mem_index < 1024; mem_index = mem_index + 1)
                $fwrite(trace_fd, ",m%0d", mem_index);
            $fwrite(trace_fd, "\n");
        end
    endtask

    task automatic write_trace_row;
        begin
            $fwrite(trace_fd,
                "%0d,%0d,%0d,%08h,%08h,%0d,%08h,%08h,",
                cycle, dut.stall_pipeline, dut.flush_younger_stages, dut.pc_if, dut.instruction_if,
                valid_id, dut.pc_id, dut.instruction_id);
            $fwrite(trace_fd,
                "%0d,%08h,%08h,%0d,%08h,%08h,%0d,%08h,%08h,",
                valid_ex, pc_ex, instr_ex, valid_mem, pc_mem, instr_mem,
                valid_wb, pc_wb, instr_wb);
            $fwrite(trace_fd,
                "%0d,%08h,%08h,%0d,%0d,%08h,",
                dut.mem_write_mem, dut.alu_result_mem,
                dut.store_value_mem, dut.reg_write_wb,
                dut.destination_wb, dut.writeback_value_wb);
            $fwrite(trace_fd,
                "%08h,%02h,%01h,%02h,%0d,%0d,%0d,%08h,",
                trace_next_pc, trace_opcode,
                trace_funct3, trace_funct7, trace_rd, trace_rs1, trace_rs2,
                trace_imm);
            $fwrite(trace_fd,
                "%08h,%08h,%08h,%08h,%01h,%08h,%0d,",
                trace_rs1_data, trace_rs2_data, trace_alu_a, trace_alu_b,
                trace_alu_op, trace_alu_result, trace_alu_zero);
            $fwrite(trace_fd,
                "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%01h,%0d,%08h,%08h,%08h",
                trace_reg_write, trace_mem_read, trace_mem_write, trace_branch,
                trace_jump, trace_alu_a_src, trace_alu_b_src, trace_wb_sel,
                trace_take_branch, trace_branch_target, trace_mem_read_data,
                trace_write_data);
            for (reg_index = 0; reg_index < 32; reg_index = reg_index + 1)
                $fwrite(trace_fd, ",%08h", dut.rf.regs[reg_index]);
            for (mem_index = 0; mem_index < 1024; mem_index = mem_index + 1)
                $fwrite(trace_fd, ",%02h", dut.dmem.mem[mem_index]);
            $fwrite(trace_fd, "\n");
        end
    endtask

    always @(posedge clk) begin
        if (!rst) begin
            trace_pc = dut.pc_ex;
            trace_instr = {dut.imem.mem[dut.pc_ex + 3],
                           dut.imem.mem[dut.pc_ex + 2],
                           dut.imem.mem[dut.pc_ex + 1],
                           dut.imem.mem[dut.pc_ex]};
            trace_next_pc = dut.next_pc_if;
            trace_opcode = dut.opcode_id;
            trace_funct3 = dut.funct3_ex;
            trace_funct7 = dut.funct7_id;
            trace_rd = dut.destination_ex;
            trace_rs1 = dut.source_1_ex;
            trace_rs2 = dut.source_2_ex;
            trace_imm = dut.immediate_ex;
            trace_rs1_data = dut.forwarded_source_1_ex;
            trace_rs2_data = dut.forwarded_source_2_ex;
            trace_alu_a = dut.alu_operand_a_ex;
            trace_alu_b = dut.alu_operand_b_ex;
            trace_alu_op = dut.alu_operation_ex;
            trace_alu_result = dut.alu_result_ex;
            trace_alu_zero = dut.alu_zero_ex;
            trace_reg_write = dut.reg_write_ex;
            trace_mem_read = dut.mem_read_ex;
            trace_mem_write = dut.mem_write_ex;
            trace_branch = dut.branch_ex;
            trace_jump = dut.jump_ex;
            trace_alu_a_src = dut.alu_a_is_pc_ex;
            trace_alu_b_src = dut.alu_b_is_immediate_ex;
            trace_wb_sel = dut.writeback_select_ex;
            trace_take_branch = dut.branch_taken_ex;
            trace_branch_target = dut.branch_target_ex;
            trace_mem_read_data = dut.memory_read_value_mem;
            trace_write_data = dut.writeback_value_wb;

            // Advance the debug tags with the same hold/flush rules as the
            // corresponding functional pipeline registers.
            valid_wb <= valid_mem;
            instr_wb <= instr_mem;
            pc_wb    <= pc_mem;
            valid_mem <= valid_ex;
            instr_mem <= instr_ex;
            pc_mem    <= pc_ex;
            if (dut.stall_pipeline || dut.flush_younger_stages) begin
                valid_ex <= 1'b0;
                instr_ex <= 32'h00000013;
                pc_ex    <= 32'b0;
            end else begin
                valid_ex <= valid_id;
                instr_ex <= dut.instruction_id;
                pc_ex    <= dut.pc_id;
            end
            if (dut.flush_younger_stages) begin
                valid_id <= 1'b0;
            end else if (!dut.stall_pipeline) begin
                valid_id <= 1'b1;
            end
            #1;
            cycle = cycle + 1;
            if ($test$plusargs("debug"))
                print_debug_state();
            if (trace_fd != 0)
                write_trace_row();
        end
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        cycle = 0;
        max_cycles = 100;
        debug_mem_bytes = 32;
        trace_fd = 0;
        valid_id = 0;
        valid_ex = 0;
        valid_mem = 0;
        valid_wb = 0;
        instr_ex = 32'h00000013;
        instr_mem = 32'h00000013;
        instr_wb = 32'h00000013;
        pc_ex = 0;
        pc_mem = 0;
        pc_wb = 0;
        if ($value$plusargs("cycles=%d", max_cycles))
            $display("Simulation cycle limit: %0d", max_cycles);
        if ($value$plusargs("mem_bytes=%d", debug_mem_bytes)) begin
            if (debug_mem_bytes < 4)
                debug_mem_bytes = 4;
            if (debug_mem_bytes > 1024)
                debug_mem_bytes = 1024;
            debug_mem_bytes = (debug_mem_bytes + 3) & ~3;
            $display("Debug data-memory range: 0 to %0d bytes", debug_mem_bytes - 1);
        end
        if ($test$plusargs("trace")) begin
            trace_fd = $fopen("sim/program_trace.csv", "w");
            if (trace_fd == 0)
                $fatal(1, "Unable to open sim/program_trace.csv");
            write_trace_header();
            $display("Execution trace: sim/program_trace.csv");
        end

        $dumpfile("sim/program.vcd");
        $dumpvars(0, program_tb);
        
        @(posedge clk);
        #1;

        // load program into instruction memory
        $readmemh("sw/program.hex", dut.imem.mem);

        @(negedge clk);
        rst = 1'b0;

        repeat (max_cycles) @(posedge clk);
        #2;

        $display("x3 = %0d", dut.rf.regs[3]);
        $display("status    = %08h", {dut.dmem.mem[255], dut.dmem.mem[254],
                                      dut.dmem.mem[253], dut.dmem.mem[252]});
        $display("signature = %08h", {dut.dmem.mem[251], dut.dmem.mem[250],
                                      dut.dmem.mem[249], dut.dmem.mem[248]});

        if (trace_fd != 0)
            $fclose(trace_fd);

        $finish;

    end
endmodule
