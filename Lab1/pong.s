# EE108B Lab 1

# Name of Group Member 1 (your_sunet_id@stanford.edu)
# Name of Group Member 2 (your_sunet_id@stanford.edu)

# This is the starter code for EE 108B Lab 1
# Winter 2013, Stanford University

# Written by Chris Copeland (chrisnc@stanford.edu)

# You must implement a self-playing Pong game using the SPIM simulator and the
# provided Python script that creates a display that will interact
# with your MIPS program via memory-mapped I/O.

# The principal requirement is that your code use no more than 256 assembly
# instructions. This is enforced in the Makefile, where one argument to spim
# is "-st 1024", meaning: limit the text segment to 1024 bytes = 256 words.
# SPIM will give you many errors if you exceed this limit.

# The display can draw squares of different colors on a 40x30 grid.
# (x,y): (0,0) is the top left, (39,29) is the bottom right
# To draw squares, use the following protocol:

# 1. Store a byte into the transmitter data register (address 0xffff000c)
# representing the x-coordinate of the square to draw. (number from 0 to 39)

# 2. Store a byte into the transmitter data register
# representing the y-coordinate of the square to draw. (number from 0 to 29)

# 3. Store a byte into the transmitter data register
# representing the color to make the square. (number from 0 to 7)
# The color format is 3-bit RGB, e.g., 0b100 is red, 0b010 is green,
# 0b110 is yellow, etc.

# Once the console has read three bytes successfully, it will display the
# square according to the three parameters supplied by your program.
# You must wait for the transmitter control register's ready bit
# to be set before writing a byte to the transmitter data register.
# Please see the appendix of the Patterson and Hennessy text on SPIM for
# a thorough explanation of the memory-mapped I/O mechanism in SPIM.
# This implementation is provided for you below in the "write_byte" function.
# Make sure you understand the implementation.


# You may implement the following extensions for up to 10 points of extra
# credit (out of 100):

# 1. Paddles on every edge of the grid, all following the ball.

# 2. Implement "Breakout". You may interpret this liberally, but at a minimum
# it must involve some form of destructible blocks whose states
# (position, destroyed or not, etc.) are stored in dynamically-allocated
# memory. Read SPIM documentation on syscalls to learn how to allocate memory.

# 3. Allow the user to control the paddle(s) by typing w/a/s/d while
# the Terminal window is selected. Refer to SPIM documentation on how
# to use the receiver control and data registers. (SPIM has facilities
# to read from stdin in a similar fashion to writing to stdout.)

# It may be difficult to implement all three extensions within the
# 256-instruction limit, so choose wisely.

# Come to office hours for a demonstration of these extensions, but be
# creative, particularly with Breakout, if you attempt them yourself.

.text
.globl main

main:
# we put some useful constants on the "stack"
# you may add more or change the existing ones if you wish
    li    $t0, 39         # maximum x coordinate
    sw    $t0, 0($sp)
    li    $t0, 29         # maximum y coordinate
    sw    $t0, 4($sp)
    li    $t0, 0          # background color (black)
    sw    $t0, 8($sp)
    li    $t0, 0x02       # paddle color
    sw    $t0, 12($sp)
    li    $t0, 0x04       # ball color
    sw    $t0, 16($sp)
    li    $t0, 1          # ball height & width, paddle width
    sw    $t0, 20($sp)
    li    $t0, 6          # paddle height
    sw    $t0, 24($sp)

# this is an example of proper use of the display protocol
# remove this code once you have implemented basic drawing
# functionality for the paddle and ball
    li    $a0, 0          # x = 0
    jal   write_byte
    li    $a0, 0          # y = 0
    jal   write_byte
    li    $a0, 0x4        # c = 100 = red
    jal   write_byte
    li    $a0, 39         # x = 39
    jal   write_byte
    li    $a0, 29         # y = 29
    jal   write_byte
    li    $a0, 0x1        # c = 001 = blue
    jal   write_byte
    li    $a0, 0          # x = 0
    jal   write_byte
    li    $a0, 29         # y = 29
    jal   write_byte
    li    $a0, 0x2        # c = 010 = green
    jal   write_byte
    li    $a0, 39         # x = 39
    jal   write_byte
    li    $a0, 0          # y = 0
    jal   write_byte
    li    $a0, 0x6        # c = 110 = yellow
    jal   write_byte

    li $s0, 10            # x pos of ball
    li $s1, 10            # y pos of ball
    li $s2, 1             # x_velocity
    li $s3, 1             # y_velocity

# initialize ball
    add $a0, $s0, $zero
    jal write_byte
    add $a0, $s1, $zero
    jal write_byte
    li $a0, 0x4
    jal write_byte


# paddle
    

game_loop:

  addi $sp, $sp, -4
  sw $ra, 0($sp)     # not necessary
  jal moveBall
  lw $ra, 0($sp)
  addi $sp, $sp, 4

  # counter
  addi $t1, $zero, 1023
counterLoop:
  addi $t1, $t1, -1
  bne $t1, $zero, counterLoop
    

# GAME CODE GOES HERE
  # Pseudo
  # seed paddle and ball in initial position
  # initialize v_x and v_y
  # if (hits left / right wall)
         # v_x = -v_x
  # if (hits top or bottom wall)
         # v_y = -v_y
  # update image of ball
  # update image of paddle
         # paddle will always track the y position of the ball
  # countdown loop
  # loop

# some things you need to do:
# draw on top of the old ball and paddle to erase them
# determine the new positions of the ball and paddle
# draw the ball and paddle again

# pause for some number of instructions so that the game is playable/observable
# (make a count-down loop from some number, experiment with different numbers)

# this will exit SPIM and stop the display from asking for more output
# the implementation is below

    # uncomment this to loop through your game code
    j     game_loop

# send the exit signal to the display and make an exit syscall in SPIM
# this stops the Python Tk display and SPIM safely
end_the_game:
    li    $a0, 69 # 69 is 'E'
    jal   write_byte
    li    $v0, 10 # the exit syscall
    syscall
    
    
 

# write useful functions here

# functions can call other functions, but make sure to use consistent
# calling conventions and to restore return addresses properly

# function: write_byte
# write the byte in $a0 to the transmitter data register after polling
# the ready bit of the transmitter control register
# the transmitter control register is at address 0xffff0008
# the transmitter data register is at address 0xffff000c
# the "la" pseudoinstruction is very convenient for loading these addresses
# to a register in one line of MIPS assembly
# (it expands to two MIPS instructions)
write_byte:
    la    $t8, 0xffff0008
poll_for_ready:
    lw    $t9, 0($t8)
    andi  $t9, $t9, 1
    blez  $t9, poll_for_ready
    sw    $a0, 4($t8)
    jr    $ra

# moving the ball
moveBall:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    add $a0, $s0, $zero
    jal write_byte
    add $a0, $s1, $zero
    jal write_byte
    li $a0, 0
    jal write_byte        # draw over previous position
    add $a0, $s0, $s2
    jal write_byte        # add v_x to x
    add $a0, $s1, $s3
    jal write_byte        # add v_y to y
    li $a0, 0x4
    jal write_byte        # add color
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra