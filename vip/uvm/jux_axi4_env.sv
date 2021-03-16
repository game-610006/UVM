class jux_axi4_env extends uvm_env;

import jux_axi4_pkg::*;

jux_axi4_virtual_sequencer virtual_sequencer;

jux_axi4_scoreboard scoreboard;

jux_axi4_master_agent master_agent;
jux_axi4_slave_agent slave_agent;

`uvm_component_utils(jux_axi4_env)

function new(string name, uvm_component parent);
    super.new(name,parent);
//	$display("=======in env function new=========\n");
endfunction : new

virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
//	$display("=======in env build phase 1=========\n");

	master_agent = jux_axi4_master_agent::type_id::create("master_agent", this);
	slave_agent = jux_axi4_slave_agent::type_id::create("slave_agent", this);

	scoreboard = jux_axi4_scoreboard::type_id::create("scoreboard", this);

	virtual_sequencer = jux_axi4_virtual_sequencer::type_id::create("virtual_sequencer",this);

//	$display("=======in env build phase 2=========\n");
	
endfunction : build_phase

/*
task run_phase(uvm_phase phase);
//  	`uvm_info(get_type_name(), "Enter run phase of env", UVM_NONE);
//	$display("============in env run phase===========\n");
	#5000000;
//	$display("============in env run phase===========\n");

	`uvm_fatal("TIMEOUT", "Time-out expired in run phase")
//   	`uvm_info(get_type_name(), "End run phase of env", UVM_NONE);
endtask : run_phase
*/

function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
//	$display("============ in env connect phase ===========\n");
	master_agent.read_monitor.item_collected_port.connect(scoreboard.us_master_read_export);
	master_agent.write_monitor.item_collected_port.connect(scoreboard.us_master_write_export);

	slave_agent.read_monitor.item_collected_port.connect(scoreboard.slave_read_export);
	slave_agent.write_monitor.item_collected_port.connect(scoreboard.slave_write_export);

endfunction : connect_phase

virtual function void report();
  `uvm_info(get_type_name(), "---- SIMULATION FINISHED ----", UVM_NONE);
endfunction : report

endclass : jux_axi4_env 
