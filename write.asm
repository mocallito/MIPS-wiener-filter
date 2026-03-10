.text
.globl write_to_file

# Function: write_to_file
# Arguments:
#   $a0 -> address of filename string
#   $a1 -> address of content string
#   $a2 -> length of content (bytes)
# Returns:
#   $v0 = 1 (success), 0 (failure)

write_to_file:
    # Save content pointer before overwriting $a1
    move $t8, $a1       # keep content address safe
    move $t9, $a2       # keep length safe

    # Open file (syscall 13)
    li $v0, 13
    move $a0, $a0       # filename
    li $a1, 1           # write-only flag
    li $a2, 0           # mode (unused)
    syscall
    bltz $v0, error     # if fd < 0, error
    move $t0, $v0       # save file descriptor

    # Write to file (syscall 15)
    li $v0, 15
    move $a0, $t0       # fd
    move $a1, $t8       # content pointer
    move $a2, $t9       # length
    syscall
    bltz $v0, error     # if write failed, error

    # Close file (syscall 16)
    li $v0, 16
    move $a0, $t0
    syscall

    # Return success
    li $v0, 1
    jr $ra

error:
    li $v0, 0
    jr $ra


