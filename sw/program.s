.section .text
.globl _start

# Five-stage pipeline stress test.
# dmem[248] = 0x600DCAFE on success.
# dmem[252] = 1 on success, or the negative failing test number.
_start:
        addi x31,x0,0
        sw x31,252(x0)

        # 1: consecutive ALU forwarding from EX/MEM and MEM/WB.
        addi x31,x0,1
        addi x1,x0,5
        addi x2,x1,7
        add x3,x2,x1
        addi x4,x0,17
        bne x3,x4,fail

        # 2: forwarded store data and a load-use stall.
        addi x31,x0,2
        sw x3,128(x0)
        lw x5,128(x0)
        add x6,x5,x5
        addi x7,x0,34
        bne x6,x7,fail

        # 3: newest producer wins when two stages target x8.
        addi x31,x0,3
        addi x8,x0,1
        addi x8,x8,1
        add x9,x8,x0
        addi x7,x0,2
        bne x9,x7,fail

        # 4: WB-to-ID register-file bypass.
        addi x31,x0,4
        addi x10,x0,40
        addi x0,x0,0
        addi x0,x0,0
        addi x11,x10,2
        addi x7,x0,42
        bne x11,x7,fail

        # 5: taken branch flushes two younger instructions.
        addi x31,x0,5
        addi x20,x0,0
        beq x1,x1,branch_ok
        addi x20,x0,99
        sw x1,240(x0)
branch_ok:
        bne x20,x0,fail
        lw x21,240(x0)
        bne x21,x0,fail

        # 6: JAL/JALR, link register, flush, and function forwarding.
        addi x31,x0,6
        addi x10,x0,9
        jal x11,function
return_from_function:
        addi x7,x0,21
        bne x10,x7,fail
        jal x0,after_function
function:
        add x10,x10,x10
        addi x10,x10,3
        jalr x0,0(x11)
        addi x10,x0,0
after_function:

        # 7: byte/halfword stores and signed/unsigned loads.
        addi x31,x0,7
        addi x12,x0,-1
        sb x12,132(x0)
        lb x13,132(x0)
        bne x13,x12,fail
        lbu x14,132(x0)
        addi x15,x0,255
        bne x14,x15,fail
        addi x12,x0,-128
        sh x12,134(x0)
        lh x13,134(x0)
        bne x13,x12,fail
        lhu x14,134(x0)
        slli x15,x15,8
        addi x15,x15,128
        bne x14,x15,fail

        # 8: shifts and signed/unsigned comparisons.
        addi x31,x0,8
        addi x16,x0,-16
        srai x17,x16,2
        addi x18,x0,-4
        bne x17,x18,fail
        srli x17,x16,28
        addi x18,x0,15
        bne x17,x18,fail
        slt x17,x16,x0
        addi x18,x0,1
        bne x17,x18,fail
        sltu x17,x16,x0
        bne x17,x0,fail

        # 9: dependency-heavy loop; sum 1 through 20 = 210.
        addi x31,x0,9
        addi x22,x0,1
        addi x23,x0,21
        addi x24,x0,0
sum_loop:
        add x24,x24,x22
        addi x22,x22,1
        blt x22,x23,sum_loop
        addi x25,x0,210
        bne x24,x25,fail

        # 10: repeated load/modify/store hazards.
        addi x31,x0,10
        sw x0,140(x0)
        addi x26,x0,8
memory_loop:
        lw x27,140(x0)
        addi x27,x27,3
        sw x27,140(x0)
        addi x26,x26,-1
        bne x26,x0,memory_loop
        lw x27,140(x0)
        addi x28,x0,24
        bne x27,x28,fail

pass:
        lui x29,0x600dd
        addi x29,x29,-1282
        sw x29,248(x0)
        addi x30,x0,1
        sw x30,252(x0)
pass_loop:
        jal x0,pass_loop

fail:
        sub x31,x0,x31
        sw x31,252(x0)
fail_loop:
        jal x0,fail_loop
