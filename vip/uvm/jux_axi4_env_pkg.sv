`ifndef AXI4_ENV_PKG
`define AXI4_ENV_PKG

`include "jux_axi4_pkg.sv"
import jux_axi4_pkg::*;


package jux_axi4_env_pkg;
	import uvm_pkg::*;

	`include "uvm_macros.svh"

	`include "jux_axi4_scoreboard.sv"

	`include "jux_axi4_virtual_sequencer.sv"

	`include "jux_axi4_env.sv"
	
endpackage

`endif 
