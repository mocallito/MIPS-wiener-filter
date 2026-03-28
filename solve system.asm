.text
.globl solve_system

# void solve_system(double **RM, double *gamma_d, double *h, int M)
# Arguments:
# $a0 = RM base address (flattened matrix)
# $a1 = gamma_d base address
# $a2 = h base address
# $a3 = M (matrix size)

solve_system:
    # --- Forward Elimination ---
    li $t4, 0                  # k = 0
fe_outer_loop:
    add $t9, $a3, -1           # M-1
    bge $t4, $t9, fe_done      # if k >= M-1, done

    addi $t5, $t4, 1           # i = k+1
fe_inner_loop:
    bge $t5, $a3, fe_outer_continue

    #### factor = RM[i][k] / RM[k][k] ####
    mul $t8, $t5, $a3          # i*M
    add $t8, $t8, $t4          # i*M + k
    sll $t8, $t8, 3
    add $t8, $a0, $t8
    l.d $f2, 0($t8)            # f2 = RM[i][k]

    mul $t9, $t4, $a3          # k*M
    add $t9, $t9, $t4          # k*M + k
    sll $t9, $t9, 3
    add $t9, $a0, $t9
    l.d $f4, 0($t9)            # f4 = RM[k][k]

    div.d $f2, $f2, $f4        # factor = f2 / f4

    #### for j = k; j < M; j++ ####
    move $t6, $t4
fe_j_loop:
    bge $t6, $a3, fe_j_done

    mul $t7, $t5, $a3
    add $t7, $t7, $t6
    sll $t7, $t7, 3
    add $t7, $a0, $t7
    l.d $f4, 0($t7)            # f4 = RM[i][j]

    mul $t9, $t4, $a3
    add $t9, $t9, $t6
    sll $t9, $t9, 3
    add $t9, $a0, $t9
    l.d $f12, 0($t9)           # f12 = RM[k][j]

    mul.d $f12, $f2, $f12
    sub.d $f12, $f4, $f12
    s.d $f12, 0($t7)

    addi $t6, $t6, 1
    j fe_j_loop
fe_j_done:

    #### gamma_d[i] -= factor * gamma_d[k] ####
    sll $t9, $t5, 3
    add $t9, $a1, $t9
    l.d $f16, 0($t9)

    sll $t8, $t4, 3
    add $t8, $a1, $t8
    l.d $f18, 0($t8)

    mul.d $f18, $f2, $f18
    sub.d $f18, $f16, $f18
    s.d $f18, 0($t9)

    addi $t5, $t5, 1
    j fe_inner_loop

fe_outer_continue:
    addi $t4, $t4, 1
    j fe_outer_loop

fe_done:

    # --- Back Substitution ---
    add $t4, $a3, $zero
    addi $t4, $t4, -1          # i = M-1

bs_outer_loop:
    bltz $t4, bs_done

    #### h[i] = gamma_d[i] ####
    sll $t6, $t4, 3
    add $t6, $a1, $t6
    l.d $f2, 0($t6)

    sll $t9, $t4, 3
    add $t9, $a2, $t9
    s.d $f2, 0($t9)

    #### for j = i+1; j < M; j++ ####
    addi $t5, $t4, 1
bs_inner_loop:
    bge $t5, $a3, bs_inner_done

    mul $t8, $t4, $a3
    add $t8, $t8, $t5
    sll $t8, $t8, 3
    add $t8, $a0, $t8
    l.d $f4, 0($t8)            # f4 = RM[i][j]

    sll $t9, $t5, 3
    add $t9, $a2, $t9
    l.d $f2, 0($t9)            # f2 = h[j]

    mul.d $f4, $f4, $f2

    sll $t9, $t4, 3
    add $t9, $a2, $t9
    l.d $f12, 0($t9)           # f12 = h[i]

    sub.d $f12, $f12, $f4
    s.d $f12, 0($t9)

    addi $t5, $t5, 1
    j bs_inner_loop
bs_inner_done:

    #### h[i] /= RM[i][i] ####
    sll $t7, $t4, 3
    add $t7, $a2, $t7
    l.d $f12, 0($t7)

    mul $t9, $t4, $a3
    add $t9, $t9, $t4
    sll $t9, $t9, 3
    add $t9, $a0, $t9
    l.d $f16, 0($t9)

    div.d $f18, $f12, $f16
    s.d $f18, 0($t7)

    addi $t4, $t4, -1
    j bs_outer_loop

bs_done:
    jr $ra

