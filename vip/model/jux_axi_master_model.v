//---------------------------------------------------------------------------//
// AXI Master model.

// * Elementary APIs:
// task send_waddr(i_id, i_addr, i_len, i_size, i_burst, i_lock, i_cache, i_prot);
// task send_raddr(i_id, i_addr, i_len, i_size, i_burst, i_lock, i_cache, i_prot);
// task send_wdata(i_id, i_data, i_strb, i_last);
// task get_bresp(o_id, o_resp);
// task get_rdata(o_id, o_data, o_resp, o_last);
//
// * Tasks for settin delay cycles
// * Initial delay cycle is a random value in 0~10
// task set_fix_delay_cycle(cycle_cnt);
// task set_random_delay_cycle(cycle_min, cycle_max);
// task clr_delay_cycle;
//
// * Macro APIs:
// task write_data
// task read_data

//---------------------------------------------------------------------------//

module jux_axi_master_model (
	  aclk,     
	  aresetn,  
	  awid,     
	  awaddr,   
	  awlen,    
	  awsize,   
	  awburst,  
	  awlock,   
	  awcache,  
	  awprot,   
	  awvalid,  
	  awready,  
	  wdata,    
	  wstrb,    
	  wlast,    
	  wvalid,   
	  wready,   
	  bid,      
	  bresp,    
	  bvalid,   
	  bready,   	
	  arid,     
	  araddr,   
	  arlen,    
	  arsize,   
	  arburst,  
	  arlock,   
	  arcache,  
	  arprot,   
	  arvalid,  
	  arready,  
	  rid,      
	  rdata,    
	  rresp,    
	  rlast,    
	  rvalid,   
	  rready    
);


//----- Configurable parameters -----//
parameter DATA_WIDTH = 3;	// Width of data bus is (1 << DATA_WIDTH) bytes
parameter ADDR_WIDTH = 32;	// Width of address bus in bits
parameter ID_WIDTH = 4;
parameter bit	AXI4 = 1'b1;		// 1: AXI4 (8-bit AxLEN), 0: AXI3 (4-bit AxLEN).
parameter bit	AXI4_AXLEN_LT16 = 1'b1;	// Indicate to use less-than-16 AxLEN even in AXI4.

parameter OUT_DELAY = 0.4;
parameter AWVALID_WAIT_CYCLE_MAX = 10;
parameter ARVALID_WAIT_CYCLE_MAX = 10;
parameter WVALID_WAIT_CYCLE_MAX  = 10;
parameter BREADY_WAIT_CYCLE_MAX  = 10;
parameter RREADY_WAIT_CYCLE_MAX  = 10;
parameter WAIT_TIMEOUT_CNT 	= 1000000;
parameter DELAY_CYCLE_MIN	= 0;
parameter DELAY_CYCLE_MAX	= 10;

//----- Derived parameters -----//
localparam DATA_BYTES = 1 << DATA_WIDTH;
localparam DATA_BITS = DATA_BYTES * 8;
localparam AXLEN_WIDTH = 4 + (AXI4 * 4);

//----- I/O declarations -----//
// Global signals
input				aclk;
input				aresetn;

// Write address channel signals
output [ID_WIDTH-1:0]		awid;
output [ADDR_WIDTH-1:0]		awaddr;
output [AXLEN_WIDTH-1:0]	awlen;
output [2:0]			awsize;
output [1:0]			awburst;
output [1:0]			awlock;
output [3:0]			awcache;
output [2:0]			awprot;
output				awvalid;
input				awready;

// Write data channel signals
output [DATA_BITS-1:0]		wdata;
output [DATA_BYTES-1:0]		wstrb;
output				wlast;
output				wvalid;
input				wready;

// Write response channel signals
input [ID_WIDTH-1:0]		bid;
input [1:0]			bresp;
input				bvalid;
output				bready;

// Read address channel signals
output [ID_WIDTH-1:0]		arid;
output [ADDR_WIDTH-1:0]		araddr;
output [AXLEN_WIDTH-1:0]	arlen;
output [2:0]			arsize;
output [1:0]			arburst;
output [1:0]			arlock;
output [3:0]			arcache;
output [2:0]			arprot;
output				arvalid;
input				arready;

// Read data channel signals
input [ID_WIDTH-1:0]		rid;
input [DATA_BITS-1:0]		rdata;
input [1:0]			rresp;
input				rlast;
input				rvalid;
output				rready;


//----- Variable declarations -----//
// Write address channel signals
reg [ID_WIDTH-1:0]		p_awid;
reg [ADDR_WIDTH-1:0]		p_awaddr;
reg [AXLEN_WIDTH-1:0]		p_awlen;
reg [2:0]			p_awsize;
reg [1:0]			p_awburst;
reg [1:0]			p_awlock;
reg [3:0]			p_awcache;
reg [2:0]			p_awprot;
reg				p_awvalid;

// Write data channel signals
reg [DATA_BITS-1:0]		p_wdata;
reg [DATA_BYTES-1:0]		p_wstrb;
reg				p_wlast;
reg				p_wvalid;

// Write response channel signals
reg				p_bready;

// Read address channel signals
reg [ID_WIDTH-1:0]		p_arid;
reg [ADDR_WIDTH-1:0]		p_araddr;
reg [AXLEN_WIDTH-1:0]		p_arlen;
reg [2:0]			p_arsize;
reg [1:0]			p_arburst;
reg [1:0]			p_arlock;
reg [3:0]			p_arcache;
reg [2:0]			p_arprot;
reg				p_arvalid;

// Read data channel signals
reg				p_rready;

int unsigned			seed;
integer				delay_type;	// 0: disable, 1: random cycles
reg [31:0]			delay_cnt;
reg [31:0]			delay_max;
reg [31:0]			delay_min;


reg [DATA_BITS-1:0] 		reg_wdata[0:15];
reg [DATA_BYTES-1:0] 		reg_wstrb[0:15];

reg [DATA_BITS-1:0] 		reg_rdata[0:15];
reg [1:0] 			reg_rresp[0:15];

initial begin
	if ($value$plusargs("seed=%d", seed))
		seed = seed ^ 32'h8f385027;
	else
		seed = 32'h8f385027;
	delay_type=0;
	delay_cnt=3;
	delay_max=DELAY_CYCLE_MAX;
	delay_min=DELAY_CYCLE_MIN;
	get_next_delay_cycle(delay_cnt);
end

always @(posedge aclk or negedge aresetn) begin
	if (~aresetn) begin
		p_awvalid	<= 1'b0;
		p_wvalid	<= 1'b0;
		p_bready	<= 1'b0;

		p_arvalid	<= 1'b0;
		p_rready	<= 1'b0;
	end
end

task set_random_delay_cycle;
input [31:0]	cycle_max;
input [31:0]	cycle_min;
begin
	delay_type=1;
	delay_max=cycle_max;
	delay_min=cycle_min;
	get_next_delay_cycle(delay_cnt);
end
endtask

task clr_delay_cycle;
begin
	delay_type=0;
	delay_cnt=32'd0;
	delay_max=32'd0;
	delay_min=32'd0;

end
endtask

task get_next_delay_cycle;
output [31:0] o_delay;
begin
	if (delay_type==0) begin
		o_delay = 0;
	end
	else if (delay_type == 1)begin
		delay_cnt = ({$random(seed)} % (delay_max - delay_min)) + delay_min;
		o_delay=delay_cnt;
	end
end
endtask

//----- Model specific task/function definitions -----//
// Initiate a write transaction via the write address channel
task send_waddr;
input [ID_WIDTH-1:0]		i_id;
input [ADDR_WIDTH-1:0]		i_addr;
input [AXLEN_WIDTH-1:0]		i_len;
input [2:0]			i_size;
input [1:0]			i_burst;
input [1:0]			i_lock;
input [3:0]			i_cache;
input [2:0]			i_prot;

reg [31:0]			wait_cnt;
reg done;
integer cycle_count;
begin
	wait (~p_awvalid) ;

	get_next_delay_cycle(wait_cnt);
	while (wait_cnt > 0) begin
		@(posedge aclk) wait_cnt = wait_cnt - 1;
	end

	p_awvalid 	<= 1'b1;
	p_awid		<= i_id;
	p_awaddr	<= i_addr;
	p_awlen		<= i_len;
	p_awsize	<= i_size;
	p_awburst	<= i_burst;
	p_awlock	<= i_lock;
	p_awcache	<= i_cache;
	p_awprot	<= i_prot;

	done = 1'b0;
	cycle_count = 0;
	while (~done && (cycle_count < WAIT_TIMEOUT_CNT)) begin
		#0.001 ;
		@(posedge aclk) ;
		if (awready & awvalid)
			done = 1'b1;
		cycle_count = cycle_count + 1;
		if (cycle_count === WAIT_TIMEOUT_CNT) begin
			$display("%0t:%m:ERROR:TIMEOUT:awready is not asserted within %0d cycles", $realtime, cycle_count);
			#1 $finish;
		end
	end

	p_awvalid	<= 1'b0;
	p_awid		<= {ID_WIDTH{1'bx}};
	p_awaddr	<= {ADDR_WIDTH{1'bx}};
	p_awlen		<= {AXLEN_WIDTH{1'hx}};
	p_awsize	<= 3'hx;
	p_awburst	<= 2'hx;
	p_awlock	<= 2'hx;
	p_awcache	<= 4'hx;
	p_awprot	<= 3'hx;
end
endtask


// Initiate a read transaction via the read address channel
task send_raddr;
input [ID_WIDTH-1:0]		i_id;
input [ADDR_WIDTH-1:0]		i_addr;
input [AXLEN_WIDTH-1:0]		i_len;
input [2:0]			i_size;
input [1:0]			i_burst;
input [1:0]			i_lock;
input [3:0]			i_cache;
input [2:0]			i_prot;

reg [31:0]			wait_cnt;
reg done;
integer cycle_count;
begin
	wait (~p_arvalid) ;

	get_next_delay_cycle(wait_cnt);
	while (wait_cnt > 0) begin
		@(posedge aclk) wait_cnt = wait_cnt - 1;
	end

	p_arvalid	<= 1'b1;
	p_arid		<= i_id;
	p_araddr	<= i_addr;
	p_arlen		<= i_len;
	p_arsize	<= i_size;
	p_arburst	<= i_burst;
	p_arlock	<= i_lock;
	p_arcache	<= i_cache;
	p_arprot	<= i_prot;

	done = 1'b0;
	cycle_count = 0;
	while (~done && (cycle_count < WAIT_TIMEOUT_CNT)) begin
		#0.001 ;
		@(posedge aclk) ;
		if (arready & arvalid)
			done = 1'b1;
		cycle_count = cycle_count + 1;
		if (cycle_count === WAIT_TIMEOUT_CNT) begin
			$display("%0t:%m:ERROR:TIMEOUT:arready is not asserted within %0d cycles", $realtime, cycle_count);
			#1 $finish;
		end
	end

	p_arvalid	<= 1'b0;
	p_arid		<= {ID_WIDTH{1'bx}};
	p_araddr	<= {ADDR_WIDTH{1'bx}};
	p_arlen		<= {AXLEN_WIDTH{1'hx}};
	p_arsize	<= 3'hx;
	p_arburst	<= 2'hx;
	p_arlock	<= 2'hx;
	p_arcache	<= 4'hx;
	p_arprot	<= 3'hx;
end
endtask


// Perform a data transfer via the write data channel
task send_wdata;
input [ID_WIDTH-1:0]		i_id;
input [DATA_BITS-1:0]		i_data;
input [DATA_BYTES-1:0]		i_strb;
input				i_last;

reg [31:0]			wait_cnt;
reg done;
integer cycle_count;
begin
	wait (~p_wvalid) ;

	get_next_delay_cycle(wait_cnt);
	while (wait_cnt > 0) begin
		@(posedge aclk) wait_cnt = wait_cnt - 1;
	end

	p_wvalid	<= 1'b1;
	p_wdata		<= i_data;
	p_wstrb		<= i_strb;
	p_wlast		<= i_last;

	done = 1'b0;
	cycle_count = 0;
	while (~done && (cycle_count < WAIT_TIMEOUT_CNT)) begin
		#0.001 ;
		@(posedge aclk) ;
		if (wready & wvalid)
			done = 1'b1;
		cycle_count = cycle_count + 1;
		if (cycle_count === WAIT_TIMEOUT_CNT) begin
			$display("%0t:%m:ERROR:TIMEOUT:wready is not asserted within %0d cycles", $realtime, cycle_count);
			#1 $finish;
		end
	end

	p_wvalid	<= 1'b0;
	p_wdata		<= {DATA_BITS{1'bx}};
	p_wstrb		<= {DATA_BYTES{1'bx}};
	p_wlast		<= 1'bx;
	
end
endtask

// Get BID and BRESP from the write response channel
task get_bresp;
output [ID_WIDTH-1:0]		o_id;
output [1:0]			o_resp;

reg [31:0]			wait_cnt;
reg done;
integer cycle_count;
begin
	wait (~p_bready) ;

	get_next_delay_cycle(wait_cnt);
	while (wait_cnt > 0) begin
		@(posedge aclk) wait_cnt = wait_cnt - 1;
	end

	p_bready	<= 1'b1;

	done = 1'b0;
	cycle_count = 0;
	while (~done && (cycle_count < WAIT_TIMEOUT_CNT)) begin
		#0.001 ;
		@(posedge aclk) ;
		if (bvalid & bready)
			done = 1'b1;
		cycle_count = cycle_count + 1;
		if (cycle_count === WAIT_TIMEOUT_CNT) begin
			$display("%0t:%m:ERROR:TIMEOUT:bvalid is not asserted within %0d cycles", $realtime, cycle_count);
			#1 $finish;
		end
	end

	o_id		= bid;
	o_resp		= bresp;

	p_bready	<= 1'b0;
end
endtask

task get_rdata;
output [ID_WIDTH-1:0]		o_id;
output [DATA_BITS-1:0]		o_data;
output [1:0]			o_resp;
output				o_last;

reg [31:0]			wait_cnt;
reg done;
integer cycle_count;
begin
	wait (~p_rready);
	get_next_delay_cycle(wait_cnt);
	while (wait_cnt > 0) begin
		@(posedge aclk) wait_cnt = wait_cnt - 1;
	end
	p_rready	<= 1'b1;

	done = 1'b0;
	cycle_count = 0;
	while (~done && (cycle_count < WAIT_TIMEOUT_CNT)) begin
		@(posedge aclk) ;
		if (rvalid & rready)
			done = 1'b1;
		cycle_count = cycle_count + 1;
		if (cycle_count === WAIT_TIMEOUT_CNT) begin
			$display("%0t:%m:ERROR:TIMEOUT:rvalid is not asserted within %0d cycles", $realtime, cycle_count);
			#1 $finish;
		end
	end

	o_id		= rid;
	o_data		= rdata;
	o_resp		= rresp;
	o_last		= rlast;

	p_rready	<= 1'b0;

end
endtask

task write_data;
// write addr channel
input  [ID_WIDTH-1:0]		i_id;
input  [ADDR_WIDTH-1:0]		i_addr;
input  [AXLEN_WIDTH-1:0]	i_len;
input  [2:0]			i_size;
input  [1:0]			i_burst;
input  [1:0]			i_lock;
input  [3:0]			i_cache;
input  [2:0]			i_prot;

// write response channel
output [1:0]			o_resp;
integer i;
integer cycle_count;

reg    [ID_WIDTH-1:0] 		resp_id;
reg				done;
reg				aw_done;
reg				w_done;
reg    [1:0]			o_resp;
reg    [DATA_BITS-1:0]		wr_data;
reg    [DATA_BYTES-1:0]		wr_wstrb;
begin
	done    = 1'b0;
	aw_done = 1'b0;
	w_done  = 1'b0;

	cycle_count = 0;
	fork
		begin
			// Send the write address/controls
			send_waddr(i_id, i_addr, i_len, i_size, i_burst, i_lock, i_cache, i_prot);
			aw_done = 1'b1;
		end
		begin
			// Send the write data/strb
			for (i = 0; i <= i_len; i = i + 1) begin
				wr_data = reg_wdata[i];
				wr_wstrb = reg_wstrb[i];
				send_wdata(i_id, wr_data, wr_wstrb, (i[AXLEN_WIDTH-1:0]==i_len));
			end
			w_done = 1'b1;
		end
		begin
			// get b channel
			while (~(aw_done & w_done)) begin
				@(posedge aclk) ;
				cycle_count = cycle_count + 1;
				if (cycle_count === WAIT_TIMEOUT_CNT) begin
					if (~aw_done) begin
						$display("%0t:%m:ERROR:TIMEOUT:aw-channel hangs for %0d cycles", $realtime, cycle_count);
					end
					if (~w_done) begin
						$display("%0t:%m:ERROR:TIMEOUT:w-channel hangs for %0d cycles", $realtime, cycle_count);
					end
					#1 $finish;
				end
			end
			
			get_bresp(resp_id, o_resp);
			if (resp_id != i_id) begin
				$display("%0t:%m:ERROR:Got BID = 0x%h but AWID = 0x%h", $realtime, resp_id, i_id);
				#1 $finish;
			end
			done = 1'b1;
		end
	join
end
endtask

task read_data;
input   [ID_WIDTH-1:0]		i_id;
input   [ADDR_WIDTH-1:0]	i_addr;
input   [AXLEN_WIDTH-1:0]	i_len;
input   [2:0]			i_size;
input   [1:0]			i_burst;
input   [1:0]			i_lock;
input   [3:0]			i_cache;
input   [2:0]			i_prot;

reg [ID_WIDTH-1:0]	 	rd_id;
reg [1:0] 			rd_resp;
reg 				rd_last;
reg [DATA_BITS-1:0] 		rd_data;

integer i;
integer cycle_count;
reg done;
reg ar_done;
begin
	done    = 1'b0;
	ar_done = 1'b0;

	cycle_count = 0;
	fork
	begin	
		send_raddr(i_id, i_addr, i_len, i_size, i_burst, i_lock, i_cache, i_prot);
		ar_done=1'b1;
	end
	begin
		while (~ar_done) begin
			@(posedge aclk) ;
			cycle_count = cycle_count + 1;
			if (cycle_count === WAIT_TIMEOUT_CNT) begin
				$display("%0t:%m:ERROR:TIMEOUT:ar-channel hangs for %0d cycles", $realtime, cycle_count);
				#1 $finish;
			end
		end

		// Save the read data to an internal buffer
		for (i = 0; i <= i_len; i = i + 1) begin
			get_rdata(rd_id, rd_data, rd_resp, rd_last);
			reg_rdata[i]  = rd_data;
			reg_rresp[i]  = rd_resp;

			if (rd_id != i_id) begin
				$display("%0t:%m:ERROR:Got RID = 0x%h but ARID = 0x%h", $realtime, rd_id, i_id);
				#1 $finish;
			end
			if ((i[AXLEN_WIDTH-1:0] == i_len) != rd_last)  begin
				$display("%0t:%m:ERROR:RLAST indication error at the %0d'th transfer. RLAST=%b, ARLEN=%0d", $realtime, i + 1, rd_last, i_len);
				#1 $finish;
			end
		end
		done = 1'b1;
	end
	join

// Not support for back to back yet, wait cycle check is not needed now
//	cycle_count = 0;
//	while (~done && (cycle_count < WAIT_TIMEOUT_CNT)) begin
//		@(posedge aclk) ;
//		cycle_count = cycle_count + 1;
//		if (cycle_count === WAIT_TIMEOUT_CNT) begin
//			$display("%0t:%m:ERROR:TIMEOUT:read_data() hangs for %0d cycles", $realtime, cycle_count);
//			#1 $finish;
//		end
//	end
end
endtask

// Insert output delay
assign #(OUT_DELAY) awid	= p_awid;
assign #(OUT_DELAY) awaddr	= p_awaddr;
assign #(OUT_DELAY) awlen	= p_awlen;
assign #(OUT_DELAY) awsize	= p_awsize;
assign #(OUT_DELAY) awburst	= p_awburst;
assign #(OUT_DELAY) awlock	= p_awlock;
assign #(OUT_DELAY) awcache	= p_awcache;
assign #(OUT_DELAY) awprot	= p_awprot;
assign #(OUT_DELAY) awvalid	= p_awvalid;

assign #(OUT_DELAY) wdata	= p_wdata;
assign #(OUT_DELAY) wstrb	= p_wstrb;
assign #(OUT_DELAY) wlast	= p_wlast;
assign #(OUT_DELAY) wvalid	= p_wvalid;

assign #(OUT_DELAY) bready	= p_bready;

assign #(OUT_DELAY) arid	= p_arid;
assign #(OUT_DELAY) araddr	= p_araddr;
assign #(OUT_DELAY) arlen	= p_arlen;
assign #(OUT_DELAY) arsize	= p_arsize;
assign #(OUT_DELAY) arburst	= p_arburst;
assign #(OUT_DELAY) arlock	= p_arlock;
assign #(OUT_DELAY) arcache	= p_arcache;
assign #(OUT_DELAY) arprot	= p_arprot;
assign #(OUT_DELAY) arvalid	= p_arvalid;

assign #(OUT_DELAY) rready	= p_rready;
// pragma protect end


//----- Include the model pattern file -----//
`include "axi_master.pat"

endmodule
