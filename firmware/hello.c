// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"

#define STAT_ADDR 0x21000000
void send_stat(bool status);
void send_stat(bool status)
{
	if (status) {
		*((volatile int *)STAT_ADDR) = 1;
	} else {
		*((volatile int *)STAT_ADDR) = 0;
	}
}

#define MULT_A 0x40000000
#define MULT_B 0x40400000
#define MULT_RES 0x40800000
#define MULT_RDY 0x30000000
#define MULT_ENABLE 0x30000004
#define START_SIG 0x01
#define TIMEOUT 1000

// Function prototypes
void Mult_WriteA(int *A, int order);
void Mult_WriteB(int *B, int order);
void Mult_StartAndWait(void);
void Mult_GetResult(int *C_hard, int order);
int checkIfMatricesEqual(int *C_soft, int *C_hard, int order);

// Set up the 'a' input to the multiplier
// void Mult_WriteA(int x)
// {
// 	volatile int *p = (int *)MULT_A;
// 	*p = x;
// }
void Mult_WriteA(int *A, int order){
	int i, j;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
		volatile int *p = (int *)(MULT_A + 4*i);
        *(p) = *((A+i*order) + j);
}}
}

// Set up the 'b' input to the multiplier
void Mult_WriteB(int *B, int order)
{
	int i, j;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
		volatile int *p = (int *)(MULT_B + 4*i);
        *(p) = *((B+i*order) + j);
}}
}

// Do a "reset" so that the values get latched into the multiplier
// and then wait until the signal "rdy" comes back as 1
void Mult_StartAndWait(void)
{
	volatile int *q = (int *)MULT_ENABLE; // corresponds to enable
	volatile int *p = (int *)MULT_RDY; // corresponds to reset
	// Assume the LSB bit of MULT_RDY is connected to the "reset" signal
	*q = 0; // Enable is low initially
	*p = START_SIG; // Reset goes high
	*p = 0; // Reset goes low
	*q = START_SIG; // Enable goes high
	// Keep reading back from MULT_RDY and check if the LSB is set to 1
	// If the "rdy" signal is connected to the LSB, this should happen
	// after multiplication is complete.
	// Note: you can condense all the code below into a single line.
	// It is written this way for clarity, not efficiency.
	bool rdy = false;
	int count = 0;
	while (!rdy && (count < TIMEOUT)) {
		volatile int x = (*p); // read from MULT_RDY
		if ((x & 0x01) == 1) rdy = true;
		count ++;
	}
	if (count == TIMEOUT) {
		print_str("TIMED OUT: did not get a 'rdy' signal back!");
	}
	//Once we're out of the above for loop, we can make enable go low again
	*q = 0;
}

void Mult_GetResult(int *C_hard, int order)
{
	int i, j;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
		volatile int *p = (int *)(MULT_RES + 4*i);
        *((C_hard+i*order) + j) = *(p);
	}}
}

int checkIfMatricesEqual(int *C_soft, int *C_hard, int order)
{
	int i, j;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
        if(*((C_soft+i*order) + j) != *((C_hard+i*order) + j)){
			return 0;
		}
	}}
	return 1;
}

void hello(void)
{
	//===================================================================================================================
	// ORIGINAL CODE STARTS HERE
	//===================================================================================================================
	// int a = 6;
	// int b = 7;
	// print_str("\nMultiplying matrices in software\n");
	// print_dec(a);
	// print_str(" with ");
	// print_dec(b);
	// print_str(" to get ");
	// print_dec(a*b);
	// print_str("\n");
	// //get software result here
	// print_str("\n\nAnd now in hardware: \n");
	// Mult_WriteA(a);
	// Mult_WriteB(b);
	// Mult_StartAndWait();
	// int x = Mult_GetResult();
	// print_str("\nPrinting the result\n");
	// print_dec(x);
	// //Send stat if x(from hardware) = AB(from hardware). Will have to implement
	// // a for loop to check if all elements are equal or not
	// send_stat(x == a*b);
	// // send_stat(true);
	//===================================================================================================================
	// ORIGINAL CODE ENDS HERE
	//===================================================================================================================


	int order = 2;
	int A[order][order]; 
	int B[order][order];
	int C_soft[order][order];
	int C_hard[order][order];
    A[0][0] = 1; A[0][1] = 2; A[1][0] = 1; A[1][1] = 1;
	B[0][0] = 2; B[0][1] = 2; B[1][0] = 2; B[1][1] = 2;
	/////////////////////////////////HARDCODING C_SOFT FOR NOW/////////////////////////////////////////
	C_soft[0][0] = 6; C_soft[0][1] = 6; C_soft[1][0] = 4; C_soft[1][1] = 4;
	//////////////////////////////////////////////////////////////////////////////////////////////////
	print_str("\nWriting A to memory========================\n");
	Mult_WriteA((int *)A, order);
	print_str("\nWriting B to memory========================\n");
	Mult_WriteB((int *)B, order);
	print_str("Waiting for multiplication result\n");
	Mult_StartAndWait();
	Mult_GetResult((int *)C_hard, order);
	//Checking if the result from hardware matches the one from software
	// int equal = checkIfMatricesEqual((int *)C_soft, (int *)C_hard, order);
	// send_stat(equal);
	if((C_soft[0][0] == C_hard[0][0]) && (C_soft[0][1] == C_hard[0][1]) && (C_soft[1][0] == C_hard[1][0]) && (C_soft[1][1] == C_hard[1][1])){
		print_str("Successful multiplication\n");
	}else{
		print_str("Error in multiplication\n");
	}
	print_dec(C_hard[0][0]);
	print_dec(C_hard[0][1]);
	print_dec(C_hard[1][0]);
	print_dec(C_hard[1][1]);

}

