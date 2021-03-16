`include "jux_axi4_vseq_lib.sv"

class test_vseq extends jux_axi4_vseq_lib;
string tID;
`uvm_object_utils(test_vseq)
function new(string name="test_vseq");
	super.new(name);
	tID=get_type_name();
	tID=tID.toupper();
endfunction

task body();
	`uvm_info(tID,"sequence RUNNING",UVM_MEDIUM)
	#500000;
	`uvm_info(tID,"run end test end",UVM_LOW);
endtask : body
endclass : test_vseq

class test extends jux_axi4_test;
`uvm_component_utils(test)

function new(string name, uvm_component parent);
	super.new(name,parent);
endfunction : new

virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info(get_type_name(),"RUN build phase RUNNING",UVM_MEDIUM)
	uvm_config_wrapper::set(this, "env.virtual_sequencer.run_phase",
		"default_sequence", test_vseq::type_id::get());
	
endfunction:build_phase
endclass : test 
