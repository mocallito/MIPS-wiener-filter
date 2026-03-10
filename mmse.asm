.data
myFloat:	.float 0.0  # Define a float in the data segment
# Function: mmse_array
# Arguments:
#   $a0 = address of first array (true values)
#   $a1 = address of second array (estimated values)
#   $a2 = length of arrays (integer)
# Returns:
#   $f0 = mean squared error (float)
.text
.globl mmse_array
mmse_array:
    l.s   $f0, myFloat          # initialize sum = 0.0
    move   $t0, $zero        # index i = 0

loop_start:
    beq    $t0, $a2, loop_end   # if i == length, exit loop

    # Load float from array1 and array2
    sll    $t1, $t0, 2          # offset = i * 4 (word size)
    add    $t2, $a0, $t1
    add    $t3, $a1, $t1
    lwc1   $f12, 0($t2)         # load true[i]
    lwc1   $f13, 0($t3)         # load est[i]

    # diff = true[i] - est[i]
    sub.s  $f2, $f12, $f13

    # diff^2
    mul.s  $f4, $f2, $f2

    # sum += diff^2
    add.s  $f0, $f0, $f4

    addi   $t0, $t0, 1          # i++
    j      loop_start

loop_end:
    # Convert length (int) to float
    mtc1   $a2, $f6
    cvt.s.w $f6, $f6

    # mse = sum / length
    div.s  $f0, $f0, $f6

    jr     $ra
