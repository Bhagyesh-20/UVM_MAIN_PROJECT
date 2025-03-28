class monitor extends uvm_monitor;
    
    `uvm_component_utils(monitor)

    uvm_analysis_port #(transaction) send;

    transaction tc;

    virtual mem_ctrl_if mcif;

    function new(input string path = "monitor",uvm_component parent = null);
        super.new(path, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc",this);
        send = new("send",this);
        
        if(!uvm_config_db#( virtual mem_ctrl_if)::get(this,"","mcif",mcif))
            `uvm_error("MON","Unable to access config db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge mcif.clk);

            if(!mcif.rst)begin
                `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
                send.write(tc);
            end


            else begin
                repeat(2) @(posedge mcif.clk);
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

                if(mcif.command == 4'b0101)begin
                    `uvm_info("MON","REFRESH DETECTED",UVM_NONE);
                    tc.is_refresh = 1;
                end
                else begin
                    tc.is_refresh = 0;
                end

                `uvm_info("MON",$sformatf("DATA SENT TO ",tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in,),UVM_NONE)
                send.write(tc);  // have to insert clk based delays
                
            end
        end
    endtask
endclass