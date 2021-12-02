### Commands to run after installing Virtualbox

1. To install iverilog and gtkwave

```
sudo apt get install iverilog
```

```
sudo apt get install gtkwave
```

2. To run the matrix_mult.v module along with the testbench

```
iverilog matrix_mult.v tb_matrix_mult.v
```

```
vvp a.out
```

This will create a file called **matrix_mult.vcd**. Right click on that file and select **Open with GTKWave**. Then select the variables whose plot you want to see and click on Append at the bottom of the screen. This will show the waves of the variables. You can click on the "zoom to fit icon"(please google it :P) in GTKWave to properly see the waves

### Random matrix generator inputs and outputs

Random matrix generator inputs, outputs
Input : Order, bitwidth (comes from test bench)
Outputs : A, B

A and B should be of order specified by test bench and their elements should contain "bitwidth" number of bits

### Divide and conquer multiplier inputs and Outputs

Same as in the matrix_mult.v module

### Todos

## Non-recursive multiplier todos

- [x] Non-recursive multiplier code
- [x] Test non-recursive multiplier with custom inputs
- [ ] Create random matrix generator
- [ ] Test non-recursive multiplier with random inputs using the random matrix generator

## Divide and conquer multiplier(DACM) todos

- [ ] DACM code
- [ ] Test DACM with custom inputs
- [ ] Test DACM with random inputs using the random matrix generator
- [ ] Put DACM C code in picorv and calculate time to finish mult(test input for this should be subject to prevsly decode matrix constraints)

**If DACM part is not done by 5th, leave it and focus on modifying the non-recursive multiplier to multiply mxn matrices instead**

## Interfacing the peripheral

- [ ] Modify aximem peripheral, Makefile, testbench etc...
- [ ] Incorporate the random matrix generator that inputs two random matrices to c code and to peripheral and calculate time taken by peripheral
- [ ] Decide matrix constraints like size etc and allocate memory correctly to A,B,Result C, size of A, size of B, Start mult mem loc

## Leftovers

- [ ] Analyse
- [ ] PDF
- [ ] Create video

### Timeline we decided

By 5th if DACM is done, then we'll connect it to the picorv32 processor and do the analysis. But if it is not done, we'll leave that and only do the non-recursive multiplier that we already have now.

### What each of us has to do till 5th

1. Ritu : RMG, DACM
2. Aditya : RMG, DACM
3. Manaswini : RMG, DACM
4. Time required for program execution verilog?
5. Understand how picorv memory etc.. works

### Ideas for what can be contained in the results section

1. Compare times and see if the peripheral makes the operation faster or not
2. Increase matrix size and see its effect on calculation time(Matplotlib)
