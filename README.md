# EE2003 Project - Acceleration of matrix multiplication using a memory mapped peripheral

## Project Goals
Our project was focused on implementing the multiplication of two square matrices using the
non-recursive multiplication algorithm and trying to check if the use of a memory mapped
peripheral accelerates the process or not.

## How the code baseline was setup for comparison
The baseline was set up by referring to the nanojpeg project baseline. To calculate the time taken to
multiply two square matrices using the matrix multiplier that was coded in Verilog,
$display($time) statements were used. To calculate the time taken by the C-code, a function
called get_time was defined. The two results obtained were then compared as shown in the
subsequent sections.

## How to run the code with different inputs
- In the file ```firmware/hello.c``` change the parameter matrix_order to an order of choice and input the matrices A, B into the main ```hello``` function
- Run the command ```make```

This should print out a ```All tests passed``` message if the result C calculated using the C-code is the same as the result obtained from the ```matrix_mult.v``` module which is the peripheral that we used to accelerate matrix multiplication