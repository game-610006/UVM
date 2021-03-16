class jux_axi4_read_item extends uvm_sequence_item; 


//read address 

bit [31:0]  	araddr;
bit [7:0]	  	arlen;

bit [1023:0]	rdata[0:255];

`uvm_object_utils_begin(jux_axi4_read_item)
    `uvm_field_int        (araddr , UVM_ALL_ON)
  	`uvm_field_int  	    (arlen , UVM_ALL_ON)
    `uvm_field_sarray_int   (rdata, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name="jux_axi4_read_item");
   super.new(name);
endfunction : new

endclass : jux_axi4_read_item 
