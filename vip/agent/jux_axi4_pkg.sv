`ifndef JUX_AXI4_PKG
`define JUX_AXI4_PKG

`include "jux_axi4_if.sv"

package jux_axi4_pkg;
	import uvm_pkg::*;

	`include "uvm_macros.svh"

	`include "jux_axi4_param.sv"

	`include "jux_axi4_read_item.sv"
	`include "jux_axi4_write_item.sv"
	`include "jux_axi4_read_monitor.sv"
	`include "jux_axi4_write_monitor.sv"

	`include "jux_axi4_slave_agent.sv"
	`include "jux_axi4_master_agent.sv"
endpackage

`endif // JUX_AXI4_PKG
