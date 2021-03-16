reg 	[1:0] 			wr_bresp;
reg 	[31:0] 			rand_addr;
reg 	[AXLEN_WIDTH-1:0] 	rand_len;
reg 	[1:0] 			rand_burst;
integer i;
integer j;
initial begin
	wait (aresetn);
	@(posedge aclk);
	@(posedge aclk);

	for (i = 0; i < 20; i = i + 1) begin
//		rand_addr 	= $random%(1<<12);
		rand_addr 	= $random;

//		rand_addr[1:0] 	= 2'b0;
//		rand_addr[31:12]= 24'b1;
		rand_len 	= 8'hf;
//		rand_len 	= 8'd255;
//		rand_len 	= $random;

//		rand_burst 	= 2'h1;
		rand_burst 	= $random;


		for (j = 0; j <= rand_len; j = j + 1) begin
			reg_wdata[j] = $random;
			reg_wstrb[j] = 4'hf;
//			reg_wstrb[j] = $random;

		end
		
		write_data(4'h0, rand_addr, rand_len, 3'h2, rand_burst, 2'h0, 4'h0, 3'h0, wr_bresp);
		//$display("%0t:%m: Write data with addr 0x%x, data 0x%x, wstrb 0x%x", $realtime, rand_addr, reg_wdata[0], reg_wstrb[0]);
		read_data(4'h0, rand_addr, rand_len, 3'h2, rand_burst, 2'h0, 4'h0, 3'h0);
		//$display("%0t:%m: Read data with addr 0x%x, data 0x%x", $realtime, rand_addr, reg_rdata[0]);
	end
end
