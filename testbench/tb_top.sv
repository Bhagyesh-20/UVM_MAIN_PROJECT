module mem_ctrl_tb();
    
    mem_ctrl_if mcif(clk, rst_n);
    
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
        mcif.clk = 0;
    end

    initial begin
        uvm_config_db#(virtual mem_ctrl_if)::set(null,"uvm_test_top.e.a*","mcif",mcif);
        run_test("test");
    end
    
    always #5 clk = ~clk;



endmodule
