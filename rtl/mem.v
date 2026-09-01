/*
 * Module: mem
 * Purpose: Provide byte-addressable data memory with asynchronous reads and
 *          synchronous writes.
 *
 * Inputs:
 *   clk        - Clock signal.
 *   rst        - Active-high synchronous reset.
 *   funct3     - Selects the memory access width and signedness.
 *   read_addr  - Byte address used for memory reads.
 *   write_en   - Enables a memory write.
 *   write_addr - Byte address used for memory writes.
 *   write_data - Data supplied for memory writes.
 *
 * Outputs:
 *   read_data - Loaded byte, halfword, or word after extension.
 */

module mem (
    input       clk,
    input       rst,
    input [2:0] funct3,

    input      [31:0] read_addr,
    output reg [31:0] read_data,

    input        write_en,
    input [31:0] write_addr,
    input [31:0] write_data
);

    reg [7:0] mem [0:1023];

    always @(*) begin
        case (funct3)
            // LB - sign extend
            3'b000: read_data = {{24{mem[read_addr[9:0]][7]}}, mem[read_addr[9:0]]};

            // LH - sign extend
            3'b001: read_data = {
                {16{mem[read_addr[9:0] + 1][7]}},
                mem[read_addr[9:0] + 1],
                mem[read_addr[9:0]]
            };

            // LW
            3'b010: read_data = {
                mem[read_addr[9:0] + 3],
                mem[read_addr[9:0] + 2],
                mem[read_addr[9:0] + 1],
                mem[read_addr[9:0]]
            };

            // LBU - zero extend
            3'b100: read_data = {24'b0, mem[read_addr[9:0]]};

            // LHU - zero extend
            3'b101: read_data = {
                16'b0,
                mem[read_addr[9:0] + 1],
                mem[read_addr[9:0]]
            };

            default: read_data = 32'hDEADBEEF;
        endcase
    end

    always @(posedge clk) begin
        // Synchronous reset.
        if (rst) begin
            for (integer i = 0; i < 1024; i++) begin
                mem[i] <= 8'b0;
            end
        end

        // Synchronous write.
        else if (write_en) begin
            case (funct3)
                3'b000: begin  // SB
                    mem[write_addr[9:0]] <= write_data[7:0];
                end
                3'b001: begin  // SH
                    mem[write_addr[9:0]] <= write_data[7:0];
                    mem[write_addr[9:0] + 1] <= write_data[15:8];
                end
                3'b010: begin  // SW
                    mem[write_addr[9:0]] <= write_data[7:0];
                    mem[write_addr[9:0] + 1] <= write_data[15:8];
                    mem[write_addr[9:0] + 2] <= write_data[23:16];
                    mem[write_addr[9:0] + 3] <= write_data[31:24];
                end
                default:;  // Invalid funct3.
            endcase
        end
    end

endmodule
