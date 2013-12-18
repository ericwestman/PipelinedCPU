# Final Project Test Code
# Shivam Desai, Kris Groth, Sarah Strohkorb, Eric Westman

# Load the value of 1 and 2 from memory into registers $t1 and $t2 respectively
#lw $t1, 1021
#lw $t2, 1022

li $t1, 1			# 0
li $t2, 2			# 1

# xor the value stored in $t1 (1) with 99
# expected output: 98	
xori $t3, $t1, 99		# 2

# $t1 + $t2 = 1 + 2 = 3, stored in $t4
add $t4, $t1, $t2		# 3

# $t4 - $t1 = 3 - 1 = 2, stored in $t5
sub $t5, $t4, $t1		# 4

# ($t1 < $t5) = (1 < 2 )= 1, stored into $t6
slt $t6, $t1, $t5		# 5

# if $t1 != $t5 (1 != 1) go to the jumpelseif 
# because (1 != 1) is false, we'll do the $t1 + $t2 = 1 + 2 = 3, stored in $t7
# then we'll jump to the end
bne $t1, $t5, jumpelseif	# 6
        add $t7, $t1, $t2	# 7
        j jumpend		# 8
jumpelseif:
        sub $t8, $t2, $t1	# 9 
jumpend:

# A test of the difference function
# difference(8, 4) = 4
li $s0, 8	# first input	# a
li $s1, 4	# second input	# b
li $sp, 1020	# set the stack pointer to a specific location in memory
jal difference			# d
li $v0, 10			# e
syscall				# f

# FUNCTION: difference(a, b)
# Returns (a - b)
# Assumption: a > b
# 
# Executes recursively (below is the psudocode)
#   function difference (a, b)
#   if a == b
#       return 0
#   else
#       return 1 + difference(a - 1 , b)
difference:
bne $s0, $s1, end		# 10
	# return 0
	add $v1, $zero, $zero	# 11
	li $t9, 1		# 12
	jr $ra			# 13
end:
	# pushing to the stack
	sub $sp, $sp, $t4	# 14
	sw $ra, 2($sp)		# 15
	sw $s1, 1($sp)		# 16
	sw $s0, 0($sp)		# 17
	
	# Argument prep (a - 1)
	sub $s0, $s0, $t1	# 18 
	
	# jal
	li $t9, 1		# 19
	li $t9, 1		# 20/1A
	jal difference		# 21/1B
	
	# popping from the stack
	lw $ra, 2($sp)		# 
	lw $s1, 1($sp)		# 
	lw $s0, 0($sp)		# 
	add $sp, $sp, $t4	# 
	
	# return 1 + difference($t1 , $t2)
	add $v1, $v1, $t1	# 
	jr $ra			# 
