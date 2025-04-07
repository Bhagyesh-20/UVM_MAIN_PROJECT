class monitor extends uvm_monitor;
    
    `uvm_component_utils(monitor)
    uvm_analysis_port #(transaction) send;
    bit [3:0] prev_command;
    transaction tc;

    virtual mem_ctrl_if mcif;

    function new(input string path = "monitor",uvm_component parent = null);
        super.new(path, parent);
        send            = new("send",this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
       
        tc = transaction::type_id::create("tc"); 
        if(!uvm_config_db#( virtual mem_ctrl_if)::get(this,"","mcif",mcif))
            `uvm_error("MON","Unable to access config db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            repeat(3)@(posedge mcif.clk);
            if(!mcif.rst_n)begin
                `uvm_info("MON", "SYSTEM RESET DETECTED mcif.rst_n", UVM_NONE); 
                prev_command = 4'b0000; 
            end

            else begin
                tc.rst_n        = 1'b1;
                tc.cmd_n        = mcif.cmd_n;
                tc.RDnWR        = mcif.RDnWR;
                tc.Addr_in      = mcif.Addr_in;
                tc.Data_in_vld  = mcif.Data_in_vld;
                tc.Data_in      = mcif.Data_in;
                tc.Data_out     = mcif.Data_out;
                tc.data_out_vld = mcif.data_out_vld;
                tc.command      = mcif.command;
                tc.RA           = mcif.RA;
                tc.CA           = mcif.CA;
                tc.cs_n         = mcif.cs_n; 
               

                if(mcif.command == 4'b0010 && mcif.RDnWR == 1'b1) begin
                    repeat(3) @(posedge mcif.clk);
                end
                    `uvm_info("MON",$sformatf("DATA SENT rst_n:%0b cmd_n:%0b RDnWR:%0b Addr_in:%0h Data_in_vld:%0b Data_in:%0h ",tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)
                    send.write(tc);
                end
            end
    endtask
endclass

