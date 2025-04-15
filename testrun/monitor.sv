class monitor extends uvm_monitor;
    
    `uvm_component_utils(monitor)
    uvm_analysis_port #(transaction) send;
    transaction tc;
    
    virtual mem_ctrl_if mcif;

    function new(input string path = "monitor",uvm_component parent = null);
        super.new(path, parent);
        send = new("send",this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc"); 
        if(!uvm_config_db#( virtual mem_ctrl_if)::get(this,"","mcif",mcif))
            `uvm_error("MON","Unable to access config db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            get_output_from_intf();
            send.write(tc);
        end
    endtask

    task get_output_from_intf();
        repeat(5)@(posedge mcif.clk);
            if(!mcif.rst_n)begin
                `uvm_info("MON", "SYSTEM RESET DETECTED mcif.rst_n", UVM_NONE)
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
               
                if(tc.command == 3'b010 && tc.RDnWR == 1'b1) begin
                    `uvm_info("MON_READ",$sformatf("DATA SENT rst_n:%0b cmd_n:%0b RDnWR:%0b Addr_in:%0h Data_in_vld:%0b Data_in:%0h ",tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)
                    repeat(2) @(posedge mcif.clk);

                end

                else if(tc.RDnWR == 1'b0) begin
                    `uvm_info("MON_WRITE",$sformatf("DATA SENT rst_n:%0b cmd_n:%0b RDnWR:%0b Addr_in:%0h Data_in_vld:%0b Data_in:%0h ",tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)
                    repeat(4) @(posedge mcif.clk);
                end
                
                else if(tc.RDnWR == 1'b1 && is_not_there(tc.Addr_in))begin
                    `uvm_info("MON_READ","Data doesn't exists sending to scoreboard",UVM_NONE)
                    repeat(4) @(posedge mcif.clk);
                end
            end
    endtask


    function bit is_not_there(bit [15:0] addr);
        foreach (addr_in_queue[i]) begin
            if (addr_in_queue[i] == addr)
                return 0;  
        end
        return 1;  
    endfunction
    
endclass