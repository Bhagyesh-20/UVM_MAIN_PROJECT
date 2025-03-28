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
        send = new("send",this);
        
        if(!uvm_config_db#( virtual mem_ctrl_if)::get(this,"","mcif",mcif))
            `uvm_error("MON","Unable to access config db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge mcif.clk);
            // tc = transaction::type_id::create("tc");

            if(!mcif.rst_n)begin
                `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
                
            end

            else begin
                tc = transaction::type_id::create("tc");    
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
                    tc.ref_detected = 1;
                    tc.pre_detected = 0;
                    tc.act_detected = 0;
                end
                else if(mcif.command == 4'b0001)begin 
                    `uvm_info("MON","ACT DETECTED",UVM_NONE);
                    tc.act_detected = 1;
                    tc.ref_detected = 0;
                    tc.pre_detected = 0;
                end
                else if(mcif.command == 4'b0100)begin
                    `uvm_info("MON","PRE DETECTED",UVM_NONE);
                    tc.pre_detected = 1;
                    tc.ref_detected = 0;
                    tc.act_detected = 0;
                end

                `uvm_info("MON",$sformatf("DATA SENT",tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in,),UVM_NONE)
                send.write(tc);  // have to insert clk based delays
                
            end
        end
    endtask
endclass