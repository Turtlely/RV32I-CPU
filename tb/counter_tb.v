`timescale 1ns/1ps // define timescale/precision

module counter_tb;
    // define signals
    reg clk; // input
    reg rst; // input
    wire [7:0] count; // output

    counter dut (
        .clk(clk), 
        .rst(rst), 
        .count(count)
    ); // instantiate DUT

    // initialize clock logic
    initial clk = 1'b0;
    initial rst = 1'b1;
    always #5 clk = ~clk; // half period of 5ns
    
    // test
    initial begin
        $monitor("time=%0t rst=%b count=%d", $time, rst, count);
        $dumpfile("sim/counter.vcd"); // create waveform output file
        $dumpvars(0, counter_tb); // record all signals in counter_tb

        #10; // wait 10ns
        rst = 1'b0;
        #100; // wait 100ns
        rst = 1'b1;
        #10; // wait 10ns
        
        $finish;
    end
endmodule