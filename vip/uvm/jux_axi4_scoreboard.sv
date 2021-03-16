//connect master read monitor
class uvm_analysis_imp_us_master_read #(type T=int, type IMP=uvm_scoreboard) extends uvm_port_base #(uvm_tlm_if_base #(T,T));
`UVM_IMP_COMMON(`UVM_TLM_ANALYSIS_MASK,`"uvm_analysis_imp_us_master`",IMP)

function void write(T t);
        m_imp.update_us_master_read (t);
endfunction : write
endclass : uvm_analysis_imp_us_master_read

//connect master write monitor
class uvm_analysis_imp_us_master_write #(type T=int, type IMP=uvm_scoreboard) extends uvm_port_base #(uvm_tlm_if_base #(T,T));
`UVM_IMP_COMMON(`UVM_TLM_ANALYSIS_MASK,`"uvm_analysis_imp_us_master`",IMP)

function void write(T t);
        m_imp.update_us_master_write (t);
endfunction : write
endclass : uvm_analysis_imp_us_master_write

//connect slave read monitor
class uvm_analysis_imp_slave_read #(type T=int, type IMP=uvm_scoreboard) extends uvm_port_base #(uvm_tlm_if_base #(T,T));
`UVM_IMP_COMMON(`UVM_TLM_ANALYSIS_MASK,`"uvm_analysis_imp_slave`",IMP)

function void write(T t);
        m_imp.update_slave_read (t);
endfunction : write
endclass : uvm_analysis_imp_slave_read

//connect slave write monitor
class uvm_analysis_imp_slave_write #(type T=int, type IMP=uvm_scoreboard) extends uvm_port_base #(uvm_tlm_if_base #(T,T));
`UVM_IMP_COMMON(`UVM_TLM_ANALYSIS_MASK,`"uvm_analysis_imp_slave`",IMP)

function void write(T t);
        m_imp.update_slave_write (t);
endfunction : write
endclass : uvm_analysis_imp_slave_write


class jux_axi4_scoreboard extends uvm_scoreboard;
`uvm_component_utils(jux_axi4_scoreboard)

import jux_axi4_pkg::*;

reg [1023:0] master_read_box[0:256];
reg [1023:0] master_write_box[0:256];
reg [1023:0] slave_read_box[0:256];
reg [1023:0] slave_write_box[0:256];

int detect_master_read;
int detect_master_write;
int detect_slave_read;
int detect_slave_write;

int master_write_item=0;
int master_read_item=0;
int slave_write_item=0;
int slave_read_item=0;


string tID;
uvm_analysis_imp_us_master_read #(jux_axi4_read_item, jux_axi4_scoreboard) us_master_read_export;
uvm_analysis_imp_us_master_write #(jux_axi4_write_item, jux_axi4_scoreboard) us_master_write_export;
uvm_analysis_imp_slave_read #(jux_axi4_read_item, jux_axi4_scoreboard) slave_read_export;
uvm_analysis_imp_slave_write #(jux_axi4_write_item, jux_axi4_scoreboard) slave_write_export;

// vif, because i want to use vif.clk
virtual interface jux_axi4_if vif;


function new (string name = "jux_axi4_scoreboard", uvm_component parent = null);
	super.new(name, parent);
//	$display("======== in scoreboard function new========\n");
	tID=get_type_name();
	tID=tID.toupper();
endfunction: new

virtual function void build_phase (uvm_phase phase);
//	$display("========== in scoreboard build phase ==========\n");
	us_master_read_export = new("us_master_read_export", this);
	us_master_write_export = new("us_master_write_export", this);
	slave_read_export = new("slave_read_export", this);
	slave_write_export = new("slave_write_export", this);

  	if(!uvm_config_db#(virtual jux_axi4_if)::get(this,"","vif",vif))
    `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(),".vif"});

endfunction: build_phase



//run phase for compare box
task run_phase(uvm_phase phase);
//	$display("========= in scorboard run phase ========\n");
	fork
		compare_data();
	join
endtask	: run_phase

task compare_data();
	
	forever begin
		@(posedge vif.aclk);
		if ((detect_master_write==1)&&(detect_slave_write==1))	begin
			$display("%0dns write burst compare",$stime);				
			if (master_write_box==slave_write_box)	begin
				$display("m_wr_box=[%8x,%8x,%8x,%8x,%8x]\n",master_write_box[0],master_write_box[1],master_write_box[2],master_write_box[3],master_write_box[4]);
				$display("s_wr_box=[%8x,%8x,%8x,%8x,%8x]\n",slave_write_box[0],slave_write_box[1],slave_write_box[2],slave_write_box[3],slave_write_box[4]);
				`uvm_info(tID,$sformatf("match"),UVM_LOW);
				detect_master_write=0;
				detect_slave_write=0;
			end
			else	begin
				$display("m_wr_box=[%8x,%8x,%8x,%8x,%8x]\n",master_write_box[0],master_write_box[1],master_write_box[2],master_write_box[3],master_write_box[4]);
				$display("s_wr_box=[%8x,%8x,%8x,%8x,%8x]\n",slave_write_box[0],slave_write_box[1],slave_write_box[2],slave_write_box[3],slave_write_box[4]);
				`uvm_fatal(tID,$sformatf("not natch"));
				detect_master_write=0;
				detect_slave_write=0;
			end
		end
		else if ((detect_master_read==1)&&(detect_slave_read==1))	begin
			$display("%0dns read burst compare",$stime);
			if (master_read_box==slave_read_box)	begin
				$display("m_rd_box=[%8x,%8x,%8x,%8x,%8x]\n",master_read_box[0],master_read_box[1],master_read_box[2],master_read_box[3],master_read_box[4]);
				$display("s_rd_box=[%8x,%8x,%8x,%8x,%8x]\n",slave_read_box[0],slave_read_box[1],slave_read_box[2],slave_read_box[3],slave_read_box[4]);
				`uvm_info(tID,$sformatf("match"),UVM_LOW);
				detect_master_read=0;
				detect_slave_read=0;
			end						
			else	begin
				$display("m_rd_box=[%8x,%8x,%8x,%8x,%8x]\n",master_read_box[0],master_read_box[1],master_read_box[2],master_read_box[3],master_read_box[4]);
				$display("s_rd_box=[%8x,%8x,%8x,%8x,%8x]\n",slave_read_box[0],slave_read_box[1],slave_read_box[2],slave_read_box[3],slave_read_box[4]);
				`uvm_fatal(tID,$sformatf("not natch"));
				detect_master_read=0;
				detect_slave_read=0;
			end
		end
	end
endtask : compare_data	

//master raed
virtual function void update_us_master_read (jux_axi4_read_item item);
	$display("============ master read function ==========\n");
	//reset box
	for (int counter=0;counter<=256;counter++)	begin
		master_read_box[counter]=0;
	end

	//input data
	master_read_box[0]=item.araddr;

	for (int counter=0;counter<=item.arlen;counter++)	begin
		master_read_box[counter+1]=item.rdata[counter];
	end
	$display("=========== master_read_box[%8x,%8x,%8x,%8x,%8x]\n",master_read_box[0],master_read_box[1],master_read_box[2],master_read_box[3],master_read_box[4]);												
	detect_master_read=1;
	master_read_item=master_read_item+1;
endfunction : update_us_master_read

//master write
virtual function void update_us_master_write (jux_axi4_write_item item);
	$display("============ master write function ==========\n");
	//reset box
	for (int counter=0;counter<=256;counter++)	begin
		master_write_box[counter]=0;
	end

	//input data
	master_write_box[0]=item.addr;

	for (int counter=0;counter<=item.len;counter++)	begin
		master_write_box[counter+1]=item.data[counter];
	end
	$display("=========== master_write_box[%8x,%8x,%8x,%8x,%8x]\n",master_write_box[0],master_write_box[1],master_write_box[2],master_write_box[3],master_write_box[4]);	
	detect_master_write=1;
	master_write_item=master_write_item+1;
endfunction : update_us_master_write

//slave read
virtual function void update_slave_read (jux_axi4_read_item item);
	$display("============ slave read function ==========\n");
	//reset box
	for (int counter=0;counter<=256;counter++)	begin
		slave_read_box[counter]=0;
	end

	//input data
	slave_read_box[0]=item.araddr; 

	for (int counter=0;counter<=item.arlen;counter++)	begin
		slave_read_box[counter+1]=item.rdata[counter];
	end
	$display("=========== slave_read_box[%8x,%8x,%8x,%8x,%8x]\n",slave_read_box[0],slave_read_box[1],slave_read_box[2],slave_read_box[3],slave_read_box[4]);
	detect_slave_read=1;	
	slave_read_item=slave_read_item+1;
endfunction : update_slave_read

//slave write
virtual function void update_slave_write (jux_axi4_write_item item);
	$display("============ slave write function ==========\n");
	//reset box
	for (int counter=0;counter<=256;counter++)	begin
		slave_write_box[counter]=0;
	end
	//input data
	slave_write_box[0]=item.addr; 
	for (int counter=0;counter<=item.len;counter++)	begin
		slave_write_box[counter+1]=item.data[counter];
	end
	$display("=========== slave_write_box[%8x,%8x,%8x,%8x,%8x]\n",slave_write_box[0],slave_write_box[1],slave_write_box[2],slave_write_box[3],slave_write_box[4]);
	detect_slave_write=1;
	slave_write_item=slave_write_item+1;
endfunction : update_slave_write


virtual function void report_phase (uvm_phase phase);
	$display("in scoreboard report phase\n");
	`uvm_info(tID,$sformatf("Scoreboard report: master write = 0x%4d, master read = 0x%4d, slave write = 0x%4d, slave read = 0x%4d", master_write_item, master_read_item, slave_write_item, slave_read_item),UVM_LOW);
endfunction : report_phase

endclass : jux_axi4_scoreboard
