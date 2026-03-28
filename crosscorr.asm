# void crosscorr(double *d, double *x, int N, double *rdx, int M)
# $a0 = d
# $a1 = x
# $a2 = N
# $a3 = rdx
# M is passed on stack at 16($sp) by caller
.text
.globl crosscorr

crosscorr:
    # read M from caller''s stack slot (0($sp)) before changing $sp
    lw   $t5, 0($sp)        # t5 = M
    li   $t6, 0             # k = 0

outer_loop:
    beq  $t6, $t5, end_func # if k == M, exit

    sll  $t7, $t6, 3        # offset = k*8
    add  $t8, $a3, $t7      # &rdx[k]
    mtc1 $zero, $f4
    cvt.d.w $f4, $f4
    s.d  $f4, 0($t8)        # rdx[k] = 0.0

    addi $t9, $t6, 0        # n = k
    l.d  $f2, 0($t8)        # accumulator = 0.0

inner_loop:
    beq  $t9, $a2, inner_done

    sll  $t7, $t9, 3
    add  $t7, $a0, $t7
    l.d  $f4, 0($t7)        # d[n]

    sub  $t7, $t9, $t6
    sll  $t7, $t7, 3
    add  $t7, $a1, $t7
    l.d  $f6, 0($t7)        # x[n-k]

    mul.d $f6, $f4, $f6
    add.d $f2, $f2, $f6

    addi $t9, $t9, 1
    j inner_loop

inner_done:
    mtc1 $a2, $f6
    cvt.d.w $f6, $f6
    div.d $f2, $f2, $f6
    s.d   $f2, 0($t8)

    addi $t6, $t6, 1
    j outer_loop

end_func:
    jr   $ra

