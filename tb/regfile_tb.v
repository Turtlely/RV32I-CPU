`timescale 1ns/1ps // define timescale/precision

module regfile_tb;
    // Clock
    reg clk;

    // Reset
    reg rst;

    // Read port A
    reg   [4:0]   read_addr_A;
    wire  [31:0]  read_data_A;

    // Read port B
    reg   [4:0]   read_addr_B;
    wire  [31:0]  read_data_B;

    // Write port
    reg   [4:0]   write_addr;
    reg   [31:0]  write_data;
    reg           write_en;

    // instantiate DUT
    regfile dut (
        // Clock
        .clk(clk), 
        
        // Reset
        .rst(rst),

        // Read port A
        .read_addr_A(read_addr_A), 
        .read_data_A(read_data_A),

        // Read port B
        .read_addr_B(read_addr_B),
        .read_data_B(read_data_B),

        // Write port
        .write_addr(write_addr),
        .write_data(write_data),
        .write_en(write_en)
    ); 

    // initialize clock logic
    initial clk = 1'b0;
    initial rst = 1'b0;
    initial write_en = 1'b0;
    always #5 clk = ~clk; // half period of 5ns
    
    // test
    initial begin
        //$monitor("time=%0t rst=%b count=%d", $time, rst, count);
        $dumpfile("sim/regfile.vcd"); // create waveform output file
        $dumpvars(0, regfile_tb); // record all signals in regfile_tb

        // Test Reset
        @(negedge clk);
        rst = 1'b1;

        // check the registers still hold their values
        for (integer i = 1; i< 32; i++) begin
            @(posedge clk)
            // Test read xi
            write_en = 1'b0; // disable write
            read_addr_A = 5'(i);
            read_addr_B = 5'(i);
            #1;

            assert (read_data_A == 32'b0) else $error("Time %0t: x%0d register is not reset on port A", $time, i);
            assert (read_data_B == 32'b0) else $error("Time %0t: x%0d register is not reset on port B", $time, i);
        end

        // Test write x0
        @(negedge clk);
        rst = 1'b0;
        write_addr = 5'b0;
        write_data = 32'hDEADBEEF;
        write_en   = 1'b1;

        @(posedge clk) // write occurs
        #1;

        // Test read x0
        write_en = 1'b0;
        read_addr_A = 5'b0;
        read_addr_B = 5'b0;
        #1;

        assert (read_data_A == 32'b0) else $error("Time %0t: x0 register did not return 0 on port A", $time);
        assert (read_data_B == 32'b0) else $error("Time %0t: x0 register did not return 0 on port B", $time);
        assert (dut.regs[0] == 32'b0) else $error("Time %0t: x0 register was written to", $time);

        // Test write x1-x31
        for (integer i = 1; i < 32; i++) begin
            @(negedge clk);
            // Test write xi
            write_addr = 5'(i);
            write_data = 32'hDEADBEEF;
            write_en   = 1'b1;

            // write occurs
            @(posedge clk);
            #1;

            // Test read xi
            write_en = 1'b0; // disable write
            read_addr_A = 5'(i);
            read_addr_B = 5'(i);
            #1;

            assert (read_data_A == 32'hDEADBEEF) else $error("Time %0t: x%0d register has incorrect data on port A", $time, i);
            assert (read_data_B == 32'hDEADBEEF) else $error("Time %0t: x%0d register has incorrect data on port B", $time, i);
        end

        // check the registers still hold their values
        for (integer i = 1; i< 32; i++) begin
            @(posedge clk)
            // Test read xi
            write_en = 1'b0; // disable write
            read_addr_A = 5'(i);
            read_addr_B = 5'(i);
            #1;

            assert (read_data_A == 32'hDEADBEEF) else $error("Time %0t: x%0d register has incorrect data on port A", $time, i);
            assert (read_data_B == 32'hDEADBEEF) else $error("Time %0t: x%0d register has incorrect data on port B", $time, i);
        end

        $finish;
    end
endmodule