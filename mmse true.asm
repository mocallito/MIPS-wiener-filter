.data
const: .double 0.0
.text
.globl mmse_func
# mmse(int N, int M, double *d, double *rdx, double *h)
mmse_func:
    # read M from caller''s stack slot (0($sp)) before changing $sp
    lw   $t5, 0($sp)        # t5 = M
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    move $t6, $a0
    move $t4, $a1
    # Call variance(d, N)
    move   $a1, $a0          # N
    move   $a0, $a2          # d
    jal    variance
    mov.d  $f12, $f0         # Ed2
    move $a0, $t6
    move $a1, $t4

    l.d   $f14, const         # hT_rdx accumulator
    li     $t9, 0

dot_loop:
    beq    $t9, $a1, dot_done
    sll    $t8, $t9, 3
    add    $t7, $a3, $t8
    l.d    $f2, 0($t7)       # rdx[i]
    add    $t7, $t5, $t8
    l.d    $f4, 0($t7)       # h[i]
    mul.d  $f4, $f2, $f4
    add.d  $f14, $f14, $f4
    addi   $t9, $t9, 1
    j      dot_loop

dot_done:
    sub.d  $f0, $f12, $f14   # mmse = Ed2 - hT_rdx

    lw   $ra, 0($sp)   # Restore return address
    addi $sp, $sp, 4   # Pop stack frame
    jr     $ra
