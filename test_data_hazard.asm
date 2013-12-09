# Final Project Test Code
# Shivam Desai, Kris Groth, Sarah Strohkorb, Eric Westman

# Load the value of 1 and 2 from memory into registers $t1 and $t2 respectively
#lw $t1, 1021
#lw $t2, 1022
li $t1, 1
li $t2, 2

li $t3, 0
li $t4, 0
li $t5, 0

#li $t1, 1
#li $t2, 2

# wait to make sure lw $t1 is written
#li $a0, 1
#li $a0, 2
#li $a0, 3

add $t3, $t2, $t1
add $t4, $t3, $t2
add $t5, $t4, $t3

