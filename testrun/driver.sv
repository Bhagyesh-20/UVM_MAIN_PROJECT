

class driver extends uvm_driver #(transaction);

    `uvm_component_utils(driver)

    transaction tc;
    uvm_analysis_port #(transaction) send;
    uvm_analysis_port #(transaction) send_to_ref_drv;
    
    virtual mem_ctrl_if mcif;

    function new(input string path = "driver", uvm_component parent  = null);
    
        super.new(path,parent);
        send            = new("send",this);
        send_to_ref_drv = new("send_to_ref_drv", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc");

        if(!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif))
            `uvm_error("DRV","Can't Access data of virtual interface")
    
    endfunction

    virtual task run_phase(uvm_phase phase);

        drive();
        
    endtask

    task drive();

        forever begin
            seq_item_port.get_next_item(tc);
            mcif.rst_n          <= tc.rst_n;
            mcif.cmd_n          <= tc.cmd_n;    
            mcif.RDnWR          <= tc.RDnWR;
            mcif.Addr_in        <= tc.Addr_in;
            mcif.Data_in_vld    <= tc.Data_in_vld;
            mcif.Data_in        <= tc.Data_in;
            
            `uvm_info("DRV",$sformatf("DATA SENT FROM DRIVER CLASS : rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h DQ = %0h",tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in,mcif.DQ),UVM_NONE)
            send_to_ref_drv.write(tc);
            repeat(9) @(posedge mcif.clk); 
            seq_item_port.item_done(tc);
            
        end
    endtask
endclass
