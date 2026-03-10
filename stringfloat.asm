.text
.globl manual_string_to_float
# manual_string_to_float
# Input: $a0 = address of string
# Output: $f0 = float result
# Clobbers: $t5-$t9, $f2-$f8

manual_string_to_float:
    # Initialize
    li   $t5, 1              # sign = +1
    li   $t6, 0              # int_value = 0
    li   $t7, 0              # frac_value = 0
    li   $t8, 1              # divisor = 1

    lb   $t9, 0($a0)         # first char

    # Skip leading spaces
skip_leading:
    beq  $t9, ' ', skip_lead_advance
    j    check_sign
skip_lead_advance:
    addi $a0, $a0, 1
    lb   $t9, 0($a0)
    j    skip_leading

# Handle sign
check_sign:
    beq  $t9, '-', neg_sign
    beq  $t9, '+', skip_sign
    j    parse_int

neg_sign:
    li   $t5, -1             # sign = -1
    addi $a0, $a0, 1         # skip sign
    j    parse_int

skip_sign:
    addi $a0, $a0, 1         # skip sign
    j    parse_int

# Parse integer part
parse_int:
    lb   $t9, 0($a0)
    beq  $t9, '.', parse_frac
    beq  $t9, 0, combine     # end of string
    beq  $t9, ' ', combine   # space ends number
    beq  $t9, '\n', combine   # space ends number
    beq  $t9, $zero, combine     # end of string
    beqz  $t9, combine     # end of string

    # digit = ord(ch) - ord('0')
    addi $t0, $t9, -48       # reuse $t9 if you want strictness
    blt  $t0, 0, error
    bgt  $t0, 9, error

    mul  $t6, $t6, 10
    add  $t6, $t6, $t0

    addi $a0, $a0, 1
    j    parse_int

# Parse fractional part
parse_frac:
    addi $a0, $a0, 1
frac_loop:
    lb   $t9, 0($a0)
    beq  $t9, ' ', combine   # space ends number
    beq  $t9, '\n', combine   # space ends number
    beq  $t9, 0, combine     # end of string
    beq  $t9, $zero, combine     # end of string
    beqz  $t9, combine     # end of string
    
    addi $t0, $t9, -48
    blt  $t0, 0, error
    bgt  $t0, 9, error

    mul  $t7, $t7, 10
    add  $t7, $t7, $t0
    mul  $t8, $t8, 10

    addi $a0, $a0, 1
    j    frac_loop

# Combine integer and fractional parts
combine:
    mtc1 $t6, $f2            # int_value -> float
    cvt.s.w $f2, $f2

    mtc1 $t7, $f4            # frac_value -> float
    cvt.s.w $f4, $f4

    mtc1 $t8, $f6            # divisor -> float
    cvt.s.w $f6, $f6

    div.s $f4, $f4, $f6      # frac_value / divisor
    add.s $f0, $f2, $f4      # int_value + fraction

    mtc1 $t5, $f8            # sign -> float
    cvt.s.w $f8, $f8
    mul.s $f0, $f0, $f8      # apply sign
    jr   $ra

error:
    move $a0, $t9
    li   $v0, 11             # syscall: print string
    syscall
    li $a0, 54
    li   $v0, 11             # syscall: print string
    syscall
    li   $v0, 10             # exit program
    syscall
