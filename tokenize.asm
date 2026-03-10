.text
.globl convert_all_floats
########################################################
# convert_all_floats
# Input: $a0 = address of string (null-terminated)
#        $a1 = address of results buffer
# Output: results stored sequentially in 'results'
########################################################
convert_all_floats:
    move $t3, $a1            # pointer to output array

next_token:
    lb   $t2, 0($a0)         # current char
    beq  $t2, 0, conv_done   # end of string
    beq  $t2, ' ', skip_space

    # --- Save $ra before nested call ---
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # Call manual_string_to_float
    jal  manual_string_to_float

    # --- Restore $ra after return ---
    lw   $ra, 0($sp)
    addi $sp, $sp, 4

    # Store result
    swc1 $f0, 0($t3)
    addi $t3, $t3, 4         # advance results pointer

    # Advance until space or end
advance:
    lb   $t2, 0($a0)
    beq  $t2, 0, conv_done
    beq  $t2, ' ', skip_space
    addi $a0, $a0, 1
    j    advance

skip_space:
    addi $a0, $a0, 1
    j    next_token

conv_done:
    jr   $ra

