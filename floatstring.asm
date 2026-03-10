.data
decimal:    .float 0.0
myFloat:    .float 100.0   # scaling factor
intbuf: .space 12   # temporary buffer for integer digits

.text
.globl float_to_string

# Arguments:
#   $f12 = float value to convert
#   $a0  = buffer address
# Returns:
#   buffer filled with ASCII string "int.frac"
# Clobbers: $t5-$t9, $f2-$f6

float_to_string:
    # --- Handle sign ---
    l.s $f0, decimal
    c.lt.s $f12, $f0
    bc1f positive
    li   $t5, 1              # mark negative
    neg.s $f12, $f12
    j    sign_done
positive:
    li   $t5, 0
sign_done:

    # --- Integer part ---
    cvt.w.s $f2, $f12
    mfc1 $t6, $f2            # integer part
    mtc1 $t6, $f4
    cvt.s.w $f4, $f4

    # --- Fractional part (scaled by 100) ---
    sub.s $f6, $f12, $f4
    l.s $f1, myFloat
    mul.s $f6, $f6, $f1
    cvt.w.s $f6, $f6
    mfc1 $t7, $f6            # fractional digits (0–99)

    # --- Write sign if needed ---
    beq  $t5, $zero, skip_sign
    li   $t8, '-'
    sb   $t8, 0($a0)
    addi $a0, $a0, 1
skip_sign:

    # --- Convert integer part to string (multi-digit) ---
    # Use intbuf as temporary reverse buffer
    la   $t9, intbuf+11      # end of buffer
    sb   $zero, 0($t9)

int_to_str_loop:
    divu $t6, $t6, 10
    mflo $t6                 # quotient
    mfhi $t8                 # remainder
    addi $t8, $t8, '0'
    addi $t9, $t9, -1
    sb   $t8, 0($t9)
    bne  $t6, $zero, int_to_str_loop

    # Copy digits into output
copy_int:
    lb   $t8, 0($t9)
    beq  $t8, $zero, after_int
    sb   $t8, 0($a0)
    addi $a0, $a0, 1
    addi $t9, $t9, 1
    j    copy_int
after_int:

    # --- Decimal point ---
    li   $t8, '.'
    sb   $t8, 0($a0)
    addi $a0, $a0, 1

    # --- Fractional digits (two digits) ---
    divu $t7, $t7, 10
    mflo $t8
    addi $t8, $t8, '0'
    sb   $t8, 0($a0)
    addi $a0, $a0, 1

    mfhi $t8
    addi $t8, $t8, '0'
    sb   $t8, 0($a0)
    addi $a0, $a0, 1

    # --- Null terminator ---
    sb   $zero, 0($a0)
    jr   $ra