`timescale 1ns/1ps

/* Module: regfile_tb
 * Purpose: Verify reset, dual asynchronous reads, synchronous writes, x0, and persistence.
 * Inputs/Outputs: None; all stimulus and checks are internal.
 */
module regfile_tb;
    reg clk, rst;
    reg [4:0] read_addr_A, read_addr_B, write_addr;
    wire [31:0] read_data_A, read_data_B;
    reg [31:0] write_data;
    reg write_en;
    reg [31:0] model [0:31];
    integer errors, i, cycle;

    regfile dut (.*);
    initial clk = 0;
    always #5 clk = ~clk;

    task automatic check_reads(input [4:0] addr_a, input [4:0] addr_b);
        begin
            read_addr_A = addr_a; read_addr_B = addr_b; #1;
            if (read_data_A !== ((addr_a == 0) ? 32'b0 : model[addr_a])) begin
                $error("Port A x%0d expected=%h got=%h", addr_a, model[addr_a], read_data_A);
                errors = errors + 1;
            end
            if (read_data_B !== ((addr_b == 0) ? 32'b0 : model[addr_b])) begin
                $error("Port B x%0d expected=%h got=%h", addr_b, model[addr_b], read_data_B);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0; rst = 1; write_en = 0; read_addr_A = 0; read_addr_B = 0;
        write_addr = 0; write_data = 0;
        for (i = 0; i < 32; i = i + 1) model[i] = 0;
        @(posedge clk); #1;
        for (i = 0; i < 32; i = i + 1) check_reads(i[4:0], 31-i);

        @(negedge clk); rst = 0;
        for (i = 1; i < 32; i = i + 1) begin
            @(negedge clk); write_en = 1; write_addr = i[4:0];
            write_data = 32'hA5000000 ^ i; model[i] = write_data;
            @(posedge clk); #1; check_reads(i[4:0], (32-i) & 5'h1F);
        end

        @(negedge clk); write_addr = 0; write_data = 32'hFFFFFFFF;
        @(posedge clk); #1; check_reads(0, 0);
        if (dut.regs[0] !== 0) begin
            $error("Physical x0 storage changed to %h", dut.regs[0]); errors = errors + 1;
        end

        for (cycle = 0; cycle < 1000; cycle = cycle + 1) begin
            @(negedge clk); write_en = $urandom_range(1, 0);
            write_addr = $urandom_range(31, 0); write_data = $urandom;
            if (write_en && write_addr != 0) model[write_addr] = write_data;
            @(posedge clk); #1;
            check_reads($urandom_range(31, 0), $urandom_range(31, 0));
        end

        @(negedge clk); write_en = 0;
        for (i = 1; i < 32; i = i + 1) begin
            write_addr = i[4:0]; write_data = ~model[i];
            @(posedge clk); #1; check_reads(i[4:0], i[4:0]); @(negedge clk);
        end

        rst = 1; @(posedge clk); #1;
        for (i = 0; i < 32; i = i + 1) model[i] = 0;
        for (i = 0; i < 32; i = i + 1) check_reads(i[4:0], 31-i);

        if (errors == 0) $display("PASS: regfile_tb");
        else $fatal(1, "FAIL: regfile_tb had %0d errors", errors);
        $finish;
    end
endmodule
