.text
.globl read_file
# read_file(filename, buffer, size)
# Arguments:
#   $a0 = address of filename string
#   $a1 = buffer address
#   $a2 = buffer size
# Returns:
#   $v0 = number of bytes read
read_file:
    # Save content pointer and length before overwriting
    move $t8, $a1       # keep buffer address safe
    move $t9, $a2       # keep length safe

    # Open file (read-only)
    li $v0, 13
    li $a1, 0           # read-only
    syscall
    move $t6, $v0       # fd

    # Read file
    li $v0, 14
    move $a0, $t6
    move $a1, $t8       # restore buffer address
    move $a2, $t9       # restore buffer size
    syscall
    move $t5, $v0       # bytes read
add $t5, $t5, 1
    # Append null terminator
    add $t7, $t8, $t5   # buffer address + bytes read
    sb $zero, 0($t7)    # store 0 at end

    # Close file
    li $v0, 16
    move $a0, $t6
    syscall

    move $v0, $t5       # return bytes read
    jr $ra

