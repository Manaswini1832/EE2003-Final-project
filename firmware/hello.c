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

 #define MULT_BASE 0x30000000
#define MULT_A 0x40000000
#define MULT_B 0x40400000
#define MULT_RES 0x30000004
#define START_SIG 0x01
#define TIMEOUT 1000

// Function prototypes
void Mult_WriteA(int x);
void Mult_WriteB(int x);
void Mult_StartAndWait(void);
int Mult_GetResult(void);

// Set up the 'a' input to the multiplier
void Mult_WriteA(int x)
{
	volatile int *p = (int *)MULT_A;
	*p = x;
}

// Set up the 'b' input to the multiplier
void Mult_WriteB(int x)
{
	volatile int *p = (int *)MULT_B;
	*p = x;
}

// Do a "reset" so that the values get latched into the multiplier
// and then wait until the signal "rdy" comes back as 1
void Mult_StartAndWait(void)
{
	volatile int *p = (int *)MULT_BASE;
	// Set the "reset" signal to 1 - assume the LSB bit of MULT_BASE
	// is connected to the "reset" signal
	*p = START_SIG; 
	// Remove the reset signal.  Since each instruction anyway takes
	// multiple cycles, the reset will be high for at least one clock
	// which is enough
	*p = 0;
	// Keep reading back from MULT_BASE and check if the LSB is set to 1
	// If the "rdy" signal is connected to the LSB, this should happen
	// after multiplication is complete.
	// Note: you can condense all the code below into a single line.
	// It is written this way for clarity, not efficiency.
	bool rdy = false;
	int count = 0;
	while (!rdy && (count < TIMEOUT)) {
		volatile int x = (*p); // read from MULT_BASE
		if ((x & 0x01) == 1) rdy = true;
		count ++;
	}
	if (count == TIMEOUT) {
		print_str("TIMED OUT: did not get a 'rdy' signal back!");
	}
}

int Mult_GetResult(void)
{
	volatile int *p = (int *)MULT_RES;
	return (*p);
}

void hello(void)
{
	int a = 6;
	int b = 7;
	print_str("\nMultiplying matrices in software\n");
	print_dec(a);
	print_str(" with ");
	print_dec(b);
	print_str(" to get ");
	print_dec(a*b);
	print_str("\n");
	//get software result here
	print_str("\n\nAnd now in hardware: \n");
	Mult_WriteA(a);
	Mult_WriteB(b);
	Mult_StartAndWait();
	int x = Mult_GetResult();
	print_str("\nPrinting the result\n");
	print_dec(x);
	//Send stat if x(from hardware) = AB(from hardware). Will have to implement
	// a for loop to check if all elements are equal or not
	send_stat(x == a*b);
	// send_stat(true);
}

