// Filename        : seq-mult.v
// Description     : Sequential multiplier
// Author          : Manaswini Munuguri
// Roll Number     : EE19B099
`define width 8
`define ctrwidth 4
module seq_mult (
		 // Outputs
		 p, rdy, 
		 // Inputs
		 clk, reset, a, b
		 ) ;
   input clk, reset;
   input [`width-1:0] a, b;
   // *** Output declaration for 'p'
   output [2*`width-1:0] p;
   output rdy;
   
   // *** Register declarations for p, multiplier, multiplicand
   reg [2*`width-1:0] p;
   reg [2*`width-1:0] multiplier;
   reg [2*`width-1:0] multiplicand;
   reg rdy;
   reg [`ctrwidth:0] ctr;

   always @(posedge clk or posedge reset)
     if (reset) 
	 	begin
			rdy <= 0;
			p <= 0;
			ctr <= 0;
			multiplier 	<= {{`width{a[`width-1]}}, a}; // sign-extend
			multiplicand <= {{`width{b[`width-1]}}, b}; // sign-extend
     	end 
	else 
		begin 
			if (ctr < /* *** How many times should the loop run? */ 2*`width) 
				begin
					// *** Code for multiplication
					// Left shift multiplicand by 1 bit on each iteration
					multiplicand <= multiplicand << 1;
					// If the bit to be multiplied with each bit of the multiplicand is 1, we add the value of multiplicand to value already contained in p
					// This will help implement the MUX functionality shown in the figure in the README file
					if(multiplier[ctr] == 1)
					begin
						p <= p + ( multiplicand );
					end
					// Increment ctr
					ctr <= ctr + 1;
				end 
			else 
				begin
					rdy <= 1; 		// Assert 'rdy' signal to indicate end of multiplication
				end
     	end
   
endmodule // seqmult