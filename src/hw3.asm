# Homework 3
# Name: Myungsuk Moon
# SBU ID: 110983806

##################################
# Part 1 - String Functions
##################################

# Parameter
# $a0: char
# Return
# $v0: 1 if char is whitespace char, otherwise 0
is_whitespace:
	# Move argument to temporary register
	move	$t0, $a0

	# Check if the char is null
	seq	$t2, $t0, $zero

	# Check if the char is space
	li	$t1, 32		# Space
	seq	$t3, $t0, $t1

	# Check if the char is newline
	li	$t1, 10		# newline
	seq	$t4, $t0, $t1

	# Check if any of the results are 1
	or	$t0, $t2, $t3
	or	$t0, $t0, $t4

	# Move to return register 
	move	$v0, $t0

	# Go back
	jr	$ra

# Parameter
# $a0: char1, $a1: char2
# Return
# $v0: 1 if both chars are whitespace char, otherwise 0
cmp_whitespace:
	# Save original information
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)

	# Move arguments to saved register
	move	$s0, $a0
	move	$s1, $a1

	# Call is_whitespace to check if char1 is a whitespace
	move	$a0, $s0
	jal	is_whitespace
	move	$s2, $v0

	# Call is_whitespace to check if char2 is a whitespace
	move	$a0, $s1
	jal	is_whitespace
	move	$t0, $v0

	# Check if any of the results are 1
	and	$t0, $t0, $s2

	# Then move result to proper register
	move	$v0, $t0

	# Restore original information
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 16

	# Go back
	jr	$ra

# Parameter
# $a0: address to be copied from
# $a1: address to be copied to
# $a2: num of bytes to copy
# No returns
strcpy:
	# Move arguments to temporary register
	move	$t0, $a0	# src address
	move	$t1, $a1	# dest address
	move	$t2, $a2	# num of bytes

	# Src address should be greater than dest address
	ble	$t0, $t1, strcpy_done

strcpy_loop:
	# Check if done
	blez	$t2, strcpy_done

	# Load byte from src
	lb	$t3, ($t0)
	
	# Save byte to dest
	sb	$t3, ($t1)

	# Shift index
	addi	$t0, $t0, 1
	addi	$t1, $t1, 1

	# Decrement num of bytes
	addi	$t2, $t2, -1

	# Continue loop
	j	strcpy_loop

strcpy_done:
	# Go back
	jr	$ra

# Parameter
# $a0: string
# Return
# $v0: length of string
strlen:
	# Save original information
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)

	# Move argument to saved register
	move	$s0, $a0

	# Set up counter
	li	$s1, 0

strlen_loop:
	# Load next char from string
	lb	$t0, ($s0)

	# Check if whitespace char has reached
	move	$a0, $t0
	jal	is_whitespace
	move	$t0, $v0
	beq	$t0, 1, strlen_done

	# Increment counter
	addi	$s1, $s1, 1

	# Shift index
	addi	$s0, $s0, 1

	# Continue loop
	j	strlen_loop

strlen_done:
	# Move result to proper register
	move	$v0, $s1

	# Restore original information
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 12

	# Go back
	jr	$ra

##################################
# Part 2 - vt100 MMIO Functions
##################################

# Parameter
# $a0: state, $a1: color
# $a2: category, $a3: mode
# No returns
set_state_color:
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1
	move	$t2, $a2
	move	$t3, $a3

	# Shift state by category
	add	$t0, $t0, $t2

	# Check mode
	beqz	$t3, set_state_color_fgbg
	beq	$t3, 1, set_state_color_fg
	beq	$t3, 2, set_state_color_bg
	
	# Invalid input so go back without action
	j	set_state_color_done

set_state_color_fgbg:
	# Save color to state
	sb	$t1, ($t0)

	# Done
	j	set_state_color_done

set_state_color_fg:
	# Delete bg color
	andi	$t1, $t1, 15

	# Save color to state
	sb	$t1, ($t0)

	# Done
	j	set_state_color_done

set_state_color_bg:
	# Delete fg color
	andi	$t1, $t1, 240

	# Save color to state
	sb	$t1, ($t0)

	# Done
	j	set_state_color_done

set_state_color_done:
	# Go back
	jr	$ra

# Parameter
# $a0: state, $a1: char
# No returns
save_char:
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1

	# Get x,y position from the state
	lb	$t2, 2($t0)	# x
	lb	$t3, 3($t0)	# y

	# Multiply x by row size(80)
	li	$t4, 80
	mul	$t4, $t4, $t2

	# Add y to result
	add	$t4, $t4, $t3

	# Multiply result by 2
	sll	$t4, $t4, 1

	# Save byte using the index
	li	$t0, 0xffff0000		# Address of (0,0)
	add	$t0, $t0, $t4
	sb	$t1, ($t0)

	# Go back
	jr	$ra

# Parameter
# $a0: state, $a1: color_only
# No returns
reset:
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1

	# Set up counter and size
	li	$t2, 0
	li	$t3, 2000

	# Load default color
	lb	$t4, ($t0)

	# Check color_only to decide what to erase
	beqz	$t1, reset_all

	# Start from 1 when erasing colors only
	li	$t0, 0xffff0001		# Address of (0,0) color

reset_color:
	# Check if done
	bge	$t2, $t3, reset_done

	# Replace color with existing color
	sb	$t4, ($t0)

	# Go to next index
	addi	$t0, $t0, 2

	# Increment counter
	addi	$t2, $t2, 1

	# Again
	j	reset_color

reset_all:
	# Start from 0 to erase
	li	$t0, 0xffff0000		# Address of (0,0)

	# Create half-word to replace with
	sll	$t4, $t4, 8
 
reset_all_loop:
	# Check if done
	bge	$t2, $t3, reset_done

	# Replace char and color
	sh	$t4, ($t0)

	# Go to next index
	addi	$t0, $t0, 2

	# Increment counter
	addi	$t2, $t2, 1

	# Again
	j	reset_all_loop

reset_done:
	# Go back
	jr	$ra
	
# Parameter
# $a0: x, $a1: y
# $a2: color
# No returns
clear_line:
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1
	move	$t2, $a2

	# Start from 0 to erase
	li	$t3, 0xffff0000		# Address of (0,0)

	# Multiply x by row size(80 * 2)
	li	$t4, 160
	mul	$t4, $t4, $t0

	# Multiply y by 2
	sll	$t1, $t1, 1

	# Add to address to move to selected row
	add	$t3, $t3, $t4
	add	$t3, $t3, $t1

	# Set up size
	li	$t4, 160

	# Create half-word to replace with
	sll	$t2, $t2, 8

clear_line_loop:
	# Check if done
	bge	$t1, $t4, clear_line_done

	# Replace char and color
	sh	$t2, ($t3)

	# Go to next index
	addi	$t3, $t3, 2

	# Increment counter y
	addi	$t1, $t1, 2

	# Again
	j	clear_line_loop

clear_line_done:
	# Go back
	jr	$ra

# Parameter
# $a0: state, $a1: x
# $a2: y, $a3: initial
# No returns
set_cursor:
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1
	move	$t2, $a2
	move	$t3, $a3

	# Check if initial is 1
	beq	$t3, 1, set_cursor_initial

	# Get original cursor position from state
	lb	$t4, 2($t0)		# Original x
	lb	$t5, 3($t0)		# Original y

	# Multiply x by row size(80)
	li	$t6, 80
	mul	$t6, $t6, $t4

	# Add y to result
	add	$t6, $t6, $t5

	# Multiply result by 2 then add 1
	sll	$t6, $t6, 1
	addi	$t6, $t6, 1

	# Load color byte using the index
	li	$t7, 0xffff0000		# Address of (0,0)
	add	$t7, $t7, $t6
	lb	$t6, ($t7)		# Current color

	# Invert bold bits
	xori	$t6, $t6, 136		# New color

	# Save new color to the byte
	sb	$t6, ($t7)

	# Update cursor position at state
	sb	$t1, 2($t0)
	sb	$t2, 3($t0)

	# Get new cursor position
	# Multiply x by row size(80)
	li	$t4, 80
	mul	$t4, $t4, $t1

	# Add y to result
	add	$t4, $t4, $t2

	# Multiply result by 2 then add 1
	sll	$t4, $t4, 1
	addi	$t4, $t4, 1

	# Load color byte using the index
	li	$t5, 0xffff0000		# Address of (0,0)
	add	$t5, $t5, $t4
	lb	$t4, ($t5)		# Current color

	# Invert bold bits
	xori	$t4, $t4, 136		# New color

	# Save new color to the byte
	sb	$t4, ($t5)

	# Done
	jr	$ra

set_cursor_initial:
	# Update cursor position at state
	sb	$t1, 2($t0)
	sb	$t2, 3($t0)

	# Get new cursor position
	# Multiply x by row size(80)
	li	$t4, 80
	mul	$t4, $t4, $t1

	# Add y to result
	add	$t4, $t4, $t2

	# Multiply result by 2 then add 1
	sll	$t4, $t4, 1
	addi	$t4, $t4, 1

	# Load color byte using the index
	li	$t5, 0xffff0000		# Address of (0,0)
	add	$t5, $t5, $t4
	lb	$t4, ($t5)		# Current color

	# Invert bold bits
	xori	$t4, $t4, 136		# New color

	# Save new color to the byte
	sb	$t4, ($t5)

	# Done
	jr	$ra

# Parameter
# $a0: state, $a1: direction
# No returns
move_cursor:
	# Save original information
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1

	# Get original cursor position from state
	lb	$t2, 2($t0)		# Original x (row)
	lb	$t3, 3($t0)		# Original y (col)

	# Check direction
	beq	$t1, 108, move_cursor_right
	beq	$t1, 104, move_cursor_left
	beq	$t1, 106, move_cursor_down
	beq	$t1, 107, move_cursor_up

move_cursor_right:
	# Check if cursor is at rightmost index
	bge	$t3, 79, move_cursor_done

	# Add 1 to move right
	addi	$t3, $t3, 1

	# Move cursor to right
	move	$a0, $t0
	move	$a1, $t2
	move	$a2, $t3
	li	$a3, 0
	jal	set_cursor

	j	move_cursor_done

move_cursor_left:
	# Check if cursor is at leftmost index
	blez	$t3, move_cursor_done

	# Add -1 to move left
	addi	$t3, $t3, -1

	# Move cursor to left
	move	$a0, $t0
	move	$a1, $t2
	move	$a2, $t3
	li	$a3, 0
	jal	set_cursor

	j	move_cursor_done

move_cursor_down:
	# Check if cursor is at last row
	bge	$t2, 24, move_cursor_done

	# Add 1 to move down
	addi	$t2, $t2, 1

	# Move cursor down
	move	$a0, $t0
	move	$a1, $t2
	move	$a2, $t3
	li	$a3, 0
	jal	set_cursor

	j	move_cursor_done

move_cursor_up:
	# Check if cursor is at last row
	blez	$t2, move_cursor_done

	# Add -1 to move up
	addi	$t2, $t2, -1

	# Move cursor up
	move	$a0, $t0
	move	$a1, $t2
	move	$a2, $t3
	li	$a3, 0
	jal	set_cursor

move_cursor_done:
	# Restore original information
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4

	# Done
	jr	$ra

# Parameter
# $a0: mmio string, $a1: b string
# Return
# $v0: 1 if two equal, 0 otherwise
mmio_streq:
	# Save original information
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	
	# Move arguments to saved registers
	move	$s0, $a0
	move	$s1, $a1

mmio_streq_loop:
	# Get a character from mmio
	lb	$s2, ($s0)
	
	# Get a character from b
	lb	$s3, ($s1)

	# Compare if both are whitespace
	move	$a0, $s2
	move	$a1, $s3
	jal	cmp_whitespace
	move	$t0, $v0
	beq	$t0, 1, mmio_streq_equal

	# Compare if both chars are equal
	bne	$s2, $s3, mmio_streq_unequal

	# Shift to next index at mmio
	addi	$s0, $s0, 2

	# Shift to next index at b
	addi	$s1, $s1, 1

	# Do again
	j	mmio_streq_loop

mmio_streq_unequal:
	# Load result
	li	$v0, 0

	# Restore original information
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20

	# Done
	jr	$ra

mmio_streq_equal:
	# Load result
	li	$v0, 1

	# Restore original information
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20

	# Done
	jr	$ra

##################################
# Part 3 - UI/UX Functions
##################################

# Parameter
# $a0: state
# No returns
handle_nl:
	# Save original information
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	
	# Move argument to saved register
	move	$s0, $a0

	# Get current position of the cursor
	lb	$s1, 2($s0)		# x row
	lb	$s2, 3($s0)		# y col

	# Check if the cursor is at the last row
	bge	$s1, 24, handle_nl_last_row

	# Check if the cursor is at the last column
	bge	$s2, 79, handle_nl_last_col

	# Save new line char at current position
	move	$a0, $s0
	li	$a1, 10			# new line
	jal	save_char

	# Get default color
	lb	$t0, 0($s0)

	# Clear rest of the line
	addi	$t1, $s2, 1
	move	$a0, $s1
	move	$a1, $t1
	move	$a2, $t0
	jal	clear_line

	# Go to first index of new row	
	move	$t0, $s1
	addi	$t0, $t0, 1		# Next row number
	move	$a0, $s0
	move	$a1, $t0
	li	$a2, 0
	li	$a3, 0
	jal	set_cursor
	
	# Restore original information
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 16

	# Done
	jr	$ra

handle_nl_last_row:
	# Go back to first row
	move	$a0, $s0
	move	$a1, $zero
	li	$a2, 0
	li	$a3, 0
	jal	set_cursor
	
	# Restore original information
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 16

	# Done
	jr	$ra

handle_nl_last_col:
	# Go to first index of new row	
	move	$t0, $s1
	addi	$t0, $t0, 1		# Next row number
	move	$a0, $s0
	move	$a1, $t0
	li	$a2, 0
	li	$a3, 0
	jal	set_cursor
	
	# Restore original information
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 16

	# Done
	jr	$ra

# Parameter
# $a0: state
# No returns
handle_backspace:
	# Save original information
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	
	# Move argument to temp register
	move	$t0, $a0

	# Get current position of the cursor
	lb	$t1, 2($t0)		# x row
	lb	$t2, 3($t0)		# y col

	# Multiply x by row size(80)
	li	$t4, 80
	mul	$t4, $t4, $t1

	# Add y to result
	add	$t4, $t4, $t2

	# Multiply result by 2
	sll	$t4, $t4, 1

	# Get current index
	li	$t3, 0xffff0000		# Address of (0,0)
	add	$t3, $t3, $t4		# Address of current index

	# Get next index
	addi	$t4, $t3, 2		# Address of next index

	# Get amount of indexes to shift
	li	$t6, 79
	sub	$t5, $t6, $t2

	# Get last index address of the row
	sll	$t6, $t5, 1
	add	$s0, $t3, $t6

	# Get color of the last index
	addi	$t6, $s0, 1
	lb	$s1, ($t6)

	# Call strcpy to move char left
	move	$a0, $t4
	move	$a1, $t3
	move	$a2, $t5
	jal	strcpy

	# Create half word to store
	sll	$s1, $s1, 4

	# Set last index of the row
	sh	$s1, ($s0)
	
	# Restore original information
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 12

	# Done
	jr	$ra

# Parameter
# $a0: x, $a1: y
# $a2: color, $a3: int n
# No returns
highlight:
	# Move arguments to temp registers
	move	$t0, $a0
	move	$t1, $a1
	move	$t2, $a2
	move	$t3, $a3

	# Multiply x by row size(80)
	li	$t5, 80
	mul	$t5, $t5, $t0

	# Add y to result
	add	$t5, $t5, $t1

	# Multiply result by 2 then add 1
	sll	$t5, $t5, 1
	addi	$t5, $t5, 1

	# Go to address of the chosen index
	li	$t4, 0xffff0000		# Address of (0,0)
	add	$t4, $t4, $t5

highlight_loop:
	# Check if done
	blez	$t3, highlight_done

	# Save new color
	sb	$t2, ($t4)

	# Decrement counter
	addi	$t3, $t3, -1
	
	# Go to next index
	addi	$t4, $t4, 2

	# Do again
	j	highlight_loop

highlight_done:
	# Done
	jr	$ra

# Parameter
# $a0: color
# $a1: dictionary
# No returns
highlight_all:
	# Save original information
	addi	$sp, $sp, -28
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)

	# Move arguments to saved register
	move	$s0, $a0
	move	$s1, $a1

	# Get current index
	li	$s2, 0xffff0000		# Address of (0,0)

	# Initialize counter
	li	$s3, 0

	# Initialize dict counter
	li	$s4, 0

	# Initialize word length holder
	li	$s5, 0

highlight_all_skip_whitespace:
	### Go to next string by skipping whitespace
	# Load char from address
	lb	$t0, ($s2)

	# Check if it is whitespace
	move	$a0, $t0
	jal	is_whitespace
	move	$t1, $v0

	# Done if none whitespace is found
	beqz	$t1, highlight_all_check_string

	# Increment counter
	addi	$s3, $s3, 1

	# Check if done
	bge	$s3, 2000, highlight_all_done

	# Go to next index
	addi	$s2, $s2, 2

	# Do again
	j	highlight_all_skip_whitespace

highlight_all_check_string:
	### Check the dictionary with the current string
	# Check if two strings match
	lw	$t1, ($s1)
	move	$a0, $s2	# Address of current index mmio string
	move	$a1, $t1	# Address of current dict string
	jal	mmio_streq
	move	$t0, $v0
	
	# Highlight if two matches
	beq	$t0, 1, highlight_all_highlight

	# Shift dictionary index
	addi	$s1, $s1, 4

	# Increment dict counter
	addi	$s4, $s4, 1

	# Check if dict index reached end
	lw	$t1, ($s1)
	beqz	$t1, highlight_all_no_highlight

	# Do again
	j	highlight_all_check_string

highlight_all_no_highlight:
	### If not highlighted, skip to next whitespace
	# Load char from address
	lb	$t0, ($s2)

	# Check if it is whitespace
	move	$a0, $t0
	jal	is_whitespace
	move	$t1, $v0

	# Done if whitespace is found
	beq	$t1, 1, highlight_all_reset_dict

	# Increment counter
	addi	$s3, $s3, 1

	# Check if done
	bge	$s3, 2000, highlight_all_done

	# Go to next index
	addi	$s2, $s2, 2

	# Do again
	j	highlight_all_no_highlight

highlight_all_highlight:
	# Get string length to highlight
	lw	$t0, ($s1)
	move	$a0, $t0
	jal	strlen
	move	$s5, $v0

	# Get row x and col y
	li	$t1, 80
	div	$s3, $t1
	mflo	$t2		# row x
	mfhi	$t3		# col y

	# Highlight the selected string
	move	$a0, $t2
	move	$a1, $t3
	move	$a2, $s0
	move	$a3, $s5
	jal	highlight

	# Go to next whitespace
	move	$t0, $s5
	sll	$t0, $t0, 1
	add	$s2, $s2, $t0

	# Update counter
	add	$s3, $s3, $s5
	
	# Check if done
	bge	$s3, 2000, highlight_all_done	

highlight_all_reset_dict:
	# Reset dict address
	sll	$s4, $s4, 2
	sub	$s1, $s1, $s4

	# Reset dict counter
	li	$s4, 0

	# Loop again
	j	highlight_all_skip_whitespace
	
highlight_all_done:
	# Restore original information
	lw	$s5, 24($sp)
	lw	$s4, 20($sp)
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 28

	# Done
	jr	$ra
