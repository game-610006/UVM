class jux_axi4_master_agent extends uvm_agent;

jux_axi4_read_monitor read_monitor;
jux_axi4_write_monitor write_monitor;

`uvm_component_utils(jux_axi4_master_agent)

function new(string name, uvm_component parent);
    super.new(name,parent);
//	$display("=======in master_agent function new=========\n");
endfunction : new

virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
//	$display("=======in master_agent build phase 1=========\n");

	read_monitor=jux_axi4_read_monitor::type_id::create("read_monitor",this);
    write_monitor=jux_axi4_write_monitor::type_id::create("write_monitor",this);

//	$display("=======in master_agent build phase 2=========\n");
endfunction : build_phase

endclass : jux_axi4_master_agent
