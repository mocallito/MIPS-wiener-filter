# Arguments:
#   $a0 = address of float array
#   $a1 = number of floats
#   $a2 = address of output buffer
# Returns:
#   buffer filled with "x.y, x.y, ..."
# Clobbers: $t0-$t4, $f12
.text
.globl convert_all

convert_all:
    move $t0, $a0        # pointer to float array
    move $t1, $a1        # number of floats
    move $t2, $a2        # write pointer into buffer

loop_start:
    beq  $t1, $zero, done     # if count == 0, exit

    # load float into $f12
    l.s  $f12, 0($t0)
    
    # --- Save $ra before nested call ---
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # call float_to_string($f12, $t2)
    move $a0, $t2
    jal  float_to_string

    # --- Restore $ra after call ---
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    
    # advance $t2 to end of written string
advance_ptr:
    lb   $t3, 0($t2)
    beq  $t3, $zero, after_string
    addi $t2, $t2, 1
    j    advance_ptr

after_string:
    addi $t0, $t0, 4          # next float
    addi $t1, $t1, -1         # decrement count

    # if more floats remain, append comma+space
    beq  $t1, $zero, loop_start
    li   $t4, ','
    sb   $t4, 0($t2)
    addi $t2, $t2, 1
    li   $t4, ' '
    sb   $t4, 0($t2)
    addi $t2, $t2, 1

    j    loop_start

done:
    sb   $zero, 0($t2)        # final null terminator
    jr   $ra

