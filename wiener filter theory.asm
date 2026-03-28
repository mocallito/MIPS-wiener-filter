.data
# Globals used internally by lms_filter
rdx:  .space 80          # space for 10 doubles
rxx:  .space 80          # space for 10 doubles
h:    .space 80          # 10 doubles
y:    .space 80          # 10 doubles
RM:   .space 900          # 10x10 doubles
results: .space 24   # space for 3 words (addresses)

.text
.globl lms_filter

# Arguments:
# a0 = address of d[]
# a1 = address of x[]
# a2 = N
# a3 = M
# Return: v0 = address of y[]
lms_filter:
addi $sp, $sp, -4
    sw   $ra, 0($sp)
    # Save arguments
    move $s0, $a0   # d
    move $s1, $a1   # x
    move $s2, $a2   # N
    move $s3, $a3   # M

    #### Cross-correlation
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    la   $a3, rdx
    addi $sp, $sp, -8
    sw   $s3, 0($sp)
    jal  crosscorr
    addi $sp, $sp, 8

    #### Auto-correlation
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    la   $a3, rxx
    addi $sp, $sp, -8
    sw   $s3, 0($sp)
    jal  autocorr
    addi $sp, $sp, 8

    #### Build Toeplitz
    move $a0, $s3
    la   $a1, rxx
    la   $a2, RM
    jal  build_toeplitz

    #### Solve system
    la $a0, RM
    la $a1, rdx
    la $a2, h
    move $a3, $s3
    jal solve_system

        #### Filter
    la   $a0, h          # h[] base → $a0
    move $a1, $s1        # x[] base → $a1
    la   $a2, y          # y[] base → $a2
    move $a3, $s3        # M → $a3

    # push N onto stack
    addi $sp, $sp, -4
    sw   $s2, 0($sp)     # N → stack

    jal  filter

    # pop stack
    addi $sp, $sp, 4



    la $t6, y
    la $t7, rdx
    la $t8, h
    la $t9, results
    sw $t6, 0($t9)
    sw $t7, 4($t9)
    sw $t8, 8($t9)
    move $v0, $t9    # return pointer to results[]
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

