class wr_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(wr_sequence)

    transaction tc;

    function new(input string path = "wr_sequence");
        super.new(path);
    endfunction

    virtual task body();
        tc = transaction::type_id::create("tc",this);
        repeat(5) begin
            start_item(tc);
                tc.randomize();
                `UVM_INFO("WR_SEQ",$sformatf("rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h", tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)
                tc.rst_n        = 1'b1;     //  To make sure reset is 1 while checking of write oper's
                tc.cmd_n        = 1'b0;     //  To make sure cmd_n is 0 while checking of write oper's
                tc.Data_in_vld  = 1'b1;     //  TO make sure Data_in_vld == 1 while checking of  write oper's 
                tc.RDnWR        = 1'b0;     //  To make sure it enters in to the write mode  
            finish_item(tc);
            get_reponse(tc);
        end
    endtask
endclass