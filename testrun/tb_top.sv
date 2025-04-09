
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "mem_ctrl_pkg.sv"

import mem_ctrl_pkg::*;
`include "dut_1.1.sv"
`include "interface.sv"



module tb_top();
    mem_ctrl_if mcif();
    
    mem_ctrl dut (
        .clk          (mcif.clk),
        .rst_n        (mcif.rst_n),
        .cmd_n        (mcif.cmd_n),
        .RDnWR        (mcif.RDnWR),
        .Addr_in      (mcif.Addr_in),
        .Data_in_vld  (mcif.Data_in_vld),
        .Data_in      (mcif.Data_in),
        .Data_out     (mcif.Data_out),
        .data_out_vld (mcif.data_out_vld),
        .command      (mcif.command),
        .RA           (mcif.RA),
        .CA           (mcif.CA),
        .DQ           (mcif.DQ),
        .cs_n         (mcif.cs_n)
    );

    initial begin
            mcif.clk    = 0;
            mcif.rst_n  = 0;
        #0  mcif.clk    = 1;
        #0  mcif.rst_n  = 1;
    end
    
    always #5 mcif.clk = ~mcif.clk;
    
    always@(posedge mcif.clk)begin
        $display($time," Command is ",mcif.command);
    end


    initial begin
        uvm_config_db#(virtual mem_ctrl_if)::set(null,"uvm_test_top.e*","mcif",mcif);
        run_test("test");
    end
    
endmodule
