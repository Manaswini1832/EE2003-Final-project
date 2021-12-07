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
// void Mult_GetResult(int *C_hard, int order);
void Mult_GetResult(void);
int checkIfMatricesEqual(int *C_soft, int *C_hard, int order);


void Mult_WriteA(int *A, int order){
	print_str("Inside the mult write A function\n");
	int i, j;
	int *p = (int *)MULT_A;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
        *(p) = *((A+i*order) + j);
		p++;
    }}
}


void Mult_WriteB(int *B, int order)
{
	print_str("Inside the mult write B function\n");
	int i, j;
	int *p = (int *)MULT_B;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
        *(p) = *((B+i*order) + j);
		p++;
    }}
}

// Do a "reset" so that the values get latched into the multiplier
// and then wait until the signal "rdy" comes back as 1
void Mult_StartAndWait(void)
{
	print_str("Inside the Multstart,wait function\n");
	volatile int *p = (int *)MULT_RDY; // corresponds to reset
	volatile int *q = (int *)MULT_ENABLE; 
	// Assume the LSB bit of MULT_RDY is connected to the "reset" signal
	*p = START_SIG; // Reset goes high
	*p = 0; // Reset goes low
	*q = 1;
	// Keep reading back from MULT_RDY and check if the LSB is set to 1
	// If the "rdy" signal is connected to the LSB, this should happen
	// after multiplication is complete.
	bool rdy = false;
	int count = 0;
	// bool enable = true;
	bool enable = 1;
	while (!rdy && (count < TIMEOUT) && enable) {
		volatile int x = (*p); // read from MULT_RDY
		// volatile int y = (*q); // read from MULT_ENABLE
		// volatile int y = (*q);
		if (((x & 0x01) == 1)) rdy = true;
		count ++;
	}
	if (count == TIMEOUT) {
		print_str("TIMED OUT: did not get a 'rdy' signal back!");
	}
	*q = 0;
	enable = 0;
}

// void Mult_GetResult(int *C_hard, int order)
void Mult_GetResult()
{
	//axi4_mem_periph.v sends back a 1048576 bit number and we need to unflatten it to get the correct result
	volatile int *p = (int *)(MULT_RES);
	print_str("Inside the mult get result function");
	print_dec(*(p));
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
	print_str("Started executing hello.c");
	int order = 2;
	int A[order][order]; 
	int B[order][order];
	// int C_soft[order][order];
	// int C_hard[order][order];
    A[0][0] = 1; A[0][1] = 2; A[1][0] = 1; A[1][1] = 1;
	B[0][0] = 2; B[0][1] = 2; B[1][0] = 2; B[1][1] = 2;
	/////////////////////////////////HARDCODING C_SOFT FOR NOW/////////////////////////////////////////
	// C_soft[0][0] = 6; C_soft[0][1] = 6; C_soft[1][0] = 4; C_soft[1][1] = 4;
	//////////////////////////////////////////////////////////////////////////////////////////////////
	print_str("\n");
	print_str("Writing A to memory========================\n");
	Mult_WriteA((int *)A, order);
	print_str("Writing B to memory========================\n");
	Mult_WriteB((int *)B, order);
	Mult_StartAndWait();
	// Mult_GetResult((int *)C_hard, order);
	Mult_GetResult();
	//Checking if the result from hardware matches the one from software
	// int equal = checkIfMatricesEqual((int *)C_soft, (int *)C_hard, order);
	// send_stat(equal);
}

