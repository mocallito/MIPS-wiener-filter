# Arguments:
# $a0 = M (matrix size)
# $a1 = address of rxx array
# $a2 = address of RM (pre-allocated 2D array, row-major)
.text
.globl build_toeplitz

build_toeplitz:
    li   $t7, 0            # i = 0
outer_loop:
    beq  $t7, $a0, done    # if i == M, exit

    li   $t8, 0            # j = 0
inner_loop:
    beq  $t8, $a0, next_i  # if j == M, go to next row

    sub  $t9, $t7, $t8     # t9 = i - j
    bltz $t9, neg_index
pos_index:
    # index = i - j
    sll  $t9, $t9, 3       # offset = index * sizeof(double) (8 bytes)
    add  $t9, $a1, $t9     # addr = rxx + offset
    l.d  $f0, 0($t9)       # load rxx[index] into f0
    j    store_value

neg_index:
    sub  $t9, $zero, $t9   # index = -(i - j)
    sll  $t9, $t9, 3
    add  $t9, $a1, $t9
    l.d  $f0, 0($t9)

store_value:
    # compute RM[i][j] address
    mul  $t9, $t7, $a0     # i * M
    add  $t9, $t9, $t8     # i*M + j
    sll  $t9, $t9, 3       # offset * sizeof(double)
    add  $t9, $a2, $t9     # addr = RM + offset
    s.d  $f0, 0($t9)       # store value

    addi $t8, $t8, 1       # j++
    j    inner_loop

next_i:
    addi $t7, $t7, 1       # i++
    j    outer_loop

done:
    jr   $ra


