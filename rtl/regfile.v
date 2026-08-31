/*
Dual channel asynchronous read + synchronous write

32 rows of 32-bit registers in the register file
*/

module regfile (
    // Clock
    input clk,
    // Reset
    input rst,

    // Read port A
    input   [4:0]   read_addr_A,
    output  [31:0]  read_data_A,

    // Read port B
    input   [4:0]   read_addr_B,
    output  [31:0]  read_data_B,

    // Write port
    input   [4:0]   write_addr,
    input   [31:0]  write_data,
    input           write_en
);

// Define register file
reg [31:0] regs [31:0];

// Asynchronous read
assign read_data_A = (read_addr_A != 5'b0) ? regs[read_addr_A] : 32'b0;
assign read_data_B = (read_addr_B != 5'b0) ? regs[read_addr_B] : 32'b0;

always @ (posedge clk) begin
    // Synchronous reset
    if (rst) begin
        for (integer i = 0; i < 32; i++) begin
            regs[i] <= 32'b0;
        end
    end

    // Synchronous write
    else if (write_en && (write_addr != 5'b0)) begin
        regs[write_addr] <= write_data;
    end
end

endmodule
