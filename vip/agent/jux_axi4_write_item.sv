class jux_axi4_write_item extends uvm_sequence_item; 

bit [31:0]         	addr;
bit [1023:0]    	data[0:255];
bit [7:0]			len;	

`uvm_object_utils_begin(jux_axi4_write_item)
  `uvm_field_int        (addr , UVM_ALL_ON)
  `uvm_field_sarray_int (data , UVM_ALL_ON)
  `uvm_field_int  		(len , UVM_ALL_ON)
`uvm_object_utils_end


function new(string name="jux_axi4_write_item");
   super.new(name);
//   $display("==========in wr_item function new=============\n");
	
endfunction : new

endclass : jux_axi4_write_item 
