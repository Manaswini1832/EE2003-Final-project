//Attribution : https://verilogcodes.blogspot.com/2020/12/synthesizable-matrix-multiplication-in.html
//Above post contained a 3x3 matrix multiplier code. We generalized it to multiply two nxn matrices

//n by n matrix multiplier. Each element of the matrix is "bitwidth" bits wide. 
//Inputs are named A and B and output is named as C. 
//Each matrix has n^2 elements each of which are "bitwidth" bits wide each. So the inputs are n^2*bitwidth=128 bits long.

module matrix_mult
    #(
        parameter order = 2, bitwidth = 16 //Default parameter values
    )
    (   input clk,
        input reset, //active high reset
        input enable,    //This should be High throughout the matrix multiplication process.
        input [order*order*bitwidth-1:0] A,
        input [order*order*bitwidth-1:0] B,
        output reg [2*order*order*bitwidth-1:0] C,
        output reg rdy     //rdy high indicates that multiplication is done and result is availble at C.
    );   

reg signed [bitwidth-1:0] matA [order-1:0][order-1:0];
reg signed [bitwidth-1:0] matB [order-1:0][order-1:0];
reg signed [2*bitwidth-1:0] matC [order-1:0][order-1:0];
integer i,j,k;                            // loop indices
reg first_cycle;                          // indicates its the first clock cycle after enable went High.
reg end_of_mult;                          // indicates multiplication has ended.
reg signed [2*bitwidth-1:0] temp;                   // register to hold the product of two elements.

//Matrix multiplication.
always @(posedge clk or posedge reset)    
begin
    if(reset == 1) begin    //Active high reset
        i = 0;
        j = 0;
        k = 0;
        temp = 0;
        first_cycle = 1;
        end_of_mult = 0;
        rdy = 0;
        //Initialize all the matrix register elements to zero.
        for(i=0; i<=order-1; i=i+1) begin
            for(j=0; j<=order-1; j=j+1) begin
                matA[i][j] = {bitwidth{1'd0}};
                matB[i][j] = {bitwidth{1'd0}};
                matC[i][j] = {bitwidth{1'd0}};
            end 
        end 
    end
    else begin  //for the positve edge of Clock.
        if(enable == 1)     //Any action happens only when enable is High.
            if(first_cycle == 1) begin     //the very first cycle after enable is high.
                //the matrices which are in a 1-D array are converted to 2-D matrices first.
                for(i=0; i<=order-1; i=i+1) begin
                    for(j=0; j<=order-1; j=j+1) begin
                        matA[i][j] = A[(i*order+j)*bitwidth+:bitwidth];
                        matB[i][j] = B[(i*order+j)*bitwidth+:bitwidth];
                        matC[i][j] = {bitwidth{1'd0}};
                    end 
                end
                //re-initalize registers before the start of multiplication.
                first_cycle = 0;
                end_of_mult = 0;
                temp = 0;
                i = 0;
                j = 0;
                k = 0;
            end
            else if(end_of_mult == 0) begin     //multiplication hasnt ended. Keep multiplying.
                //Actual matrix multiplication starts from now on.
                temp = matA[i][k]*matB[k][j];
                matC[i][j] = matC[i][j] + temp[bitwidth-1:0];    //Lower half of the product is accumulatively added to form the result.
                if(k == order-1) begin
                    k = 0;
                    if(j == order-1) begin
                        j = 0;
                        if (i == order-1) begin
                            i = 0;
                            end_of_mult = 1;
                        end
                        else
                            i = i + 1;
                    end
                    else
                        j = j+1;    
                end
                else
                    k = k+1;
            end
            else if(end_of_mult == 1) begin     //End of multiplication has reached
                //convert n by n matrix into a 1-D matrix.
                for(i=0; i<=order-1; i=i+1) begin   //run through the rows
                    for(j=0; j<=order-1; j=j+1) begin    //run through the columns
                        C[(i*order+j)*bitwidth+:bitwidth] = matC[i][j];
                    end
                end   
                rdy = 1;   //Set this output High, to say that C has the final result.
            end
    end
end
 
endmodule