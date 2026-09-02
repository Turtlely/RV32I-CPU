/*
 * Module: hazard_detect
 * Purpose: Detect a load-use dependency between the EX and ID stages.
 *
 * Inputs:
 *   id_ex_mem_read - Indicates that the EX-stage instruction is a load.
 *   id_ex_rd       - Destination register of the EX-stage load.
 *   id_rs1         - First source register of the ID-stage instruction.
 *   id_rs2         - Second source register of the ID-stage instruction.
 *
 * Outputs:
 *   stall - Asserted when the ID-stage instruction depends on the load.
 */

module hazard_detect (
    input id_ex_mem_read, // is the instruction currently in EX a load?
    input [4:0] id_ex_rd, // what register are we loading into
    input [4:0] id_rs1,   // what registers is the ID stage instruction using?
    input [4:0] id_rs2, 
    input uses_rs1,
    input uses_rs2,

    output stall
);

    assign stall = id_ex_mem_read && (id_ex_rd != 5'b0) &&
                (((id_ex_rd == id_rs1) && uses_rs1) || ((id_ex_rd == id_rs2) && uses_rs2));

endmodule
