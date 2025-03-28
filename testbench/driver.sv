class driver extends uvm_driver #(transaction);

    `uvm_component_utils(driver)

    transaction tc;

    virtual mem_ctrl_if mcif;

    function new(input string path = "driver", uvm_component parent  = null);
    
        super.new(path,parent);
    
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif))
            `uvm_error("DRV","Can't Access data of virtual interface")
    
    endfunction

    virtual task run_phase(uvm_phase phase);

        tc = transaction::type_id::create("tc");

        drive();
        
    endtask

    task reset_dut();
        repeat(5)begin
            mcif.rst_n          <= 1'b1;
            mcif.cmd_n          <= 1'b1;
            mcif.Addr_in        <= 'b0;
            mcif.Data_in        <= 'b0;
            mcif.Data_in_vld    <= 1'b0;

            `uvm_info("DRV_RST","System System Reset : Start of Simulation", UVM_MEDIUM)    
            
            @(posedge mcif.clk);
        end
    endtask


    task drive();

        reset_dut();

        forever begin
                
            seq_item_port.get_next_item(tr);

            mcif.RDnWR          <= tr.RDnWR;
            mcif.Addr_in        <= tr.Addr_in;
            mcif.Data_in_vld    <= tr.Data_in_vld;
            mcif.Data_in        <= tr.Data_in;
                
            `uvm_info("DRV",$sformatf("DATA SENT FROM DRIVER CLASS : rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h",tr.rst_n, tr.cmd_n, tr.RDnWR, tr.Addr_in, tr.Data_in_vld, tr.Data_in),UVM_NONE)
                
            repeat (2) @(posedge mcif.clk); // arbitary delay not calculated
                
            seq_item_port.item_done(tr);

        end
    endtask

endclass