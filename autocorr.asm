# void autocorr(double *x, int N, double *rxx, int M)
# Arguments:
# $a1 = x (pointer)
# $a2 = N
# $a3 = rxx (pointer)
# $t9 = M
.text
.globl autocorr

autocorr:
    lw   $t9, 0($sp)          # load M into $t9
    addi $t5, $zero, 0        # k = 0

outer_loop:
    beq  $t5, $t9, end_func   # if k == M, exit

    # rxx[k] = 0.0
    sll  $t6, $t5, 3          # offset = k * 8 (double size)
    add  $t7, $a3, $t6        # &rxx[k]
    mtc1 $zero, $f4
    cvt.d.w $f4, $f4
    s.d  $f4, 0($t7)          # rxx[k] = 0.0

    addi $t8, $t5, 0          # n = k
    l.d  $f2, 0($t7)          # accumulator = 0.0

inner_loop:
    beq  $t8, $a2, inner_done # if n == N, break

    # load x[n]
    sll  $t6, $t8, 3          # offset = n * 8
    add  $t6, $a1, $t6
    l.d  $f4, 0($t6)

    # load x[n-k]
    sub  $t6, $t8, $t5        # n - k
    sll  $t6, $t6, 3
    add  $t6, $a1, $t6
    l.d  $f6, 0($t6)

    # multiply and accumulate
    mul.d $f6, $f4, $f6
    add.d $f2, $f2, $f6

    addi $t8, $t8, 1          # n++
    j inner_loop

inner_done:
    # divide by N
    mtc1 $a2, $f6             # move N into FP register
    cvt.d.w $f6, $f6          # convert int to double
    div.d $f2, $f2, $f6

    # store result in rxx[k]
    s.d $f2, 0($t7)

    addi $t5, $t5, 1          # k++
    j outer_loop

end_func:
    jr $ra

