interface jux_axi4_if (input logic aclk, input logic areset_n); 

parameter DATA_WIDTH = 2;	// Width of data bus is (1 << DATA_WIDTH) bytes
parameter ADDR_WIDTH = 32;	// Width of address bus in bits
parameter ID_WIDTH = 4;
parameter bit	AXI4 = 1'b1;		// 1: AXI4 (8-bit AxLEN), 0: AXI3 (4-bit AxLEN).
parameter bit	AXI4_AXLEN_LT16 = 1'b1;	// Indicate to use less-than-16 AxLEN even in AXI4.


//----- Derived parameters -----//
localparam DATA_BYTES = 1 << DATA_WIDTH;
localparam DATA_BITS = DATA_BYTES * 8;
localparam AXLEN_WIDTH = 4 + (AXI4 * 4);


// Write address channel signals
logic	[ID_WIDTH-1:0] 		awid;
logic 	[ADDR_WIDTH:0] 		awaddr;
logic 	[AXLEN_WIDTH-1:0] 	awlen;
logic 	[2:0]				awsize;
logic	[1:0]				awburst;
logic	[1:0]				awlock;
logic	[3:0]				awcache;
logic	[2:0]				awprot;
logic						awvalid;

logic						awready;


// Write data channel signals
logic	[DATA_BITS-1:0] 	wdata;
logic	[DATA_BYTES-1:0] 	wstrb;
logic						wlast;
logic						wvalid;

logic						wready;

// Write response channel signals
logic						bready;

logic	[ID_WIDTH-1:0]		bid;
logic	[1:0]				bresp;
logic						bvalid;

// Read address channel signals
logic	[ID_WIDTH-1:0]		arid;
logic	[ADDR_WIDTH-1:0]	araddr;
logic	[AXLEN_WIDTH-1:0]	arlen;
logic	[2:0]				arsize;
logic	[1:0]				arburst;
logic	[1:0]				arlock;
logic	[3:0]				arcache;
logic	[2:0]				arprot;
logic						arvalid;

logic						arready;


// Read data channel signals

logic						rready;

logic	[ID_WIDTH-1:0]		rid;
logic	[DATA_BITS-1:0]		rdata;
logic	[1:0]				rresp;
logic						rlast;
logic						rvalid;	

endinterface : jux_axi4_if
