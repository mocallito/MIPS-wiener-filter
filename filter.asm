.data
const: .double 0.0

.text
.globl filter

# filter function: applies FIR filter
# Inputs:
# $a0 = base address h[]
# $a1 = base address x[]
# $a2 = base address y[]
# $a3 = M
# $t8 = N
filter:
    lw   $t8, 0($sp)         # retrieve N from stack
    li   $t5, 0              # n = 0

loop_n:
    bge  $t5, $t8, done      # if n >= N, exit

    # y[n] = 0.0
    l.d  $f6, const          # accumulator reset

    li   $t6, 0              # k = 0

loop_k:
    bge  $t6, $a3, store_y   # if k >= M, go store result
    sub  $t7, $t5, $t6       # compute n-k
    bltz $t7, skip_k         # if n-k < 0, skip

    # load x[n-k]
    mul  $t7, $t7, 8         # offset = (n-k)*8
    add  $t7, $a1, $t7
    l.d  $f4, 0($t7)

    # load h[k]
    mul  $t7, $t6, 8         # offset = k*8
    add  $t7, $a0, $t7
    l.d  $f2, 0($t7)

    # multiply and accumulate
    mul.d $f4, $f2, $f4
    add.d $f6, $f6, $f4

skip_k:
    addi $t6, $t6, 1
    j    loop_k

store_y:
    # store y[n]
    mul  $t7, $t5, 8
    add  $t7, $a2, $t7
    s.d  $f6, 0($t7)

    addi $t5, $t5, 1
    j    loop_n

done:
    jr   $ra

