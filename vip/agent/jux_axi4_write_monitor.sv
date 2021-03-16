class jux_axi4_write_monitor extends uvm_monitor;

string tID;
//virtual interface
virtual interface jux_axi4_if vif;
jux_axi4_write_item trans_write;

//TLM port for scoreboard communication (implement scoreboard write method if needed)
uvm_analysis_port #(jux_axi4_write_item) item_collected_port;

`uvm_component_utils_begin(jux_axi4_write_monitor)
  `uvm_field_object(trans_write, UVM_ALL_ON)
`uvm_component_utils_end

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
//  $display("==========in wr_monitor build phase==========\n");
  if(!uvm_config_db#(virtual jux_axi4_if)::get(this,"","vif",vif))
    `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(),".vif"});
endfunction : build_phase

task run_phase(uvm_phase phase);
  `uvm_info(tID,"RUNNING:",UVM_MEDIUM);
//  	$display("============in wr_monitor run phase==========\n");
  fork
	collect_data(trans_write);
  join
endtask : run_phase

//new() function needs to be listed last so other items defined
function new(string name, uvm_component parent);
  super.new(name,parent);
//  $display("=======in wr_monitor function new============\n");
  tID=get_type_name();
  tID=tID.toupper();
  trans_write = new();
  item_collected_port = new("item_collected_port", this);
endfunction : new

int counter;

task collect_data(jux_axi4_write_item trans);
	$display("============in wr_monitor collect_data=========\n");
	
	forever begin
		    //address phase
		if (vif.awvalid && vif.awready)	begin
			$display("*********************************************************\n");
			$display("********** %0dns  write address channel handshake********\n",$stime);
			$display("*********************************************************\n");

			trans.addr=vif.awaddr;
			trans.len=vif.awlen;
			$display("%0dns awaddr =%8x\n",$stime,trans.addr);
			$display("%0dns awlen = %d \n",$stime,trans.len);
			counter=0;

			for (int i=0;i<=255;i++)		begin
				trans.data[i]=1024'd0;
			end

		end

			//data phase
		if (vif.wvalid && vif.wready) 	begin
			$display("*********************************************************\n");
			$display("********** %0dns  write data channel handshake***********\n",$stime);
			$display("*********************************************************\n");

			trans.data[counter]=vif.wdata;//array is defined
			$display("%0dns wdata = %8x\n",$stime,trans.data[counter]);
			$display("current trans_data are [%8x,%8x,%8x,%8x]\n",trans.data[0],trans.data[1],trans.data[2],trans.data[3]);
			counter=counter+1;
		end

		if (vif.wlast)	begin
			$display("%0dns item_collect_port to scoreboard\n",$stime);
			item_collected_port.write(trans);
		end

		@(posedge vif.aclk);

	end
	
endtask : collect_data

endclass : jux_axi4_write_monitor 
