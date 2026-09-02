/*
 * Module: regfile
 * Purpose: Provide 32 RV32I registers with two asynchronous read ports and one
 *          synchronous write port. Register x0 always reads as zero.
 *
 * Inputs:
 *   clk         - Clock signal.
 *   rst         - Active-high synchronous reset.
 *   read_addr_A - Address for read port A.
 *   read_addr_B - Address for read port B.
 *   write_addr  - Address of the register to write.
 *   write_data  - Data to write to the selected register.
 *   write_en    - Enables a register-file write.
 *
 * Outputs:
 *   read_data_A - Data returned through read port A.
 *   read_data_B - Data returned through read port B.
 */

module regfile (
    // Clock
    input clk,
    // Reset
    input rst,

    // Read port A
    input  [4:0]  read_addr_A,
    output [31:0] read_data_A,

    // Read port B
    input  [4:0]  read_addr_B,
    output [31:0] read_data_B,

    // Write port
    input [4:0]  write_addr,
    input [31:0] write_data,
    input        write_en
);

    // Define register file.
    reg [31:0] regs [31:0];

    // Asynchronous read.
    assign read_data_A = (read_addr_A == 5'b0) ? 32'b0 :
                            (write_en && write_addr == read_addr_A) ? write_data : 
                                                                        regs[read_addr_A];

    assign read_data_B = (read_addr_B == 5'b0) ? 32'b0 :
                            (write_en && write_addr == read_addr_B) ? write_data :
                                                                        regs[read_addr_B];

    always @(posedge clk) begin
        // Synchronous reset.
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                regs[i] <= 32'b0;
            end
        end

        // Synchronous write.
        else if (write_en && (write_addr != 5'b0)) begin
            regs[write_addr] <= write_data;
        end
    end

endmodule
