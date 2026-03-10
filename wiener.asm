.text
.globl wiener_filter
wiener_filter:
    # Compute denominator = signal_var + noise_var
    add.s $f16, $f12, $f14

    # Compute H = signal_var / denominator
    div.s $f18, $f12, $f16   # f18 = H

    # Loop setup
    move $t5, $a0            # input pointer
    move $t6, $a1            # output pointer
    move $t7, $a2            # n
    li   $t8, 0              # i = 0

loop_wiener:
    beq  $t8, $t7, end_wiener

    # Load input[i]
    l.s  $f4, 0($t5)

    # Multiply by H
    mul.s $f6, $f4, $f18

    # Store result in output[i]
    s.s  $f6, 0($t6)

    # Increment pointers and counter
    addi $t5, $t5, 4
    addi $t6, $t6, 4
    addi $t8, $t8, 1

    j loop_wiener

end_wiener:
    jr $ra

