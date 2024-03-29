.data           #Data declaration section
my_string:      .space 3000
too_long:       .asciiz "Input is too long."
invalid_spaces: .asciiz "Invalid base-36 number."
print_invalid: .asciiz "Invalid base-36 number."
empty_string_error: .asciiz "Input is empty."

.text           #Assembly language instruction
.globl main

main:
        li $v0, 8       #takes user input
        la $a0, my_string
        syscall

        la $t0, my_string       #loaded the address of the string
        li $t2, 0       #initialized i= 0
        li $t3, 32      #loaded space here
        li $s0, 0       #initialized previous character to 0
        li $t5, 0       #initialized num_of_chracters
        li $t6, 0x0A    #loaded new line here
        li $t7, 0       #number of spaces in front( used for during calculation)

loop:
        lb $t1, 0($t0)          #got a character of the string
        beq $t1, $t6, break_loop        #break when the current character is a newline

        beq $t1, $t3, dont_print_invalid_spaces         #if the character is not a space and
        bne $s0, $t3, dont_print_invalid_spaces         #if the previous character is a space and
        beq $t5, $0, dont_print_invalid_spaces          #if the num of previously seen characters is not zero and
        beq $t1, $0, dont_print_invalid_spaces          #if the chLaracter is not null and
        beq $t1, $t6, dont_print_invalid_spaces         #if the character is not new line then print invalid

	#if invalid spaces and too long: print too long instead
	#so if i - num_spaces_before_characters > 4: print too long
	sub $t0, $t2, $t7      #t0 = i - num_spaces_in_front
	addi $t0, $t0, 1	#t0++ since i is the index and not the length
	li $t1, 4    #t1 = 4
	ble $t0, $t1, dont_print_too_long_instead_of_invalid_spaces
        li $v0, 4
        la $a0, too_long
        syscall         #printed too long error for the input
        jr $ra	
dont_print_too_long_instead_of_invalid_spaces:

        li $v0, 4
        la $a0, invalid_spaces
        syscall         #print invalid spaces
        jr $ra
dont_print_invalid_spaces:

        beq $t1, $t3, dont_incr_num_of_characters       #if character is not equal to a space, increment num_of_characters
        addi $t5, $t5, 1
dont_incr_num_of_characters:

        bne $t1, $t3, dont_count_space          #if current character is a space and
        bne $t5, $0, dont_count_space           #if num of previous character is equal to 0 then count space
        addi $t7, $t7, 1
dont_count_space:


        move $s0, $t1           #set previous character with current one
        addi $t0, $t0, 1        #incremented the address
        addi $t2, $t2, 1        #incremented i
        j loop
break_loop:

        li $t1, 4
        ble $t5, $t1, dont_print_too_long       #checks if user input is greater than 4
        li $v0, 4
        la $a0, too_long
        syscall         #printed too long error for the input
        jr $ra
dont_print_too_long:

        bne $t5, $zero, dont_print_empty_string_error   #if user input is empty, and
        beq $t1, $t6, dont_print_empty_string_error     #if user input is a newline print invalid
        li $v0, 4
        la $a0, empty_string_error
        syscall
        jr $ra
dont_print_empty_string_error:

#about to overwrite all the registers apart from $t5- len(numofcharacters and $t7- numofspaces in front)
        la $s0, my_string       #got the string address
        add $s0, $s0, $t7       #got the address of the start of the number

	addi $sp, $sp, -4  #allocate space
	sw $ra, 0($sp)  #store return address

	addi $sp, $sp, -8
	sw $s0, 0($sp)  #set addr of start of number
	sw $t5, 4($sp)  #set length of number
	jal converter
	#move $t0, $v0
	lw $t0, 0($sp)
	addi $sp, $sp, 4

	li $v0, 1    #print res
	move $a0, $t0
	syscall
	
	lw $ra, 0($sp)  #restore return address
	addi $sp, $sp, 4 #deallocated space

	jr $ra

converter:
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 8  #deallocate space for parameters

	addi $sp, $sp, -20  #allocate space
	sw $ra, 0($sp)  #store return address
	sw $s0, 4($sp)  #store s0  = used for address of arr
	sw $s1, 8($sp)  #store s1  = used for length arr
	sw $s2, 12($sp)  #store s2  = used for first num
	sw $s3, 16($sp)  #store s3  = used for power of 36

	#transfer args to s-registers
	move $s0, $a0  #address of array
	move $s1, $a1  #length of array

	#base case
	li $t0, 1
	bne $s1, $t0, dont_get_number	#if length == 1 then
	lb $t1, 0($s0)			#loads the first element of the array

	move $a0, $t1	#set char to arg for char_to_digit function
	jal char_to_digit
	move $t1, $v0  #get result

	move $t0, $t1			#put the first element in $t0, before it's put on the stack to be returned
	j exit_converter
dont_get_number:

	addi $s1, $s1, -1  #length--

	move $a0, $s1  #set args for power_ts
	jal power_ts
	move $s3, $v0  # get res t0 = 36 ^ (len-1)

	lb $t0, 0($s0) #loads the first element of the array
	move $a0, $t0
	jal char_to_digit
	move $t0, $v0
	mul $s2, $t0, $s3
	addi $s0, $s0, 1  #increment ptr to start of array
	#effectively saying that the array starts at the next element

	#recursive case
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	jal converter
	#move $t0, $v0  #get conversion result
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	add $t0, $s2, $t0  #return conversion res + first num and put the return value in $t0

exit_converter:
	lw $ra, 0($sp)  #restore return address
	lw $s0, 4($sp)  #restore s0  = used for addr of arr
	lw $s1, 8($sp)  #restore s1  = used for length arr
	lw $s2, 12($sp)  #restore s2  = used for first num
	lw $s3, 16($sp)  #store s3  = used for power of 36
	addi $sp, $sp, 20  #deallocate space

	addi $sp, $sp, -4
	sw $t0, 0($sp)

	jr $ra

power_ts:
	addi $sp, $sp, -4 #allocate space
	sw $ra, 0($sp)  #store return address

	li $t0, 0
	bne $a0, $t0, dont_get_power_of_zero
	li $v0, 1
	j exit_power_ts
dont_get_power_of_zero:

	addi $a0, $a0, -1  #setting arg for recursion call
	jal power_ts
	move $t1, $v0 #result in $v0 moved to $t1
	li $t2,36 #first number
	mul $v0, $t2, $t1 #takes the mult result and puts it into $v0
exit_power_ts:
	lw $ra, 0($sp)  #restore return address
	addi $sp, $sp, 4 #deallocated space
	jr $ra

char_to_digit:
	li $t2, 65
	li $t3, 90
	#convert character to digit
        blt $a0, $t2, dont_convert_capital_letter_to_digit      #if char >= 65 and
        bgt $a0, $t3, dont_convert_capital_letter_to_digit      #if char <= 90
        addi $a0, $a0, -55      #got the decimal value of the capital letter
	move $v0, $a0  #return res
	jr $ra
dont_convert_capital_letter_to_digit:
	
        li $t2, 97      #smallest ascii value for lowercase letters
        li $t3, 122     #biggest ascii value for lowercase letters

        blt $a0, $t2, dont_convert_lowercase_letter_to_digit    #if char >= 97 and
        bgt $a0, $t3, dont_convert_lowercase_letter_to_digit     #if char <= 122
        addi $a0, $a0, -87      #got the decimal value of the lowercase letter
	move $v0, $a0
	jr $ra
dont_convert_lowercase_letter_to_digit:

        li $t2, 48      #smallest ascii value for decimals
        li $t3, 57      #biggest ascii value for decimals

        blt $a0, $t2, dont_convert_digit_to_digit	#if char >= 48 and
        bgt $a0, $t3, dont_convert_digit_to_digit       #char <= 57
        addi $a0, $a0, -48      #got the decimal value of the decimal
	move $v0, $a0
	jr $ra
dont_convert_digit_to_digit:

	li $v0, 4	#throw error if character is not in any of the ranges
	la $a0, print_invalid
	syscall

	li $v0, 10	#termination syscall
	syscall
