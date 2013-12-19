# Final Project Test Code
# Can be assembled and run in MARS
# Shivam Desai, Kris Groth, Sarah Strohkorb, Eric Westman

# Load the value of 1 and 2 from memory into registers $t1 and $t2 respectively
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

# if $t1 != $t5 (1 != 2) go to the jumpelseif 
# because (1 != 2) is false, we'll do the $t2 - $t1 = 2 - 1 = 1, stored in $t8
# then we'll jump to the end
bne $t1, $t5, jumpelseif
        add $t7, $t1, $t2
        j jumpend
jumpelseif:
        sub $t8, $t2, $t1
jumpend:

# A test to see if the jal (jump and link) jumps, does not test linking
jal jumping_maybe_linking	
li $t9, 10	# a meaningless isntruction to show that it is skipped (by the jal) ($t9 should be 0)
jumping_maybe_linking:
li $s0, 5	# this line should be executed, so $s0 should be 5
