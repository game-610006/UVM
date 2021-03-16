class jux_axi4_test extends uvm_test;
//optional - declare tb class here or in actual test
jux_axi4_env env;
`uvm_component_utils(jux_axi4_test)

function new(string name, uvm_component parent);
	super.new(name,parent);
//	$display("=======in test function new==========\n");
endfunction : new

virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
//	$display("=======in test build phase 1\n");
	uvm_config_db#(int)::set(this,"*","recording_detail",UVM_FULL);

	env=jux_axi4_env::type_id::create("env",this);

//	$display("=======in test build phase 2\n");

endfunction : build_phase

virtual function void start_of_simulation_phase(uvm_phase phase);
//	$display("=============in test simulation phase==========\n");
endfunction : start_of_simulation_phase

task run_phase(uvm_phase phase);
//	$display("=============in test run phase==========\n");
	#5000000;
	`uvm_fatal("TIMEOUT", "Time-out expired in run phase")
endtask : run_phase

endclass : jux_axi4_test 
