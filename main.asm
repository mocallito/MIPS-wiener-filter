.data
filename_in:      .asciiz "input.txt"
filename_desired: .asciiz "desired.txt"
filename_out:     .asciiz "output.txt"
success_msg:      .asciiz "MSE written successfully!\n"
failure_msg:      .asciiz "Write operation failed!\n"
buffer_in:      .space 100        # buffer for input.txt
buffer_desired: .space 100        # buffer for desired.txt
buffer_result:    .space 400        # space to store string result
buffer_mmse:  .space 32
length:       .word 10
.align 2
array1:     .space 40   # space for 10 floats (4 bytes each)
array2:     .space 40   # space for 10 floats (4 bytes each)
# buffer to hold Wiener filter output
array_filt:   .space 40       # 10 floats (4 bytes each)

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
    move $t1, $v0             # bytes read from input.txt
    # Load address of the string into $a0
    la   $a0, buffer_in

    # Load address of results into $a1
    la   $a1, array1

    # Call convert_all_floats
    jal  convert_all_floats

    # --- Read desired.txt ---
    la $a0, filename_desired
        la $a1, buffer_desired
    li $a2, 100
    jal read_file
    move $t2, $v0             # bytes read from input.txt
    # Load address of the string into $a0
    la   $a0, buffer_desired

    # Load address of results into $a1
    la   $a1, array2

    # Call convert_all_floats
    jal  convert_all_floats

    # --- Call Wiener filter ---
    la   $a0, array1      # input pointer
    la   $a1, array_filt      # output pointer
    lw   $a2, length          # length
    la   $t0, signal_var
    lwc1 $f12, 0($t0)         # signal_var
    la   $t3, noise_var
    lwc1 $f13, 0($t3)         # noise_var
    jal  wiener_filter        # fills array_filt

    # --- Convert Wiener output to string ---
    la   $a0, array_filt
    li   $a1, 10
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
    sb $zero, 0($t0)    # null terminate again

# --- Call MMSE with filtered array and array_est ---
    la $a0, array_filt           # first array
    la $a1, array2           # second array
    lw $a2, length           # assume same length as input.txt
    jal mmse_array           # returns MSE in $f0

# Call float_to_string
    la $a0, buffer_mmse    # buffer address
    mov.s $f12, $f0          # pass float in $f12
    jal float_to_string

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