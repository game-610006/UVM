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
