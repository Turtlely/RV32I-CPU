`timescale 1ns/1ps

/* Module: cpu_tb
 * Purpose: Execute RV32I programs that verify arithmetic, memory, jumps, and branches.
 * Inputs/Outputs: None; programs are loaded hierarchically and state is self-checked.
 */
module cpu_tb;
    reg clk, rst;
    integer errors, i;

    cpu dut (.clk(clk), .rst(rst));
    initial clk = 0;
    always #5 clk = ~clk;

    function automatic [31:0] enc_r;
        input [6:0] fn7; input [4:0] rs2; input [4:0] rs1;
        input [2:0] fn3; input [4:0] rd; input [6:0] op;
        enc_r = {fn7, rs2, rs1, fn3, rd, op};
    endfunction
    function automatic [31:0] enc_i;
        input integer immediate; input [4:0] rs1; input [2:0] fn3;
        input [4:0] rd; input [6:0] op;
        enc_i = {immediate[11:0], rs1, fn3, rd, op};
    endfunction
    function automatic [31:0] enc_s;
        input integer immediate; input [4:0] rs2; input [4:0] rs1;
        input [2:0] fn3; input [6:0] op;
        enc_s = {immediate[11:5], rs2, rs1, fn3, immediate[4:0], op};
    endfunction
    function automatic [31:0] enc_b;
        input integer immediate; input [4:0] rs2; input [4:0] rs1;
        input [2:0] fn3; input [6:0] op;
        enc_b = {immediate[12], immediate[10:5], rs2, rs1, fn3,
                 immediate[4:1], immediate[11], op};
    endfunction
    function automatic [31:0] enc_u;
        input [19:0] immediate; input [4:0] rd; input [6:0] op;
        enc_u = {immediate, rd, op};
    endfunction
    function automatic [31:0] enc_j;
        input integer immediate; input [4:0] rd; input [6:0] op;
        enc_j = {immediate[20], immediate[10:1], immediate[11],
                 immediate[19:12], rd, op};
    endfunction

    task automatic load_word(input integer address, input [31:0] word);
        begin
            dut.imem.mem[address]   = word[7:0];
            dut.imem.mem[address+1] = word[15:8];
            dut.imem.mem[address+2] = word[23:16];
            dut.imem.mem[address+3] = word[31:24];
        end
    endtask

    task automatic check_reg(input [4:0] address, input [31:0] expected);
        begin
            if (dut.rf.regs[address] !== expected) begin
                $error("CPU x%0d expected=%h got=%h at PC=%h", address, expected,
                       dut.rf.regs[address], dut.pc_out);
                errors = errors + 1;
            end
        end
    endtask

    task automatic reset_cpu;
        begin
            rst = 1;
            @(posedge clk); #1;
            rst = 0;
        end
    endtask

    task automatic run_cycles(input integer count);
        integer cycle;
        begin
            for (cycle = 0; cycle < count; cycle = cycle + 1) begin
                @(posedge clk); #1;
                if (^dut.pc_out === 1'bx) begin
                    $error("CPU PC became unknown after %0d cycles", cycle + 1);
                    errors = errors + 1;
                    cycle = count;
                end
            end
        end
    endtask

    initial begin
        errors = 0;
        rst = 0;

        // Program 1: arithmetic, comparisons, memory, upper immediates, JAL, and JALR.
        reset_cpu();
        load_word( 0, enc_i( 5, 0, 3'b000,  1, 7'b0010011)); // addi x1,x0,5
        load_word( 4, enc_i(-3, 0, 3'b000,  2, 7'b0010011)); // addi x2,x0,-3
        load_word( 8, enc_r(0,2,1,3'b000,3,7'b0110011));     // add x3,x1,x2
        load_word(12, enc_r(7'b0100000,2,1,3'b000,4,7'b0110011)); // sub
        load_word(16, enc_r(0,2,1,3'b111,5,7'b0110011));     // and
        load_word(20, enc_r(0,2,1,3'b110,6,7'b0110011));     // or
        load_word(24, enc_r(0,2,1,3'b100,7,7'b0110011));     // xor
        load_word(28, enc_i(2,1,3'b001,8,7'b0010011));       // slli
        load_word(32, enc_i(1,2,3'b101,9,7'b0010011));       // srli
        load_word(36, enc_i(12'h401,2,3'b101,10,7'b0010011));// srai
        load_word(40, enc_r(0,1,2,3'b010,11,7'b0110011));    // slt x11,x2,x1
        load_word(44, enc_r(0,1,2,3'b011,12,7'b0110011));    // sltu x12,x2,x1
        load_word(48, enc_s(0,3,0,3'b010,7'b0100011));       // sw x3,0(x0)
        load_word(52, enc_i(0,0,3'b010,13,7'b0000011));      // lw x13,0(x0)
        load_word(56, enc_u(20'h12345,14,7'b0110111));       // lui
        load_word(60, enc_u(0,15,7'b0010111));               // auipc
        load_word(64, enc_j(8,16,7'b1101111));               // jal x16,72
        load_word(68, enc_i(99,0,3'b000,17,7'b0010011));     // skipped
        load_word(72, enc_i(17,0,3'b000,17,7'b0010011));
        load_word(76, enc_i(88,0,3'b000,18,7'b0010011));
        load_word(80, enc_i(0,18,3'b000,19,7'b1100111));     // jalr x19,x18,0
        load_word(84, enc_i(99,0,3'b000,20,7'b0010011));     // skipped
        load_word(88, enc_i(20,0,3'b000,20,7'b0010011));
        run_cycles(24);
        check_reg(0,0); check_reg(1,5); check_reg(2,32'hFFFFFFFD);
        check_reg(3,2); check_reg(4,8); check_reg(5,5); check_reg(6,32'hFFFFFFFD);
        check_reg(7,32'hFFFFFFF8); check_reg(8,20); check_reg(9,32'h7FFFFFFE);
        check_reg(10,32'hFFFFFFFE); check_reg(11,1); check_reg(12,0); check_reg(13,2);
        check_reg(14,32'h12345000); check_reg(15,60); check_reg(16,68);
        check_reg(17,17); check_reg(19,84); check_reg(20,20);

        // Program 2: not-taken branch must continue sequentially.
        reset_cpu();
        load_word(0, enc_i(1,0,3'b000,1,7'b0010011));
        load_word(4, enc_i(2,0,3'b000,2,7'b0010011));
        load_word(8, enc_b(8,2,1,3'b000,7'b1100011));       // beq not taken
        load_word(12, enc_i(3,0,3'b000,3,7'b0010011));
        run_cycles(4);
        check_reg(3,3);

        // Program 3: taken branch must select PC + immediate and skip address 12.
        reset_cpu();
        load_word(0, enc_i(1,0,3'b000,1,7'b0010011));
        load_word(4, enc_i(1,0,3'b000,2,7'b0010011));
        load_word(8, enc_b(8,2,1,3'b000,7'b1100011));       // beq to 16
        load_word(12, enc_i(99,0,3'b000,3,7'b0010011));
        load_word(16, enc_i(3,0,3'b000,3,7'b0010011));
        run_cycles(5);
        check_reg(3,3);

        if (errors == 0) $display("PASS: cpu_tb");
        else $fatal(1, "FAIL: cpu_tb had %0d errors", errors);
        $finish;
    end
endmodule
