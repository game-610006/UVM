//`timescale 1ns/1ps
`include "jux_axi4_test_pkg.sv";
import uvm_pkg::*;
/*
`include "jux_axi4_if.sv"
`include "jux_axi4_env.sv"
`include "jux_axi4_test.sv"
*/
module system(
);

//------------------------------------------------------------------------------
// global signal declarations
//------------------------------------------------------------------------------
 reg		clk;
 reg		resetn;

//----- Configurable parameters -----//
 parameter DATA_WIDTH = 3;	// Width of data bus is (1 << DATA_WIDTH) bytes
 parameter ADDR_WIDTH = 32;	// Width of address bus in bits
 parameter ID_WIDTH = 4;
 parameter bit	AXI4 = 1'b1;		// 1: AXI4 (8-bit AxLEN), 0: AXI3 (4-bit AxLEN).
 parameter bit	AXI4_AXLEN_LT16 = 1'b1;	// Indicate to use less-than-16 AxLEN even in AXI4.

//----- Derived parameters -----//
 localparam DATA_BYTES = 1 << DATA_WIDTH;
 localparam DATA_BITS = DATA_BYTES * 8;
 localparam AXLEN_WIDTH = 4 + (AXI4 * 4);


//===================master to dut=====================//
//-----write address channel-----//
 wire [ID_WIDTH-1:0]		m_awid;
 wire [ADDR_WIDTH-1:0]		m_awaddr;
 wire [AXLEN_WIDTH-1:0]	m_awlen;
 wire [2:0]			m_awsize;
 wire [1:0]			m_awburst;
 wire [1:0]			m_awlock;
 wire [3:0]			m_awcache;
 wire [2:0]			m_awprot;
 wire				m_awvalid;
 wire				m_awready;

// Write data channel signals
 wire  			m_wready;
 wire [DATA_BITS-1:0]		m_wdata;
 wire [DATA_BYTES-1:0]		m_wstrb;
 wire				m_wlast;
 wire				m_wvalid;

// Write response channel signals
 wire [ID_WIDTH-1:0]		m_bid;
 wire [1:0]			m_bresp;
 wire   			m_bvalid;
 wire 				m_bready;

// Read address channel signals
 wire  				m_arready;
 wire [ID_WIDTH-1:0]		m_arid;
 wire [ADDR_WIDTH-1:0]		m_araddr;
 wire [AXLEN_WIDTH-1:0]		m_arlen;
 wire [2:0]			m_arsize;
 wire [1:0]			m_arburst;
 wire [1:0]			m_arlock;
 wire [3:0]			m_arcache;
 wire [2:0]			m_arprot;
 wire				m_arvalid;

// Read data channel signals
 wire[ID_WIDTH-1:0]		m_rid;
 wire[DATA_BITS-1:0]		m_rdata;
 wire[1:0]			m_rresp;
 wire  				m_rlast;
 wire  				m_rvalid;
 wire				m_rready;


//===================slave to dut=====================//
//-----write address channel-----//
 wire [ID_WIDTH-1:0]		s_awid;
 wire [ADDR_WIDTH-1:0]		s_awaddr;
 wire [AXLEN_WIDTH-1:0]	s_awlen;
 wire [2:0]			s_awsize;
 wire [1:0]			s_awburst;
 wire [1:0]			s_awlock;
 wire [3:0]			s_awcache;
 wire [2:0]			s_awprot;
 wire				s_awvalid;
 wire				s_awready;

// Write data channel signals
 wire  			s_wready;
 wire [DATA_BITS-1:0]		s_wdata;
 wire [DATA_BYTES-1:0]		s_wstrb;
 wire				s_wlast;
 wire				s_wvalid;

// Write response channel signals
 wire [ID_WIDTH-1:0]		s_bid;
 wire [1:0]			s_bresp;
 wire   			s_bvalid;
 wire 				s_bready;

// Read address channel signals
 wire  				s_arready;
 wire [ID_WIDTH-1:0]		s_arid;
 wire [ADDR_WIDTH-1:0]		s_araddr;
 wire [AXLEN_WIDTH-1:0]		s_arlen;
 wire [2:0]			s_arsize;
 wire [1:0]			s_arburst;
 wire [1:0]			s_arlock;
 wire [3:0]			s_arcache;
 wire [2:0]			s_arprot;
 wire				s_arvalid;

// Read data channel signals
 wire[ID_WIDTH-1:0]		s_rid;
 wire[DATA_BITS-1:0]		s_rdata;
 wire[1:0]			s_rresp;
 wire  				s_rlast;
 wire  				s_rvalid;
 wire				s_rready;








jux_axi_master_model axi_master (
	.aclk		(clk			),
	.aresetn	(resetn			),
	.awid		(m_awid			),
	.awaddr		(m_awaddr		),
	.awlen		(m_awlen		),
	.awsize		(m_awsize		),
	.awburst	(m_awburst		),
	.awlock		(m_awlock		),
	.awcache	(m_awcache		),
	.awprot		(m_awprot		),
	.awvalid	(m_awvalid		),
	.awready	(m_awready		),
	.wdata		(m_wdata		),
	.wstrb		(m_wstrb		),
	.wlast		(m_wlast		),
	.wvalid		(m_wvalid		),
	.wready		(m_wready		),
	.bid		(m_bid			),
	.bresp		(m_bresp		),
	.bvalid		(m_bvalid		),
	.bready		(m_bready		),
	.arid		(m_arid			),
	.araddr		(m_araddr		),
	.arlen		(m_arlen		),
	.arsize		(m_arsize		),
	.arburst	(m_arburst		),
	.arlock		(m_arlock		),
	.arcache	(m_arcache		),
	.arprot		(m_arprot		),
	.arvalid	(m_arvalid		),
	.arready	(m_arready		),
	.rid		(m_rid			),
	.rdata		(m_rdata		),
	.rresp		(m_rresp		),
	.rlast		(m_rlast		),
	.rvalid		(m_rvalid		),
	.rready 	(m_rready 		)
);

jux_axi_slave_model axi_slave (
	.clk		(clk			),
	.rstn		(resetn			),
	.awaddr		(s_awaddr		),
	.awsize		(s_awsize		),
	.awburst	(s_awburst		),
	.awid		(s_awid			),
	.awlen		(s_awlen		),
	.awvalid	(s_awvalid		),
	.awready	(s_awready		),
	.wdata		(s_wdata		),
	.wstrb		(s_wstrb		),
	.wlast		(s_wlast		),
	.wvalid		(s_wvalid		),
	.wready		(s_wready		),
	.bresp		(s_bresp		),
	.bid		(s_bid			),
	.bvalid		(s_bvalid		),
	.bready		(s_bready		),
	.araddr		(s_araddr		),
	.arsize		(s_arsize		),
	.arburst	(s_arburst		),
	.arid		(s_arid			),
	.arlen		(s_arlen		),
	.arvalid	(s_arvalid		),
	.arready	(s_arready		),
	.rdata		(s_rdata		),
	.rid		(s_rid			),
	.rresp		(s_rresp		),
	.rlast		(s_rlast		),
	.rvalid		(s_rvalid		),
	.rready		(s_rready		)
);



dut bridge(
   // global signals
   	.axi_clk(clk),
   	.reset_n(resetn),
//---------dut_master----------------------------
//=======axi write address channel================
//dut_m_input
 	.dut_m_in_AWID(m_awid),       
 	.dut_m_in_AWADDR(m_awaddr),     
 	.dut_m_in_AWLEN(m_awlen),      
 	.dut_m_in_AWSIZE(m_awsize),     
 	.dut_m_in_AWBURST(m_awburst),    
 	.dut_m_in_AWVALID(m_awvalid),    
 	.dut_m_in_AWCACHE(m_awcache),
 	.dut_m_in_AWLOCK(m_awlock),
 	.dut_m_in_AWPROT(m_awprot),
//dut_m_output 
 	.dut_m_out_AWREADY(m_awready),    

//=======axi write data channel==================
//dut_m_input
 	.dut_m_in_WLAST(m_wlast),      
 	.dut_m_in_WSTRB(m_wstrb),      
 	.dut_m_in_WVALID(m_wvalid),    
 	.dut_m_in_WID(),
 	.dut_m_in_WDATA(m_wdata),
 //dut_m_output 
 	.dut_m_out_WREADY(m_wready),

//========axi write response channel===============
//dut_m_input
//======== 11/19 dut_m_in_BREADY=1 ==================
  	.dut_m_in_BREADY(1),
//dut_m_output 
  	.dut_m_out_BID(m_bid),       
  	.dut_m_out_BRESP(m_bresp),     
  	.dut_m_out_BVALID(m_bvalid),     


//========axi read address channel================
//dut_m_input
  	.dut_m_in_ARID(m_arid),       
  	.dut_m_in_ARADDR(m_araddr),     
  	.dut_m_in_ARLEN(m_arlen),      
  	.dut_m_in_ARSIZE(m_arsize),     
  	.dut_m_in_ARBURST(m_arburst),    
  	.dut_m_in_ARVALID(m_arvalid),    
  	.dut_m_in_ARCACHE(m_arcache),
  	.dut_m_in_ARLOCK(m_arlock),
  	.dut_m_in_ARPROT(m_arprot),
//dut_m_output  
  	.dut_m_out_ARREADY(m_arready),    

//============axi read data channel=================
//dut_m_input
//============11/19 dut_m_in_RREADY=1 ==================
  	.dut_m_in_RREADY(1),
//dut_m_output  
  	.dut_m_out_RID(m_rid),       
  	.dut_m_out_RLAST(m_rlast),     
  	.dut_m_out_RRESP(m_rresp),     
  	.dut_m_out_RVALID(m_rvalid),    
  	.dut_m_out_RDATA(m_rdata),     

//-------------dut_slave------------------------------
//============axi write address channel===========
//dut_s_output
	.dut_s_out_AWID(s_awid),
	.dut_s_out_AWADDR(s_awaddr),
	.dut_s_out_AWLEN(s_awlen),
	.dut_s_out_AWSIZE(s_awsize),
	.dut_s_out_AWBURST(s_awburst),
	.dut_s_out_AWVALID(s_awvalid),
	.dut_s_out_AWCACHE(s_awcache),
	.dut_s_out_AWLOCK(s_awlock),
	.dut_s_out_AWPROT(s_awprot),
//dut_s_input
//============== 11/19 dut_s_in_awready=1 =======================
  	.dut_s_in_AWREADY(1),


//===========axi write data channel=================
//dut_s_output
	.dut_s_out_WLAST(s_wlast),
	.dut_s_out_WSTRB(s_wstrb),
	.dut_s_out_WVALID(s_wvalid),
	.dut_s_out_WID(),
	.dut_s_out_WDATA(s_wdata),
//dut_s_input	
//===========================11/18 dut_s_in_wready=1 =============================
  	.dut_s_in_WREADY(1),

//=========axi write response channel==============
//dut_s_output

  	.dut_s_out_BREADY(s_bready),
//dut_s_input	
	.dut_s_in_BID(s_bid),
	.dut_s_in_BRESP(s_bresp),
	.dut_s_in_BVALID(s_bvalid),

//===========axi read address channel=============

//dut_s_output
	.dut_s_out_ARID(s_arid),
	.dut_s_out_ARADDR(s_araddr),
	.dut_s_out_ARLEN(s_arlen),
	.dut_s_out_ARSIZE(s_arsize),
	.dut_s_out_ARBURST(s_arburst),
	.dut_s_out_ARVALID(s_arvalid),
	.dut_s_out_ARCACHE(s_arcache),
	.dut_s_out_ARLOCK(s_arlock),
	.dut_s_out_ARPROT(s_arprot),
//dut_s_input  
  	.dut_s_in_ARREADY(s_arready),

//===========axi read data channel=================
//dut_s_output
  	.dut_s_out_RREADY(s_rready),

//dut_s_input

	.dut_s_in_RID(s_rid),
	.dut_s_in_RLAST(s_rlast),
	.dut_s_in_RRESP(s_rresp),
	.dut_s_in_RVALID(s_rvalid),
	.dut_s_in_RDATA(s_rdata)


	);




jux_axi4_if master_if(

	.aclk(clk),
	.areset_n(resetn)

);


jux_axi4_if slave_if(
	.aclk(clk),
	.areset_n(resetn)

);

jux_axi4_if scoreboard_if(
	.aclk(clk),
	.areset_n(resetn)

);






//-----master interface---------------------------------- 
// Write address channel signals
assign master_if.awid     = m_awid;
assign master_if.awaddr   = m_awaddr;  
assign master_if.awlen    = m_awlen;   
assign master_if.awsize   = m_awsize;    
assign master_if.awburst  = m_awburst;      
assign master_if.awlock   = m_awlock;      
assign master_if.awcache  = m_awcache;       
assign master_if.awprot   = m_awprot;        
assign master_if.awvalid  = m_awvalid;      

assign master_if.awready  = m_awready;          


// Write data channel signals
assign master_if.wdata    = m_wdata;
assign master_if.wstrb    = m_wstrb;  
assign master_if.wlast    = m_wlast;   
assign master_if.wvalid   = m_wvalid;   

assign master_if.wready   = m_wready;        

// Write response channel signals
assign master_if.bready   = m_bready;       

assign master_if.bid      = m_bid;       
assign master_if.bresp    = m_bresp;             
assign master_if.bvalid   = m_bvalid;             

// Read address channel signals
assign master_if.arid     = m_arid;         
assign master_if.araddr   = m_araddr;          
assign master_if.arlen    = m_arlen;           
assign master_if.arsize   = m_arsize;           
assign master_if.arburst  = m_arburst;            
assign master_if.arlock   = m_arlock;              
assign master_if.arcache  = m_arcache;                
assign master_if.arprot   = m_arprot;              
assign master_if.arvalid  = m_arvalid;              

assign master_if.arready  = m_arready;          


// Read data channel signals

assign master_if.rready   = m_rready;               

assign master_if.rid      = m_rid;              
assign master_if.rdata    = m_rdata;               
assign master_if.rresp    = m_rresp;               
assign master_if.rlast    = m_rlast;                 
assign master_if.rvalid	  = m_rvalid;                 


//-----slave interface-----------------------------

// Write address channel signals
assign slave_if.awid     = s_awid;
assign slave_if.awaddr   = s_awaddr;  
assign slave_if.awlen    = s_awlen;   
assign slave_if.awsize   = s_awsize;    
assign slave_if.awburst  = s_awburst;      
assign slave_if.awlock   = s_awlock;      
assign slave_if.awcache  = s_awcache;       
assign slave_if.awprot   = s_awprot;        
assign slave_if.awvalid  = s_awvalid;      

assign slave_if.awready  = s_awready;          


// Write data channel signals
assign slave_if.wdata    = s_wdata;
assign slave_if.wstrb    = s_wstrb;  
assign slave_if.wlast    = s_wlast;   
assign slave_if.wvalid   = s_wvalid;   

assign slave_if.wready   = s_wready;        

// Write response channel signals
assign slave_if.bready   = s_bready;       

assign slave_if.bid      = s_bid;       
assign slave_if.bresp    = s_bresp;             
assign slave_if.bvalid   = s_bvalid;             

// Read address channel signals
assign slave_if.arid     = s_arid;         
assign slave_if.araddr   = s_araddr;          
assign slave_if.arlen    = s_arlen;           
assign slave_if.arsize   = s_arsize;           
assign slave_if.arburst  = s_arburst;            
assign slave_if.arlock   = s_arlock;              
assign slave_if.arcache  = s_arcache;                
assign slave_if.arprot   = s_arprot;              
assign slave_if.arvalid  = s_arvalid;              

assign slave_if.arready  = s_arready;          


// Read data channel signals

assign slave_if.rready   = s_rready;               

assign slave_if.rid      = s_rid;              
assign slave_if.rdata    = s_rdata;               
assign slave_if.rresp    = s_rresp;               
assign slave_if.rlast    = s_rlast;                 
assign slave_if.rvalid	 = s_rvalid;                 




initial begin
	
	uvm_config_db#(virtual jux_axi4_if)::set(null,"uvm_test_top.env.master_agent.*", "vif",master_if);
	uvm_config_db#(virtual jux_axi4_if)::set(null,"uvm_test_top.env.slave_agent.*", "vif",slave_if);

	uvm_config_db#(virtual jux_axi4_if)::set(null,"uvm_test_top.env.scoreboard", "vif",scoreboard_if);


	
//	uvm_config_db#(virtual jux_axi4_if)::set(uvm_root::get(),"*", "vif",master_if);
//	uvm_config_db#(virtual jux_axi4_if)::set(null,"uvm_test_top.env.master_agent.read_monitor", "vif",master_if);

//	uvm_config_db#(virtual jux_axi4_if)::set(null,"uvm_test_top.env.slave_agent.write_monitor", "vif",slave_if);
//	uvm_config_db#(virtual jux_axi4_if)::set(null,"uvm_test_top.env.slave_agent.read_monitor", "vif",slave_if);


//	run_test("jux_axi4_test");
	set_global_timeout(500000ns);
//	run_test("test");
	run_test("jux_axi4_test");
end

/*
always@(m_awaddr)
	$display("awaddr is %x\n",master_if.awaddr);
*/

always #10 clk=~clk;
/*
initial begin
	forever begin
		#10 clk	= ~clk;
		#10 $display("hello world\n");
		#50000 $finish;
	end
end
*/

initial begin
	$display("%0dns system: start to run simulation", $stime);
	clk	= 1'b0;
	resetn	= 1'b0;
	$display("%0dns system: assert the resetn", $stime);
	#75
	resetn	= 1'b1;
	$display("%0dns system: de-assert the resetn", $stime);
	#1315
	$display("*** %dns s_rvalid=%d, s_rready=%d, rdata=%x",$stime,s_rvalid,s_rready,s_rdata);
  	//#50000 $finish;
end

/*
initial begin
	$display("%d, dump start", $stime);
	$dumpfile("UVM_dump.vcd");
	$dumpvars;
end
*/
initial begin
	$fsdbDumpfile("test_uvm_1125.fsdb");
	$fsdbDumpvars;
end


endmodule
