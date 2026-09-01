`timescale 1ns/1ps

/* Module: mem_tb
 * Purpose: Verify reset, byte ordering, signed/unsigned loads, stores, and random accesses.
 * Inputs/Outputs: None; all stimulus and checks are internal.
 */
module mem_tb;
    reg clk, rst;
    reg [2:0] funct3;
    reg [31:0] read_addr;
    wire [31:0] read_data;
    reg write_en;
    reg [31:0] write_addr, write_data;
    reg [7:0] model [0:1023];
    integer errors, i, cycle, addr;
    reg [31:0] expected;

    mem dut (.*);
    initial clk = 0;
    always #5 clk = ~clk;

    function automatic [31:0] model_read(input [9:0] base, input [2:0] fn3);
        begin
            case (fn3)
                3'b000: model_read = {{24{model[base][7]}}, model[base]};
                3'b001: model_read = {{16{model[base+1][7]}}, model[base+1], model[base]};
                3'b010: model_read = {model[base+3], model[base+2], model[base+1], model[base]};
                3'b100: model_read = {24'b0, model[base]};
                3'b101: model_read = {16'b0, model[base+1], model[base]};
                default: model_read = 32'hDEADBEEF;
            endcase
        end
    endfunction

    task automatic check_read(input [31:0] address, input [2:0] fn3);
        begin
            read_addr = address; funct3 = fn3; #1;
            expected = model_read(address[9:0], fn3);
            if (read_data !== expected) begin
                $error("Read addr=%h funct3=%b expected=%h got=%h", address, fn3, expected, read_data);
                errors = errors + 1;
            end
        end
    endtask

    task automatic write_value(input [31:0] address, input [2:0] fn3, input [31:0] value);
        begin
            @(negedge clk); write_en = 1; write_addr = address; write_data = value; funct3 = fn3;
            case (fn3)
                3'b000: model[address[9:0]] = value[7:0];
                3'b001: begin model[address[9:0]] = value[7:0]; model[address[9:0]+1] = value[15:8]; end
                3'b010: begin
                    model[address[9:0]] = value[7:0]; model[address[9:0]+1] = value[15:8];
                    model[address[9:0]+2] = value[23:16]; model[address[9:0]+3] = value[31:24];
                end
            endcase
            @(posedge clk); #1; write_en = 0;
        end
    endtask

    initial begin
        errors = 0; rst = 1; funct3 = 0; read_addr = 0; write_en = 0;
        write_addr = 0; write_data = 0;
        for (i = 0; i < 1024; i = i + 1) model[i] = 0;
        @(posedge clk); #1;
        for (i = 0; i < 1024; i = i + 1)
            if (dut.mem[i] !== 0) begin $error("Reset failed at byte %0d", i); errors = errors + 1; end

        @(negedge clk); rst = 0;
        write_value(0, 3'b010, 32'h80FF7F01);
        check_read(0, 3'b010);
        check_read(0, 3'b000); check_read(1, 3'b000); check_read(2, 3'b000); check_read(3, 3'b000);
        check_read(0, 3'b100); check_read(1, 3'b100); check_read(2, 3'b100); check_read(3, 3'b100);
        check_read(0, 3'b001); check_read(2, 3'b001);
        check_read(0, 3'b101); check_read(2, 3'b101);

        // Verify little-endian byte placement and overlapping writes.
        write_value(100, 3'b010, 32'h12345678);
        write_value(101, 3'b000, 32'h000000AA);
        check_read(100, 3'b010);
        write_value(102, 3'b001, 32'h0000BEEF);
        check_read(100, 3'b010);

        // Invalid read encodings return the documented sentinel.
        check_read(20, 3'b011); check_read(20, 3'b110); check_read(20, 3'b111);

        // Random valid writes followed by every compatible read form.
        for (cycle = 0; cycle < 1000; cycle = cycle + 1) begin
            addr = $urandom_range(1020, 0);
            case ($urandom_range(2, 0))
                0: write_value(addr, 3'b000, $urandom);
                1: write_value(addr, 3'b001, $urandom);
                2: write_value(addr, 3'b010, $urandom);
            endcase
            check_read(addr, 3'b000); check_read(addr, 3'b100);
            check_read(addr, 3'b001); check_read(addr, 3'b101); check_read(addr, 3'b010);
        end

        // Disabled and invalid writes must preserve memory.
        @(negedge clk); write_en = 0; write_addr = 200; write_data = 32'hFFFFFFFF; funct3 = 3'b010;
        @(posedge clk); #1; check_read(200, 3'b010);
        write_value(200, 3'b111, 32'hFFFFFFFF); check_read(200, 3'b010);

        // Reset after use must clear the full array again.
        @(negedge clk); rst = 1; @(posedge clk); #1;
        for (i = 0; i < 1024; i = i + 1)
            if (dut.mem[i] !== 0) begin $error("Second reset failed at byte %0d", i); errors = errors + 1; end

        if (errors == 0) $display("PASS: mem_tb");
        else $fatal(1, "FAIL: mem_tb had %0d errors", errors);
        $finish;
    end
endmodule
