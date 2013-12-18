# Final Project Test Code
# Shivam Desai, Kris Groth, Sarah Strohkorb, Eric Westman

# Load the value of 1 and 2 from memory into registers $t1 and $t2 respectively
#lw $t1, 1021
#lw $t2, 1022

li $t1, 1
li $t2, 2

# xor the value stored in $t1 (1) with 99
# expected output: 98
xori $t3, $t1, 99

# $t1 + $t2 = 1 + 2 = 3, stored in $t4
add $t4, $t1, $t2

# $t4 - $t1 = 3 - 1 = 2, stored in $t5
sub $t5, $t4, $t1

# ($t1 < $t5) = (1 < 2 )= 1, stored into $t6
slt $t6, $t1, $t5

# if $t1 != $t1 (1 != 1) go to the jumpelseif 
# because (1 != 1) is false, we'll do the $t1 + $t2 = 1 + 2 = 3, stored in $t7
# then we'll jump to the end
bne $t1, $t2, jumpelseif
	add $t7, $t1, $t2
jumpelseif:
add $t9, $t2, $t1

add $t8, $t2, $t1
jal here
add $s0, $t2, $t1
here:
add $s1, $t2, $t1

# A test of the difference function
# difference(8, 4) = 4
#li $s0, 8	# first input
#li $s1, 4	# second input
#li $sp, 1020	# set the stack pointer to a specific location in memory
#jal difference
#li $v0, 10
#syscall

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
#difference:
#bne $s0, $s1, end
#	# return 0
#	add $v1, $zero, $zero
#	jr $ra
#end:
#	# pushing to the stack
#	sub $sp, $sp, $t4
#	sw $ra, 2($sp)
#	sw $s1, 1($sp)
#	sw $s0 0($sp)
#	
#	# Argument prep (a - 1)
#	sub $s0, $s0, $t1
#	
#	# jal
#	jal difference
#	
#	# popping from the stack
#	lw $s1, 1($sp)
#	lw $s0, 0($sp)
#	add $sp, $sp, $t4
#	
#	# return 1 + difference($t1 , $t2)
#	add $v1, $v1, $t1
#	jr $ra
