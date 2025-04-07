package mem_ctrl_pkg;
    import uvm_pkg::*;
    
    bit [15:0] addr_in_queue[$];   

    `include "uvm_macros.svh"
    `include "transaction.sv"
    `include "cmd_n_sequence.sv"
    `include "rd_sequence.sv"
    `include "rst_sequence.sv"
    `include "wr_invld_sequence.sv"
    `include "randomize_sequence.sv"
    `include "wr_sequence.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "agent.sv"
    `include "scoreboard.sv"
  //  `include "ref_model.sv"
    `include "env.sv"
    `include "test.sv"

endpackage
