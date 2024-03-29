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
#define MULT_ORDER 0x30000008
#define matrix_order 4

// Function prototypes
void Mult_WriteOrder(int order);
void Mult_WriteA(int *A, int order);
void Mult_WriteB(int *B, int order);	
void Mult_StartAndWait(void);
void Mult_GetResult(int *C_hard, int order);
int checkIfMatricesEqual(int *C_soft, int *C_hard, int order);
int get_time(void);

void Mult_WriteOrder(int order){
    volatile int *p = (int *)MULT_ORDER;
    *p = order;
}
void Mult_WriteA(int *A, int order){
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
	print_str("Waiting for the result...\n");
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
	bool enable = 1;
	while (!rdy && (count < TIMEOUT) && enable) {
		volatile int x = (*p); // read from MULT_RDY
		if (((x & 0x01) == 1)) {
			rdy = true;
		}
		count ++;
		
	}
	if (count == TIMEOUT) {
		print_str("TIMED OUT: did not get a 'rdy' signal back!");
	}
	*q = 0;
	enable = 0;
}

void Mult_GetResult(int *C_hard, int order)
// void Mult_GetResult()
{
	print_str("Reading multiplication result from memory ... \n");
	int i, j;
	int *p = (int *)MULT_RES;
    for (i = 0; i < order; i++){
      for (j = 0; j < order; j++){
        *((C_hard+i*order) + j) = *(p);
		p++;
    }}
	print_str("Finished reading the result\n");
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

int get_time(void)
{
	unsigned int time;
	__asm__ volatile ("rdtime %0;" : "=r"(time));
	return time;
}

void hello(void)
{
	static const int A[matrix_order][matrix_order] = {{1, 2}, {1, 1}, {1, 2}, {1, 1}}; 
	static const int B[matrix_order][matrix_order] = {{2, 2}, {2, 2}, {1, 2}, {1, 1}};
	int C_soft[matrix_order][matrix_order];
	int C_hard[matrix_order][matrix_order];

	//Start2 is the timestamp before starting the execution of multiplication C-code
	int start = get_time();
	for (int i = 0; i < matrix_order; i++) {
       	 for (int j = 0; j < matrix_order; j++) {
            		C_soft[i][j] = 0;
           		 for (int k = 0; k < matrix_order; k++){
               		 C_soft[i][j] += A[i][k] * B[k][j];
            			}
        	}
    	}
	int end = get_time();

	print_str("\n");
	print_str("Multiplication in software------------------------------------\n");
	print_str("Time taken by software : ");
	print_dec(end - start);
	print_str("\n");
	print_str("Multiplication in hardware------------------------------------\n");
    print_str("Writing order to memory ... \n");
    Mult_WriteOrder(matrix_order);
	print_str("Writing A to memory ... \n");
	Mult_WriteA((int *)A, matrix_order);
	print_str("Writing B to memory ... \n");
	Mult_WriteB((int *)B, matrix_order);
	Mult_StartAndWait();
	Mult_GetResult((int *)C_hard, matrix_order);
	//Checking if the result from hardware matches the one from software
	int equal = checkIfMatricesEqual((int *)C_soft, (int *)C_hard, matrix_order);
	send_stat(equal);
}
