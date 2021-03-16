class jux_axi4_read_monitor extends uvm_monitor;

string tID;
//virtual interface 
virtual interface jux_axi4_if vif;
jux_axi4_read_item trans_read;

// TLM port for scoreboard communication (temporary)
uvm_analysis_port #(jux_axi4_read_item) item_collected_port;

`uvm_component_utils_begin(jux_axi4_read_monitor)
  `uvm_field_object(trans_read, UVM_ALL_ON)
`uvm_component_utils_end

virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
//  $display("========= in rd_monitor build phase =========\n");
  if(!uvm_config_db#(virtual jux_axi4_if)::get(this,"","vif",vif))
    `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(),".vif"});
endfunction : build_phase

//instance implement
function new(string name,uvm_component parent);
  super.new(name,parent);
//  $display("============= in rd_monitor function new =======\n");
  tID=get_type_name();
  tID=tID.toupper();
  trans_read = new();
  item_collected_port = new("item_collected_port", this);
endfunction : new 

task run_phase(uvm_phase phase);
  `uvm_info(tID,"RUNNING:",UVM_MEDIUM);
//  $display("======== in rd_monitor run phase ========\n");
  fork
    collect_data(trans_read);
  join
endtask : run_phase

int counter;

task collect_data(jux_axi4_read_item trans);
	$display("============in rd_monitor collect_data=========\n");

	forever begin
//		$display("forever loop start\n");

		//read address phase
			if (vif.arvalid && vif.arready)	begin

				$display("*********************************************************\n");
				$display("********** %0dns  read address channel handshake*********\n",$stime);
				$display("*********************************************************\n");
//				$display("===== awaddr = %x ============\n",vif.awaddr);
				trans.araddr = vif.araddr;
        		trans.arlen  = vif.arlen; //pass to scoreboard
				$display("%0dns araddr =%8x\n",$stime,trans.araddr);
				$display("%0dns arlen = %d \n",$stime,trans.arlen);
				counter=0;

				for (int i=0;i<=255;i++)		begin
					trans.rdata[i]=1024'd0;
				end

			end


			//read data phase
			if (vif.rvalid && vif.rready) 	begin
				$display("*********************************************************\n");
				$display("********** %0dns  read data channel handshake ***********\n",$stime);
				$display("*********************************************************\n");

				trans.rdata[counter]=vif.rdata;//array is defined
				$display("%0dns rdata = %8x\n",$stime,trans.rdata[counter]);
				$display("current trans_data are [%8x,%8x,%8x,%8x]\n",trans.rdata[0],trans.rdata[1],trans.rdata[2],trans.rdata[3]);
				counter=counter+1;
			end

			if (vif.rlast)	begin
				$display("%0dns item_collect_port to scoreboard\n",$stime);
				item_collected_port.write(trans);
			end

			@(posedge vif.aclk);

    
	end
endtask : collect_data

endclass : jux_axi4_read_monitor
