.data
filename_in:      .asciiz "input.txt"
filename_desired: .asciiz "desired.txt"
filename_out:     .asciiz "output.txt"
success_msg:      .asciiz "Write operation succeeded!\n"
failure_msg:      .asciiz "Write operation failed!\n"
buffer_in:      .space 100        # buffer for input.txt
buffer_desired: .space 100        # buffer for desired.txt
buffer_result:    .space 400        # space to store string result
buffer_mmse:  .space 32
.align 3
array1:     .space 80   # space for 10 double (8 bytes each)
array2:     .space 80   # space for 10 double (8 bytes each)
mmse_double_buf: .space 8
mmse_float_buf: .space 4
# buffer to hold Wiener filter output
array_filt:   .space 100       # 10 double (8 bytes each)
length:       .word 10
M:              .word 10         # filter length

signal_var:   .float 2.0
noise_var:    .float 0.5

.text
.globl main

main:
        # --- Read input.txt ---
    la $a0, filename_in
    la $a1, buffer_in
    li $a2, 100
    jal read_file
    move $t1, $v0

    # Convert string → floats
    la   $a0, buffer_in
    la   $a1, array1
    jal  convert_all_floats

    # Convert floats → doubles
    la   $a0, array1              # source float array
    # allocate double array for input
    lw   $a2, length
    sll  $t0, $a2, 3              # n*8 bytes
    li   $v0, 9
    move $a0, $t0
    syscall
    move $s3, $v0                 # input_doubles pointer
    la   $a0, array1              # input floats
    move $a1, $s3                 # output doubles
    lw   $a2, length
    jal  convert_float_to_double

    # --- Read desired.txt ---
    la $a0, filename_desired
    la $a1, buffer_desired
    li $a2, 100
    jal read_file
    move $t2, $v0

    # Convert string → floats
    la   $a0, buffer_desired
    la   $a1, array2
    jal  convert_all_floats

    # Convert floats → doubles
    lw   $a2, length
    sll  $t1, $a2, 3
    li   $v0, 9
    move $a0, $t1
    syscall
    move $s4, $v0                 # desired_doubles pointer
    la   $a0, array2              # input floats
    move $a1, $s4                 # output doubles
    lw   $a2, length
    jal  convert_float_to_double

    # --- Call LMS Wiener filter ---
    move $a0, $s4      # d[] doubles
    move $a1, $s3      # x[] doubles
    lw   $a2, length
    lw   $a3, M
    jal  lms_filter
    lw   $s0, 0($v0)   # y (double array)
    lw   $s1, 4($v0)   # rdx
    lw   $s2, 8($v0)   # h

    # --- Convert Wiener output doubles → floats ---
    move $a0, $s0                  # input doubles
    la   $a1, array_filt           # output floats
    lw   $a2, length
    jal  convert_double_to_float

    # --- Convert floats → string ---
    la   $a0, array_filt           # float array
    lw   $a1, length
    la   $a2, buffer_result
    jal  convert_all

# --- Find end of buffer_result ---
    la $t0, buffer_result
find_end:
    lb $t1, 0($t0)
    beq $t1, $zero, end_found
    addi $t0, $t0, 1
    j find_end
end_found:

# --- Insert newline separator ---
    li $t1, 10          # ASCII '\n'
    sb $t1, 0($t0)
    addi $t0, $t0, 1
    sb $zero, 0($t0)

    # --- Call MMSE with filtered array and array_est ---
    lw   $a0, length      # N
    lw   $a1, M           # M
    move   $a2, $s4      # d[]
    move $a3, $s1         # rdx

    # Push h_opt onto stack
    move $t9, $s2
    addi $sp, $sp, -8
    sw   $t9, 0($sp)

    jal  mmse_func        # returns MSE in $f0
    addi $sp, $sp, 8
    mov.d $f12, $f0
    li $v0, 3
    syscall

        # Store MMSE result (double) into buffer
    sdc1 $f0, mmse_double_buf

    # Convert double → float
    la   $a0, mmse_double_buf   # input double array
    la   $a1, mmse_float_buf    # output float array
    li   $a2, 1                 # only 1 element
    jal  convert_double_to_float

    # Load float back and convert to string
    la   $a0, buffer_mmse       # destination string buffer
    lwc1 $f12, mmse_float_buf   # load float result
    jal  float_to_string

    # --- Append MMSE string ---
    la   $t0, buffer_result
find_end1:
    lb   $t1, 0($t0)
    beq  $t1, $zero, copy_mmse
    addi $t0, $t0, 1
    j    find_end1
copy_mmse:
    la   $t2, buffer_mmse
copy_loop:
    lb   $t3, 0($t2)
    beq  $t3, $zero, copy_done
    sb   $t3, 0($t0)
    addi $t0, $t0, 1
    addi $t2, $t2, 1
    j    copy_loop
copy_done:
    sb   $zero, 0($t0)
    

    # --- Write to file ---
    la   $a0, filename_out
    la   $a1, buffer_result
    la   $t1, buffer_result     # load base address into a register
    sub  $a2, $t0, $t1   # length = end - start
    jal  write_to_file

    # --- Print success/failure ---
    beq $v0, $zero, print_fail
    la $a0, success_msg
    li $v0, 4
    syscall
    j exit

print_fail:
    la $a0, failure_msg
    li $v0, 4
    syscall

exit:
    li $v0, 10
    syscall
