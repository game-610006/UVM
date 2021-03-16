class jux_axi4_vseq_lib extends uvm_sequence;
string tID;
function new(string name="jux_axi4_vseq_lib");
	super.new(name);
//	$display("========in vseq_lib==========\n");
	tID=get_type_name();
	tID=tID.toupper();
	set_response_queue_depth(100);
endfunction

`uvm_object_utils(jux_axi4_vseq_lib)
`uvm_declare_p_sequencer(jux_axi4_virtual_sequencer)

task pre_body();
`ifndef UVM_VERSION_1_1
  uvm_phase starting_phase = get_starting_phase();
`endif
	 if (starting_phase != null)
		starting_phase.raise_objection(this, {"Running sequence '",
			get_full_name(), "'"});
endtask

task post_body();
`ifndef UVM_VERSION_1_1
  uvm_phase starting_phase = get_starting_phase();
`endif
	if (starting_phase != null)
		starting_phase.drop_objection(this, {"Completed sequence '",
			 get_full_name(), "'"});
endtask
endclass
