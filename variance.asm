# double variance(double *signal, int No)
# Arguments: signal in $a0, No in $a1
# Return: variance in $f0
.data
const: .double 0.0
.text
.globl variance

# variance(double *signal, int No)
variance:
    l.d   $f2, const          # mean accumulator
    l.d   $f4, const          # var accumulator
    li     $t9, 0            # i = 0

mean_loop:
    beq    $t9, $a1, mean_done
    sll    $t8, $t9, 3       # offset = i * 8
    add    $t7, $a0, $t8
    l.d    $f6, 0($t7)       # signal[i]
    add.d  $f2, $f2, $f6
    addi   $t9, $t9, 1
    j      mean_loop

mean_done:
    mtc1   $a1, $f8
    cvt.d.w $f8, $f8
    div.d  $f2, $f2, $f8     # mean /= No

    li     $t9, 0

var_loop:
    beq    $t9, $a1, var_done
    sll    $t8, $t9, 3
    add    $t7, $a0, $t8
    l.d    $f6, 0($t7)
    sub.d  $f6, $f6, $f2
    mul.d  $f6, $f6, $f6
    add.d  $f4, $f4, $f6
    addi   $t9, $t9, 1
    j      var_loop

var_done:
    div.d  $f0, $f4, $f8     # var /= No
    jr     $ra
