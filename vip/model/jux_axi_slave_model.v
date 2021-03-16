module jux_axi_slave_model
(
	 	clk,
		rstn,

		// AXI write address channel
		awaddr,
		awsize,   
		awburst,  
		awid,
		awlen,
		awvalid,
		awready,

		// AXI write data channel
		wdata,
		wstrb,
		wlast,
		wvalid,
		wready,
		bresp,
		bid,
		bvalid,
		bready,

		// AXI read address channel
		araddr,
		arsize,   
		arburst,  
		arid,
		arlen,
		arvalid,
		arready,

		// AXI read data channel

		rdata,
		rid,
		rresp,
		rlast,
		rvalid,
		rready
);

parameter DATA_WIDTH = 2;	// Width of data bus is (1 << DATA_WIDTH) bytes
parameter ADDR_WIDTH = 32;	// Width of address bus in bits
parameter ID_WIDTH = 4;
parameter MEM_SIZE = 16;	// memory size = 1 << MEM_SIZE
parameter bit	AXI4 = 1'b1;		// 1: AXI4 (8-bit AxLEN), 0: AXI3 (4-bit AxLEN).
parameter bit	AXI4_AXLEN_LT16 = 1'b1;	// Indicate to use less-than-16 AxLEN even in AXI4.

//----- Derived parameters -----//
localparam DATA_BYTES = 1 << DATA_WIDTH;
localparam DATA_BITS = DATA_BYTES * 8;
localparam AXLEN_WIDTH = 4 + (AXI4 * 4);

localparam ST_R_IDLE = 2'd0;
localparam ST_R_READ = 2'd1;
localparam ST_R_END  = 2'd2;

localparam ST_W_IDLE  = 2'd0;
localparam ST_W_WRITE = 2'd1;
localparam ST_W_END   = 2'd2;

input           clk;
input           rstn;

// AXI write address channel
input	[ADDR_WIDTH-1:0]	awaddr;
input 	[2:0]			awsize;
input	[1:0]			awburst;
input	[ID_WIDTH-1:0]  	awid;
input	[AXLEN_WIDTH-1:0]   	awlen;
input           		awvalid;
output          		awready;

// AXI write data channel
input   [DATA_BITS-1:0]  	wdata;
input   [DATA_BYTES-1:0]   	wstrb;
input           		wlast;
input           		wvalid;
output          		wready;

// AXI write resp channel
output  [ID_WIDTH-1:0]   	bid;
output  [1:0]   		bresp;
output          		bvalid;
input           		bready;



// AXI read address channel
input   [ADDR_WIDTH-1:0]  	araddr;
input 	[2:0]			arsize;
input	[1:0]			arburst;
input   [ID_WIDTH-1:0]   	arid;
input   [AXLEN_WIDTH-1:0] 	arlen;
input         			arvalid;
output        			arready;

// AXI read data channel
output  [DATA_BITS-1:0]  	rdata;
output  [ID_WIDTH-1:0]   	rid;
output  [1:0]   		rresp;
output          		rlast;
output          		rvalid;
input           		rready;

reg     [1:0] 			r_cs;
reg     [1:0] 			r_ns;
reg     [1:0] 			w_cs;
reg     [1:0] 			w_ns;

reg     [3:0] 			rdcnt;
reg     [31:0]			reg_araddr;
reg	[2:0]			reg_arsize;
reg	[1:0]			reg_arburst;
reg     [AXLEN_WIDTH-1:0] 	reg_arlen;
reg     [ID_WIDTH-1:0] 		reg_arid;

reg	[ADDR_WIDTH-1:0]	next_raddr;

wire	[ADDR_WIDTH-1:0]	rbytes;
wire	[ADDR_WIDTH-1:0]	raddr_mask;
wire	[ADDR_WIDTH-1:0]	raddr_incr;
wire	[2+AXI4:0]		rlen_bits;
wire	[ADDR_WIDTH-1:0]	rwrap_bytes;
wire	[ADDR_WIDTH-1:0]	rwrap_mask;

reg				is_first_rctl;
wire 	[ADDR_WIDTH-1:0]	current_araddr;
wire	[2:0]			current_arsize;
wire	[1:0]			current_arburst;
wire	[AXLEN_WIDTH-1:0] 	current_arlen;
wire	[ID_WIDTH-1:0] 		current_arid;

reg     [3:0] 			wdcnt;
reg     [31:0]			reg_awaddr;
reg	[2:0]			reg_awsize;
reg	[1:0]			reg_awburst;
reg     [AXLEN_WIDTH-1:0] 	reg_awlen;
reg     [ID_WIDTH-1:0]  	reg_awid;

reg	[ADDR_WIDTH-1:0]	next_waddr;

wire	[ADDR_WIDTH-1:0]	wbytes;
wire	[ADDR_WIDTH-1:0]	waddr_mask;
wire	[ADDR_WIDTH-1:0]	waddr_incr;
wire	[2+AXI4:0]		wlen_bits;
wire	[ADDR_WIDTH-1:0]	wwrap_bytes;
wire	[ADDR_WIDTH-1:0]	wwrap_mask;

reg				is_first_wctl;
wire 	[ADDR_WIDTH-1:0]	current_awaddr;
wire	[2:0]			current_awsize;
wire	[1:0]			current_awburst;
wire	[AXLEN_WIDTH-1:0] 	current_awlen;
wire	[ID_WIDTH-1:0] 		current_awid;

reg     [5:0] 			axi_wait_cnt_0;
reg     [5:0] 			axi_wait_cnt_1;
reg     [5:0] 			axi_wait_num_0;
reg     [5:0] 			axi_wait_num_1;
reg     [31:0]			rdn_num_0;
reg     [31:0]			rdn_num_1;

reg     [31:0] 			reg_rdata;
reg     [7:0] 			rnd_data;
reg     [7:0] 			mem[0:1<<MEM_SIZE];
reg 	[31:0] 			seed;

integer 			i;
initial begin
	if ($value$plusargs("seed=%d", seed))
		seed = seed ^ 32'h8f385027;
	else
		seed = 32'h8f385027;
end

initial begin
	for (i = 0; i < (1 << MEM_SIZE); i = i + 1) begin
		rnd_data	= {$random(seed)};
		mem[i] 		= rnd_data;
	end
end

always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		rdn_num_0 <= 32'd0;
		rdn_num_1 <= 32'd0;
	end else begin
		rdn_num_0 <= $random;
		rdn_num_1 <= $random;
	end
end

always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		axi_wait_cnt_0 <= 6'd0;
		axi_wait_num_0 <= 6'd8;
	end 
	else if (arvalid & arready) begin
		axi_wait_cnt_0 <= 6'd0;
		axi_wait_num_0 <= rdn_num_0[5:0];
	end 
	else if (arvalid & !arready) begin
		if (axi_wait_cnt_0==axi_wait_num_0) begin
			axi_wait_cnt_0 <= 5'd0;
		end
		else begin
			axi_wait_cnt_0 <= axi_wait_cnt_0 + 1'b1;
		end
	end
end

always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		axi_wait_cnt_1 <= 6'd0;
		axi_wait_num_1 <= 6'd8;
	end 
	else if (awvalid & awready) begin
		axi_wait_cnt_1 <= 6'd0;
		axi_wait_num_1 <= rdn_num_1[5:0];
	end 
	else if (awvalid & !awready) begin
		if (axi_wait_cnt_1==axi_wait_num_1) begin
			axi_wait_cnt_1 <= 5'd0;
		end 
		else begin
			axi_wait_cnt_1 <= axi_wait_cnt_1 + 1'b1;
		end
	end
end

//------------------------------------------------------------------------------------------------
`ifdef AXI_BUSY
assign arready = (r_cs==ST_R_IDLE) & (axi_wait_cnt_0==axi_wait_num_0);
`else
assign arready = (r_cs==ST_R_IDLE);
`endif

assign rresp   = 2'b00;
assign rvalid  = (r_cs==ST_R_READ);
assign rlast   = rvalid & (rdcnt==reg_arlen);
assign rid     = reg_arid;
//==== 11/25 jason +delay==========
assign #(1) rdata   = reg_rdata;

always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		r_cs <= ST_R_IDLE;
	end 
	else begin
		r_cs <= r_ns;
	end
end

always@(*) begin
	r_ns = r_cs;
	case (r_cs)
		ST_R_IDLE : r_ns = (arvalid & arready) ? ST_R_READ : r_cs;
		ST_R_READ : r_ns = (rvalid & rready & rdcnt==reg_arlen) ? ST_R_END : r_cs;
		ST_R_END  : r_ns = ST_R_IDLE;
	endcase
end


always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		rdcnt <= 4'd0;
	end 
	else if (rvalid & rready) begin
		if (rdcnt==reg_arlen) begin
			rdcnt <= 4'd0;
		end else begin
			rdcnt <= rdcnt + 1'b1;
		end
	end
end

always@(posedge clk) begin
	if (arvalid & arready) begin
		reg_araddr 	<= araddr;
    		reg_arlen  	<= arlen;
		reg_arid   	<= arid;
		reg_arsize	<= arsize;
		reg_arburst	<= arburst;	
	end
end

always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		is_first_rctl <= 1'b1;
	end
//============ 11/19 delete if (rready) =======================	
	else if (rvalid) begin
		if (rlast)
			is_first_rctl <= 1'b1;
		else
			is_first_rctl <= 1'b0;
	end
end

assign current_araddr 	= is_first_rctl ? reg_araddr : next_raddr;
assign current_arsize 	= reg_arsize;
assign current_arburst 	= reg_arburst;
assign current_arlen 	= reg_arlen;
assign current_arid	= reg_arid;

assign rbytes = 1 << current_arsize;
assign raddr_mask = (rbytes - {{(ADDR_WIDTH-1){1'b0}}, 1'b1});
assign raddr_incr[11:0] = (current_araddr & ~raddr_mask) + rbytes;
assign raddr_incr[ADDR_WIDTH-1:12] = current_araddr[ADDR_WIDTH-1:12];

generate
	if (AXI4) begin : axi4_arlen 
		assign rlen_bits = current_arlen[7] ? 4'd8 :
				   current_arlen[6] ? 4'd7 :
				   current_arlen[5] ? 4'd6 :
				   current_arlen[4] ? 4'd5 :
				   current_arlen[3] ? 4'd4 :
				   current_arlen[2] ? 4'd3 :
				   current_arlen[1] ? 4'd2 :
			 	   current_arlen[0] ? 4'd1 : 4'd0;
	end
	else begin : axi3_arlen
		assign rlen_bits = current_arlen[3] ? 3'd4 :
				   current_arlen[2] ? 3'd3 :
				   current_arlen[1] ? 3'd2 :
			 	   current_arlen[0] ? 3'd1 : 3'd0;	
	end
endgenerate

assign rwrap_bytes = 1 << (rlen_bits + {{AXI4{1'b0}}, current_arsize});
assign rwrap_mask = (rwrap_bytes - {{(ADDR_WIDTH-1){1'b0}}, 1'b1});

always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		next_raddr <= 32'h0;
	end
//========= 11/19 delete if(rready)==================	
	if (rvalid) begin
		case (current_arburst)
		2'b00: // FIXED
			next_raddr <= current_araddr;
		
		2'b01: // INCR
			next_raddr <= raddr_incr;
		
		2'b10: // WRAP
			next_raddr <= (current_araddr & ~rwrap_mask) | (raddr_incr & rwrap_mask);
		
		default: // Reserved
			;
		endcase
	end
end
//========= 11/19 delete rready ========================
always@(posedge clk) begin
	if (rvalid ) begin
		read_mem(current_araddr,reg_rdata);
	end
end

//------------------------------------------------------------------------------------------------
always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		w_cs <= ST_W_IDLE;
	end else begin
		w_cs <= w_ns;
	end
end

always@(*) begin
	w_ns = w_cs;
	case (w_cs)
		ST_W_IDLE  : w_ns = (awvalid & awready) ? ST_W_WRITE : w_cs;
		ST_W_WRITE : w_ns = (wvalid & wready & wdcnt==reg_awlen) ? ST_W_END : w_cs;
		ST_W_END   : w_ns = (bvalid & bready) ? ST_W_IDLE : w_cs;
	endcase
end

always@(posedge clk or negedge rstn) begin
	if (!rstn) begin
		wdcnt <= 4'd0;
	end else if (wvalid & wready) begin
		if (wdcnt==reg_awlen) begin
			wdcnt <= 4'd0;
		end else begin
			wdcnt <= wdcnt + 1'b1;
		end
	end
end

always@(posedge clk) begin
	if (awvalid & awready) begin
		reg_awaddr 	<= awaddr;
    		reg_awlen  	<= awlen;
		reg_awid   	<= awid;
		reg_awsize	<= awsize;
		reg_awburst	<= awburst;	
	end
end

always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		is_first_wctl <= 1'b1;
	end
	else if (wvalid && wready) begin
		if (wlast)
			is_first_wctl <= 1'b1;
		else
			is_first_wctl <= 1'b0;
	end
end

assign current_awaddr 	= is_first_wctl ? reg_awaddr : next_waddr;
assign current_awsize 	= reg_awsize;
assign current_awburst 	= reg_awburst;
assign current_awlen 	= reg_awlen;
assign current_awid	= reg_awid;

assign wbytes = 1 << current_awsize;
assign waddr_mask = (wbytes - {{(ADDR_WIDTH-1){1'b0}}, 1'b1});
assign waddr_incr[11:0] = (current_awaddr & ~waddr_mask) + wbytes;
assign waddr_incr[ADDR_WIDTH-1:12] = current_awaddr[ADDR_WIDTH-1:12];

generate
	if (AXI4) begin : axi4_awlen 
		assign wlen_bits = current_awlen[7] ? 4'd8 :
				   current_awlen[6] ? 4'd7 :
				   current_awlen[5] ? 4'd6 :
				   current_awlen[4] ? 4'd5 :
				   current_awlen[3] ? 4'd4 :
				   current_awlen[2] ? 4'd3 :
				   current_awlen[1] ? 4'd2 :
			 	   current_awlen[0] ? 4'd1 : 4'd0;
	end
	else begin : axi3_awlen
		assign wlen_bits = current_awlen[3] ? 3'd4 :
				   current_awlen[2] ? 3'd3 :
				   current_awlen[1] ? 3'd2 :
			 	   current_awlen[0] ? 3'd1 : 3'd0;	
	end
endgenerate

assign wwrap_bytes = 1 << (wlen_bits + {{AXI4{1'b0}}, current_awsize});
assign wwrap_mask = (wwrap_bytes - {{(ADDR_WIDTH-1){1'b0}}, 1'b1});

always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		next_waddr <= 32'h0;
	end
	if (wvalid && wready) begin
		case (current_awburst)
		2'b00: // FIXED
			next_waddr <= current_awaddr;
		
		2'b01: // INCR
			next_waddr <= waddr_incr;
		
		2'b10: // WRAP
			next_waddr <= (current_awaddr & ~wwrap_mask) | (waddr_incr & wwrap_mask);
		
		default: // Reserved
			;
		endcase
	end
end

always@(posedge clk) begin
	if (wvalid & wready) begin
		write_mem(current_awaddr, wstrb ,wdata);
	end
end

// for error checking
always@(posedge clk) begin
	if (wvalid & wready) begin
		if (wdcnt==reg_awlen & !wlast) begin
			$display("[FAIL]: reg_awlen does not match with wlast");
			$finish;
		end
		if (wdcnt!=reg_awlen & wlast) begin
			$display("[FAIL]: reg_awlen does not match with wlast");
			$finish;
		end
	end
end

`ifdef AXI_BUSY
assign awready = (w_cs==ST_W_IDLE) & (axi_wait_cnt_1==axi_wait_num_1);
`else
assign awready = (w_cs==ST_W_IDLE);
`endif

assign wready  = (w_cs==ST_W_WRITE);
assign bresp   = 2'b00;
assign bid     = reg_awid;
assign bvalid  = (w_cs==ST_W_END);

task read_mem;
input   [MEM_SIZE-1:0]		addr;
output 	[DATA_BITS-1:0]		data;
reg 	[DATA_BITS-1:0] 	data;
begin
	data[7:0] = mem[addr];
	data[15:8] = mem[addr + 1];
	data[23:16] = mem[addr + 2];
	data[31:24] = mem[addr + 3];
	$display("%0t:%m:Read mem address 0x%x, data 0x%x", $realtime, addr, data);
end
endtask

task write_mem;
input   [MEM_SIZE-1:0]		addr;
input   [DATA_BYTES-1:0]   	wstrb;
input   [DATA_BITS-1:0]		data;
begin	
	if (wstrb[0])
		mem[addr] = data[7:0];
	if (wstrb[1])
		mem[addr + 1] = data[15:8];
	if (wstrb[2])
		mem[addr + 2] = data[23:16];
	if (wstrb[3])
		mem[addr + 3] = data[31:24];
	$display("%0t:%m:Write mem address 0x%x, data 0x%x, wstrb 0x%x", $realtime, addr, {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]}, wstrb);
end
endtask
endmodule

