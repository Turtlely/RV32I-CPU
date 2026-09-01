`timescale 1ns/1ps

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

    always #5 clk = ~clk;

    cpu dut(.clk(clk),
            .rst(rst));

    task automatic print_debug_state;
        begin
            $display("");
            $display("=============== STATE AFTER CLOCK EDGE %0d ===============", cycle);
            $display("FETCH PC : %08h    NEXT PC  : %08h", dut.pc_out, dut.next_pc);
            $display("NEXT INST: %08h    IMM      : %08h", dut.instr, dut.imm);
            $display("OPCODE   : %07b      FUNCT3   : %03b      FUNCT7: %07b",
                     dut.opcode, dut.funct3, dut.funct7);
            $display("RD       : x%0d       RS1      : x%0d       RS2   : x%0d",
                     dut.rd, dut.rs1, dut.rs2);
            $display("RS1 DATA : %08h    RS2 DATA : %08h", dut.rs1_data, dut.rs2_data);
            $display("ALU A    : %08h    ALU B    : %08h", dut.alu_a, dut.alu_b);
            $display("ALU OP   : %04b        RESULT   : %08h    ZERO: %b",
                     dut.alu_op, dut.alu_result, dut.alu_zero);
            $display("CONTROL  : reg_write=%b mem_read=%b mem_write=%b branch=%b jump=%b",
                     dut.reg_write, dut.mem_read, dut.mem_write, dut.branch, dut.jump);
            $display("MUXES    : alu_a_src=%b alu_b_src=%b wb_sel=%02b",
                     dut.alu_a_src, dut.alu_b_src, dut.wb_sel);
            $display("BRANCH   : take=%b target=%08h", dut.take_branch, dut.branch_target);
            $display("MEM/WB   : mem_read=%08h write_data=%08h",
                     dut.mem_read_data, dut.write_data);
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
                "cycle,pc,instr,next_pc,opcode,funct3,funct7,rd,rs1,rs2,imm,");
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
                "%0d,%08h,%08h,%08h,%02h,%01h,%02h,%0d,%0d,%0d,%08h,",
                cycle, trace_pc, trace_instr, trace_next_pc, trace_opcode,
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
            trace_pc = dut.pc_out;
            trace_instr = dut.instr;
            trace_next_pc = dut.next_pc;
            trace_opcode = dut.opcode;
            trace_funct3 = dut.funct3;
            trace_funct7 = dut.funct7;
            trace_rd = dut.rd;
            trace_rs1 = dut.rs1;
            trace_rs2 = dut.rs2;
            trace_imm = dut.imm;
            trace_rs1_data = dut.rs1_data;
            trace_rs2_data = dut.rs2_data;
            trace_alu_a = dut.alu_a;
            trace_alu_b = dut.alu_b;
            trace_alu_op = dut.alu_op;
            trace_alu_result = dut.alu_result;
            trace_alu_zero = dut.alu_zero;
            trace_reg_write = dut.reg_write;
            trace_mem_read = dut.mem_read;
            trace_mem_write = dut.mem_write;
            trace_branch = dut.branch;
            trace_jump = dut.jump;
            trace_alu_a_src = dut.alu_a_src;
            trace_alu_b_src = dut.alu_b_src;
            trace_wb_sel = dut.wb_sel;
            trace_take_branch = dut.take_branch;
            trace_branch_target = dut.branch_target;
            trace_mem_read_data = dut.mem_read_data;
            trace_write_data = dut.write_data;
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
        $display("dmem[0..3] = %02h %02h %02h %02h",
                dut.dmem.mem[0],
                dut.dmem.mem[1],
                dut.dmem.mem[2],
                dut.dmem.mem[3]);

        if (trace_fd != 0)
            $fclose(trace_fd);

        $finish;

    end
endmodule
