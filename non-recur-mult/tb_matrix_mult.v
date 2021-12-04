//Testbench for testing the 4 by 4 matrix multiplier.
module tb_matrix_mult
#(
parameter order = 4, bitwidth = 8
);

reg [order*order*bitwidth - 1:0] A;
reg [order*order*bitwidth - 1:0] B;
wire [order*order*bitwidth - 1:0] C;
reg clk, reset, enable;
wire rdy;
reg [bitwidth-1:0] matC [order-1:0][order-1:0];
integer i,j;
parameter Clock_period = 10;    //Change clock period here. 

initial
begin
    $dumpfile("matrix_mult.vcd");
    $dumpvars(0, tb_matrix_mult);
    clk = 1;
    reset = 1;
    #100;   //Apply reset for 100 ns before applying inputs.
    reset = 0;
    #Clock_period;
    //input matrices are set and enable input is set High

    //3x3 matrix test case
    // A = {8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,8'd1};
    // B = {8'd1,8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2};
    //Answer should be 5D 96 7E 39 60 51 15 2A 24

    //4x4 matrix test case
    A = {8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,8'd1,8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3};
    B = {8'd1,8'd9,8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,8'd1,8'd9,8'd8,8'd7,8'd6,8'd5,8'd4};
    //Answer should be 71 A4 C5 A7 31 50 5D 4F 78 68 97 7E 41 65 77 65

    enable = 1;
    wait(rdy); //wait until rdy goes High.
    
    #(Clock_period/2);  //wait for half a clock cycle.
    //convert the 1-D matrix into 2-D format to easily verify the results.
    for(i=0; i<=order-1; i=i+1) begin
        for(j=0; j<=order-1; j=j+1) begin
            matC[i][j] = C[(i*order+j)*bitwidth+:bitwidth];
        end
    end
    #Clock_period;  //wait for one clock cycle.
    enable = 0; //reset enable.
    #(20*Clock_period);
    $finish;  //Stop the simulation, as we have finished testing the design.
end

//generate a 50Mhz clock for testing the design.
always #(Clock_period/2) clk <= ~clk;

//Instantiate the matrix multiplier
matrix_mult #(.order(order), .bitwidth(bitwidth)) matrix_multiplier (.clk(clk), 
        .reset(reset), 
        .enable(enable), 
        .A(A),
        .B(B), 
        .C(C),
        .rdy(rdy));


endmodule   //End of testbench.