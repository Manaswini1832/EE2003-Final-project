module axi4_mem_periph #(
	parameter AXI_TEST = 0,
	parameter VERBOSE = 0
) (
	/* verilator lint_off MULTIDRIVEN */

	input             clk,
	input             mem_axi_awvalid,
	output reg        mem_axi_awready,
	input      [31:0] mem_axi_awaddr,
	input      [ 2:0] mem_axi_awprot,

	input             mem_axi_wvalid,
	output reg        mem_axi_wready,
	input      [31:0] mem_axi_wdata,
	input      [ 3:0] mem_axi_wstrb,

	output reg        mem_axi_bvalid,
	input             mem_axi_bready,

	input             mem_axi_arvalid,
	output reg        mem_axi_arready,
	input      [31:0] mem_axi_araddr,
	input      [ 2:0] mem_axi_arprot,

	output reg        mem_axi_rvalid,
	input             mem_axi_rready,
	output reg [31:0] mem_axi_rdata,

	output reg        tests_passed
);	
	//Memory register instantiations
	reg [31:0] memory [0:2048*1024/4-1];
	reg [0:1048576*32-1] matAarg; // Number that contains A's elements as bits. Input this to matrix_mult module
	reg [0:1048576*32-1] matBarg; // Number that contains B's elements as bits. Input this to matrix_mult module
	wire [0:1048576*32-1] matCarg; // Number that should store C's elements as bits. This is the output from matrix_mult module

	//Reg, wire declarations for the inputs and outputs of the matrix_mult module
    reg reset = 0;
	wire rdy;
    reg [9:0]order = 0;
	reg enable = 0;

	integer unflatten_index = 0;
	integer flatten_index = 0;	
// 	integer order = 2;

	//Instantiating the matrix multiplier module
	matrix_mult_new #(.order(2), .bitwidth(32)) matrix_mult_new(
		.clk(clk), 
        .reset(reset),  
		.enable(enable),
        .matAarg(matAarg),
        .matBarg(matBarg), 
        .matCarg(matCarg),
        .rdy(rdy)
	);
	
	reg verbose;
	initial verbose = $test$plusargs("verbose") || VERBOSE;
	// initial verbose = 1;

	initial begin
		mem_axi_awready = 0;
		mem_axi_wready = 0;
		mem_axi_bvalid = 0;
		mem_axi_arready = 0;
		mem_axi_rvalid = 0;
		tests_passed = 0;
	end

	reg latched_raddr_en = 0;
	reg latched_waddr_en = 0;
	reg latched_wdata_en = 0;

	reg fast_raddr = 0;
	reg fast_waddr = 0;
	reg fast_wdata = 0;

	reg [31:0] latched_raddr;
	reg [31:0] latched_waddr;
	reg [31:0] latched_wdata;
	reg [ 3:0] latched_wstrb;
	reg        latched_rinsn;

	task handle_axi_arvalid; begin
		mem_axi_arready <= 1;
		latched_raddr = mem_axi_araddr;
		latched_rinsn = mem_axi_arprot[2];
		latched_raddr_en = 1;
		fast_raddr <= 1;
	end endtask

	task handle_axi_awvalid; begin
		mem_axi_awready <= 1;
		latched_waddr = mem_axi_awaddr;
		latched_waddr_en = 1;
		fast_waddr <= 1;
	end endtask

	task handle_axi_wvalid; begin
		mem_axi_wready <= 1;
		latched_wdata = mem_axi_wdata;
		latched_wstrb = mem_axi_wstrb;
		latched_wdata_en = 1;
		fast_wdata <= 1;
	end endtask

	task handle_axi_rvalid; begin
		if (verbose)
			$display("RD: ADDR=%08x DATA=%08x%s", latched_raddr, memory[latched_raddr >> 2], latched_rinsn ? " INSN" : "");
		if (latched_raddr < 2048*1024) begin
			mem_axi_rdata <= memory[latched_raddr >> 2];
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0;
		end else
		if (latched_raddr == 32'h3000_0000) begin
			// Return the multiplier status - bit 0 should reflect the rdy signal
			mem_axi_rdata <= rdy;
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; // Why?
		end else
		if (latched_raddr == 32'h3000_0004) begin
			// Send enable signal of the matrix_mult module back
			mem_axi_rdata <= enable;
			mem_axi_rvalid <= 1;
			latched_raddr_en = 0; // Why?
		end 
		else
		if ((latched_raddr >= 32'h4080_0000) && (latched_raddr <= 32'h40BF_FFFF)) begin
			//Send the apt element of C back(C has been calculated using the matrix_mult module)
			unflatten_index = (latched_raddr-'h4080_0000) >> 2;
			mem_axi_rdata = matCarg[32*unflatten_index +: 32];
			mem_axi_rvalid = 1;
			latched_raddr_en = 0; // Why?
		end
        else
            if (latched_raddr == 32'h3000_0008) begin
                $display("Reading order:");
			mem_axi_rdata <= order;
			mem_axi_rvalid = 1;
			latched_raddr_en = 0; // Why?
		end
		else begin
			$display("OUT-OF-BOUNDS MEMORY READ FROM %08x", latched_raddr);
			$finish;
		end
	end endtask

	task handle_axi_bvalid; begin
		if (verbose)
			$display("WR: ADDR=%08x DATA=%08x STRB=%04b", latched_waddr, latched_wdata, latched_wstrb);
		if (latched_waddr < 2048*1024) begin
			if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
			if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
			if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
			if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
		end else
		if (latched_waddr == 32'h1000_0000) begin
			if (verbose) begin
				if (32 <= latched_wdata && latched_wdata < 128)
					$display("OUT: '%c'", latched_wdata[7:0]);
				else
					$display("OUT: %3d", latched_wdata);
			end else begin
				$write("%c", latched_wdata[7:0]);
`ifndef VERILATOR
				$fflush();
`endif
			end
		end else
		// address below used by assembly in start.S - we are not using this
		if (latched_waddr == 32'h2000_0000) begin
			if (latched_wdata == 1)
				tests_passed = 1;
		end else 
		// Changed the target address for the 'all pass' so that it can be written from C
		if (latched_waddr == 32'h2100_0000) begin
			if (latched_wdata == 1)
				tests_passed = 1;
		end else 
		if (latched_waddr == 32'h3000_0000) begin // Checking for rdy signal
            reset <= latched_wdata;
			$display("Write %3d to the reset signal", latched_wdata);
		end else
		if (latched_waddr == 32'h3000_0004) begin // Enabling or disabling the matrix multiplier
			enable <= latched_wdata;
			$display("Write %3d to the enable signal", latched_wdata);
		end 
        else
            if (latched_waddr == 32'h3000_0008) begin
                $display("Write %3d to the order signal", latched_wdata);
                      order <= latched_wdata;
		end
		else
		if ((latched_waddr >= 32'h4000_0000) && (latched_waddr <= 32'h403F_FFFF)) begin
			//Flattening out latched_wdata so that matrix_mult receives correct input
			flatten_index = (latched_waddr-'h4000_0000) >> 2;
			matAarg[32*flatten_index +: 32] = latched_wdata;	
		end else
		if ((latched_waddr >= 32'h4040_0000) && (latched_waddr <= 32'h407F_FFFF)) begin
			//Flattening out latched_wdata so that matrix_mult receives correct input
			flatten_index = (latched_waddr-'h4040_0000) >> 2;
			matBarg[32*flatten_index +: 32] = latched_wdata;	
		end 
        
        else
		if ((latched_waddr >= 32'h4080_0000) && (latched_waddr <= 32'h40BF_FFFF)) begin
			//Can't write into C from hello.c
			$display("Can't write into this memory location\n");
		end
        
		else begin
			$display("OUT-OF-BOUNDS MEMORY WRITE TO %08x", latched_waddr);
			$finish;
		end
		mem_axi_bvalid <= 1;
		latched_waddr_en = 0;
		latched_wdata_en = 0;
	end endtask

	always @(negedge clk) begin
		if (mem_axi_arvalid && !(latched_raddr_en || fast_raddr)) handle_axi_arvalid;
		if (mem_axi_awvalid && !(latched_waddr_en || fast_waddr)) handle_axi_awvalid;
		if (mem_axi_wvalid  && !(latched_wdata_en || fast_wdata)) handle_axi_wvalid;
		if (!mem_axi_rvalid && latched_raddr_en) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en) handle_axi_bvalid;
	end

	always @(posedge clk) begin
		mem_axi_arready <= 0;
		mem_axi_awready <= 0;
		mem_axi_wready <= 0;

		fast_raddr <= 0;
		fast_waddr <= 0;
		fast_wdata <= 0;

		if (mem_axi_rvalid && mem_axi_rready) begin
			mem_axi_rvalid <= 0;
		end

		if (mem_axi_bvalid && mem_axi_bready) begin
			mem_axi_bvalid <= 0;
		end

		if (mem_axi_arvalid && mem_axi_arready && !fast_raddr) begin
			latched_raddr = mem_axi_araddr;
			latched_rinsn = mem_axi_arprot[2];
			latched_raddr_en = 1;
		end

		if (mem_axi_awvalid && mem_axi_awready && !fast_waddr) begin
			latched_waddr = mem_axi_awaddr;
			latched_waddr_en = 1;
		end

		if (mem_axi_wvalid && mem_axi_wready && !fast_wdata) begin
			latched_wdata = mem_axi_wdata;
			latched_wstrb = mem_axi_wstrb;
			latched_wdata_en = 1;
		end

		if (mem_axi_arvalid && !(latched_raddr_en || fast_raddr)) handle_axi_arvalid;
		if (mem_axi_awvalid && !(latched_waddr_en || fast_waddr)) handle_axi_awvalid;
		if (mem_axi_wvalid  && !(latched_wdata_en || fast_wdata)) handle_axi_wvalid;

		if (!mem_axi_rvalid && latched_raddr_en) handle_axi_rvalid;
		if (!mem_axi_bvalid && latched_waddr_en && latched_wdata_en) handle_axi_bvalid;
	end
endmodule
