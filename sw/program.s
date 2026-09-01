.section .text
.globl _start

# Sieve of Eratosthenes: mark composite numbers in mem[0..49] (byte array)
# mem[i] = 0 means "i is prime" (initially), 1 means "i is composite"
# After running: mem[i] == 0 for every prime i in [2, 49]

_start:
        addi x1, x0, 0        # x1 = i, loop index for clearing the array
        addi x2, x0, 50       # x2 = N = 50 (limit)

clear_loop:
        bge  x1, x2, clear_done
        sb   x0, 0(x1)         # mem[i] = 0 (mark as "prime" initially)
        addi x1, x1, 1
        jal  x0, clear_loop

clear_done:
        addi x3, x0, 2         # x3 = p, starting candidate prime

sieve_outer:
        # if p*p >= N, we're done
        mul_check:
        addi x4, x0, 0          # x4 = p*p, computed via repeated addition (no MUL)
        addi x5, x0, 0          # x5 = counter, counts up to p

square_loop:
        beq  x5, x3, square_done
        add  x4, x4, x3
        addi x5, x5, 1
        jal  x0, square_loop

square_done:
        bge  x4, x2, sieve_done  # if p*p >= N, sieve complete

        lb   x6, 0(x3)           # x6 = mem[p]
        bne  x6, x0, skip_mark   # if mem[p] != 0, p is already composite, skip

        addi x7, x3, 0           # x7 = j, starts at p*p... actually starts marking from p*p
        addi x7, x4, 0           # x7 = j = p*p

mark_loop:
        bge  x7, x2, mark_done
        sb   x3, 0(x7)           # mem[j] = p (any nonzero marks composite)
        add  x7, x7, x3          # j += p
        jal  x0, mark_loop

mark_done:
skip_mark:
        addi x3, x3, 1           # p++
        jal  x0, sieve_outer

sieve_done:
        jal  x0, sieve_done       # infinite loop — program complete