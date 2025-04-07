class rst_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(rst_sequence)

    transaction tc;

    function new(input string path = "rst_sequence");
        super.new(path);
    endfunction

    virtual task body();
        tc = transaction::type_id::create("tc");
            start_item(tc);
                if(!tc.randomize())begin
                    `uvm_error("RST_SEQ","Randomization failed");
                end
                tc.rst_n = 0; 
                `uvm_info("RST_SEQ",$sformatf("rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h", tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)
                finish_item(tc);
    endtask
endclass