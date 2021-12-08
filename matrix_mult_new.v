//Attribution : https://verilogcodes.blogspot.com/2020/12/synthesizable-matrix-multiplication-in.html
//Above post contained a 3x3 matrix multiplier code. We generalized it to multiply two nxn matrices

//n by n matrix multiplier. Each element of the matrix is "bitwidth" bits wide. 
//Inputs are named A and B and output is named as C. 
//Each matrix has n^2 elements each of which are "bitwidth" bits wide each. So the inputs are n^2*bitwidth=128 bits long.

module matrix_mult_new
    #(
        parameter order = 2, bitwidth = 32 //Default parameter values
    )
    (   input clk,
        input reset, //active high reset
        input enable,    //This should be High throughout the matrix multiplication process.
        input [0:1048576*32-1] matAarg, // Number that contains A's elements as bits. Input this to matrix_mult module
        input [0:1048576*32-1] matBarg, // Number that contains B's elements as bits. Input this to matrix_mult module
        output reg [0:1048576*32-1] matCarg,
        output reg rdy     //rdy high indicates that multiplication is done and result is availble at C.
    );   
reg [31:0] matAmem [0:1048575]; // 1D Array into which A's elements are written.
reg [31:0] matBmem [0:1048575]; // 1D Array into which B's elements are written.
reg [31:0] matCmem [0:1048575]; // 1D Array into which 2D matC's elements are written.
reg signed [bitwidth-1:0] matA [order-1:0][order-1:0];
reg signed [bitwidth-1:0] matB [order-1:0][order-1:0];
reg signed [bitwidth-1:0] matC [order-1:0][order-1:0];
integer i,j,k;                            // loop indices
reg first_cycle;                          // indicates its the first clock cycle after enable went High.
reg end_of_mult;                          // indicates multiplication has ended.
reg signed [2*bitwidth-1:0] temp;                   // register to hold the product of two elements.
integer flatten_index;
integer unflatten_index;

//Matrix multiplication.
always @(posedge clk or posedge reset)    
begin
    if(reset) begin    //Active high reset
        // $display("Resetting inside matrix_mult");
        i <= 0;
        j <= 0;
        k <= 0;
        temp <= 0;
        first_cycle = 1;
        end_of_mult <= 0;
        rdy <= 0;
        //Initialize all the matrix register elements to zero.
        for(i=0; i<=order-1; i=i+1) begin
            for(j=0; j<=order-1; j=j+1) begin
                matA[i][j] <= {bitwidth{1'd0}};
                matB[i][j] <= {bitwidth{1'd0}};
                matC[i][j] <= {bitwidth{1'd0}};
            end 
        end 
    end
    else begin
        if(enable && !end_of_mult)begin
            if(first_cycle) begin
                // Flattened numbers matAarg and matBarg are unflattened into matAmem and matBmem
                //NEED TO UNCOMMENT FOLLOWING LINE LATER    
                // for (unflatten_index = 0; unflatten_index < 1048576; unflatten_index = unflatten_index+1) begin
                for (unflatten_index = 0; unflatten_index < 4; unflatten_index = unflatten_index+1) begin
                    matAmem[unflatten_index] = matAarg[32*unflatten_index +: 32];
                    matBmem[unflatten_index] = matBarg[32*unflatten_index +: 32];
                end

                //Unflattened 1-D arrays matAmem and matBmem are converted to 2-D matrices
                $display("Starting to create 2d matrices\n");
                for(i=0; i<=order-1; i=i+1) begin
                    for(j=0; j<=order-1; j=j+1) begin
                        matA[i][j] = matAmem[(i*order+j)];
                        matB[i][j] = matBmem[(i*order+j)];
                        matC[i][j] = {bitwidth{1'd0}};
                    end 
                end
                $display("Done creating 2D matrices");
                // re-initalize registers before the start of multiplication.
                        first_cycle = 0;
                        end_of_mult = 0;
                        temp = 0;
                        i = 0;
                        j = 0;
                        k = 0;
        end
        end
        else begin
                //If it is not the first cycle after enable, do this
                if(end_of_mult == 0) begin     //multiplication hasnt ended. Keep multiplying.
                    $display("Doing actual multiplication\n");
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
                                $display("End of mult is made 1");
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
        else if(end_of_mult && !rdy) begin     
                //End of multiplication has reached
                //convert n by n matrix into a 1-D matrix.
                //All the first 'order' number of elements of matCmem are filled with the multiplication result
                //Other elements are zero anyways since we initialized all elements to zero at the beginning of axi4_mem_periph.v
                for(i=0; i<=order-1; i=i+1) begin   //run through the rows
                $display("Last second step of multiplication\n");
                    for(j=0; j<=order-1; j=j+1) begin    //run through the columns
                        // matCmem[(i*order+j)*bitwidth+:bitwidth] = matC[i][j];
                        matCmem[(i*order+j)] = matC[i][j];
                    end
                end   
                // Flatten the 1D array matCmem into a 1048576 bit number matCarg which is the output of this module
                //NEED TO UNCOMMENT FOLLOWING LINE LATER    
				// for (flatten_index = 0; flatten_index < 1048576; flatten_index = flatten_index+1) begin
                $display("Starting to flatten out multiplication result :)\n");
                for (flatten_index = 0; flatten_index < 4; flatten_index = flatten_index+1) begin
					matCarg[32*flatten_index +: 32] = matCmem[flatten_index];
				end
                rdy = 1;   //Set this output High, to say that C has the final result.
    end
end
    end
end
 
endmodule