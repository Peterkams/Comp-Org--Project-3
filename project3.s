.data		#Data declaration section
my_string:	.space 3000
too_long:	.asciiz "Input is too long."
invalid_spaces:	.asciiz "Invalid base-36 number."
empty_string_error: .asciiz "Input is empty."

.text		#Assembly language instruction
.globl main

main:
	li $v0, 8	#takes user input
	la $a0, my_string
	syscall

	la $t0, my_string	#loaded the address of the string
	li $t2, 0 	#initialized i= 0
	li $t3, 32 	#loaded space here
	li $s0, 0	#initialized previous character to 0
	li $t5, 0	#initialized num_of_chracters
	li $t6, 0x0A	#loaded new line here
	li $t7, 0	#number of spaces in front( used for during calculation)

loop:
	lb $t1, 0($t0)		#got a character of the string
	beq $t1, $t6, break_loop	#break when the current character is a newline

	beq $t1, $t3, dont_print_invalid_spaces		#if the character is not a space and
	bne $s0, $t3, dont_print_invalid_spaces		#if the previous character is a space and
	beq $t5, $0, dont_print_invalid_spaces		#if the num of previously seen characters is not zero and
	beq $t1, $0, dont_print_invalid_spaces		#if the chLaracter is not null and 
	beq $t1, $t6, dont_print_invalid_spaces		#if the character is not new line then print invalid 	
	
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
	syscall		#print invalid spaces
	jr $ra	
dont_print_invalid_spaces:

	beq $t1, $t3, dont_incr_num_of_characters	#if character is not equal to a space, increment num_of_characters
	addi $t5, $t5, 1
dont_incr_num_of_characters:

	bne $t1, $t3, dont_count_space		#if current character is a space and
	bne $t5, $0, dont_count_space		#if num of previous character is equal to 0 then count space
	addi $t7, $t7, 1
dont_count_space:


	move $s0, $t1		#set previous character with current one
	addi $t0, $t0, 1	#incremented the address
	addi $t2, $t2, 1	#incremented i
	j loop
break_loop:

	li $t1, 4
	ble $t5, $t1, dont_print_too_long 	#checks if user input is greater than 4
	li $v0, 4
	la $a0, too_long
	syscall		#printed too long error for the input
	jr $ra
dont_print_too_long:

	bne $t5, $zero, dont_print_empty_string_error	#if user input is empty, and
	beq $t1, $t6, dont_print_empty_string_error     #if user input is a newline print invalid
	li $v0, 4
	la $a0, empty_string_error
	syscall
	jr $ra
dont_print_empty_string_error:


#about to overwrite all the registers apart from $t5- len(numofcharacters and $t7- numofspaces in front)

	li $t0, 0	#initialized i here
	addi $t1, $t5, -1	#initialized j(length-1)
	la $s0, my_string	#got the string address
	add $s0, $s0, $t7	#got the address of the start of the number
	add $s0,$s0, $t1	#add length -1 to the address(starts from the end)
	li $t4, 1 	#initialized power of 36
	li $t9, 0	#initialized sum of decimal value
	li $s3, 36	#constant of 36

convert_next_digit_loop:
	li $t8, -1	#initialized the digit to -1
	lb $s1, 0($s0)	
	li $t2, 65	#smallest ascii value for capital letters
	li $t3, 90	#biggest ascii value for capital letters

	blt $s1, $t2, dont_convert_capital_letter_to_digit 	#if ascii[j] >= 65 and
	bgt $s1, $t3, dont_convert_capital_letter_to_digit      #if ascii[j] <= 90
	addi $t8, $s1, -55 	#got the decimal value of the capital letter
dont_convert_capital_letter_to_digit:

	li $t2, 97	#smallest ascii value for lowercase letters
	li $t3, 122	#biggest ascii value for lowercase letters

	blt $s1, $t2, dont_convert_lowercase_letter_to_digit 	#if ascii[j] >= 97 and
	bgt $s1, $t3, dont_convert_lowercase_letter_to_digit     #if ascii[j] <= 122
	addi $t8, $s1, -87 	#got the decimal value of the capital letter
dont_convert_lowercase_letter_to_digit:

	li $t2, 48	#smallest ascii value for capital letters
	li $t3, 57	#biggest ascii value for capital letters

	blt $s1, $t2, dont_convert_digit_to_digit 	#if ascii[j] >= 48 and
	bgt $s1, $t3, dont_convert_digit_to_digit       #if ascii[j] <= 57
	addi $t8, $s1, -48	#got the decimal value of the capital letter
dont_convert_digit_to_digit:

	li $s4, -1	#initialized -1 in $s4
	bne $t8, $s4, dont_print_invalid_symbol	#if $t8 is -1 then print invalid_spaces 
	li $v0, 4
	la $a0, invalid_spaces 
	syscall
	jr $ra
dont_print_invalid_symbol:

	mul $s2, $t8, $t4 	#value = digit * power_of_36
	mul $t4, $t4, $s3	#power_of_base *= 36
	add $t9, $t9, $s2	#sum+= value


	addi $t0, $t0, 1	#incremented i
	addi $t1, $t1, -1	#decremented j
	addi $s0, $s0, -1	#incremented the address to get the next character
	blt $t0, $t5, convert_next_digit_loop

	li $v0, 1
	move $a0, $t9
	syscall		#prints sum of the decimal value



	jr $ra
