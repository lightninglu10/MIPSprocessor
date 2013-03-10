.global _start
.ent    _start

.data 
failsz:		.asciiz "Test FAILED: "
expect1_str:	.asciiz "Expected: "
expect2_str:	.asciiz ", Got: "

passsz:		.asciiz "All tests passed!\n"

result1_str:	.asciiz "Passed "
result3_str:	.asciiz " tests!\n"

testnum: 	.byte 0
passcount:	.byte 0
numtests:	.byte 0

.align 2
tests:		.asciiz "sll_1  "
		.word slltest1
		.asciiz "sll_2  "
		.word slltest2
		.asciiz "srl_1  "
		.word srltest1
		.asciiz "srl_2  "
		.word srltest2
		.byte 0
.text
_start:
exectest:
	# load base address for test structure into $s0
	addiu $t1, $zero, 12
	mult $t0, $t1
	mflo $t0
	la $t1, tests
	addu $s0, $t0, $t1

	# check to see if the test name is null
	lb $t0, 0($s0)
	beq $t0, $zero, done
	
	# increment max test count
	lb $t0, numtests
	addiu $t0, $t0, 1
	sb $t0, numtests
	
	# load address to test and jump
	addu $t0, $s0, 8
	lw $t0, 0($t0)
	jalr $t0
	
	# if $v0 is 0, we passed, if not, we failed
	bnez $v0, testfail
	
	# print a dot, increment the pass count, and loop
	addiu $v0, $zero, 11
	addiu $a0, $zero, '.'
	syscall
	
	lb $t0, passcount
	addiu $t0, $t0, 1
	sb $t0, passcount
	
	j mainloop
testfail:
	# clear line from testing dots
	addiu $v0, $zero, 11
	addiu $a0, $zero, '\n'
	syscall
	
	# print test failed text and the name of the current test
	addiu $v0, $zero, 4
	la $a0, failsz
	syscall
	move $a0, $s0
	syscall
	addiu $v0, $zero, 11
	addiu $a0, $zero, '\n'
	syscall
	
	# return to expectation function to print differences.
	jr $ra

mainloop:
	# increment test number and go back to top
	lb $t0, testnum
	addiu $t0, $t0, 1
	sb $t0, testnum
	j exectest

done:
	lb $t0, passcount
	lb $t1, numtests
	
	# print newline
	addiu $v0, $zero, 11
	addiu $a0, $zero, '\n'
	syscall
	
	# if we didn't pass all of them don't say we did.
	bne $t0, $t1, results
	
	# print passed message
	addiu $v0, $zero, 4
	la $a0, passsz
	syscall
	
results:
	# print results 
	addiu $v0, $zero, 4
	la $a0, result1_str
	syscall
	
	addiu $v0, $zero, 1
	lb $a0, passcount
	syscall
	
	addiu $v0, $zero, 11
	addiu $a0, $zero, '/'
	syscall
	
	addiu $v0, $zero, 1
	lb $a0, numtests
	syscall
	
	addiu $v0, $zero, 4
	la $a0, result3_str
	syscall
	
	# exit
	addiu $v0, $zero, 10
	syscall
	
	.end _start

# expectation functions go here
pass_if_equal:
	# $a0 -> value
	# $a1 -> expected
	# checks to see if $a0 and $a1 are equal, result goes into $v0 and control is returned to the main loop
	sne $v0, $a0, $a1
	move $t0, $ra
	
	move $s6, $a0
	move $s7, $a1
	
	jalr $t0

	# print expectation vs reality
	addiu $v0, $zero, 4
	la $a0, expect1_str
	syscall
	addiu $v0, $zero, 34
	move $a0, $s7
	syscall
	addiu $v0, $zero, 4
	la $a0, expect2_str
	syscall
	addiu $v0, $zero, 34
	move $a0, $s6
	syscall
	addiu $v0, $zero, 11
	addiu $a0, $zero, '\n'
	syscall
	
	# go to next test
	j mainloop

pass:
	lui $v0, 0
	jr $ra

# tests start here
slltest1:
	ori $a0, $zero, 1
	sll $a0, $a0, 3
	
	# 1 << 3 == 8
	ori $a1, $zero, 8
	j pass_if_equal
slltest2:
	lui $a0, 0x8000
	sll $a0, $a0, 5
	
	# 0x80000000 << anything == 0
	ori $a1, $zero, 0
	j pass_if_equal
	
srltest1:
	ori $a0, $zero, 1
	srl $a0, $a0, 1
	
	# 1 >> 1 == 0
	addiu $a1, $zero, 0
	j pass_if_equal

srltest2:
	lui $a0, 0x8000
	srl $a0, $a0, 5
	
	# 0x80000000 >> 5 == 0x04000000
	lui $a1, 0x0400
	j pass_if_equal
