class wr_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(wr_sequence)

    transaction tc;

    function new(input string path = "wr_sequence");
        super.new(path);
    endfunction

    virtual task body();
        tc = transaction::type_id::create("tc");
            start_item(tc);

                if(!tc.randomize())begin
                    `uvm_error("WR_SEQ","Randomization failed")
                end
                else begin
                    tc.rst_n        = 1'b1;     //  To make sure reset is not asserted while checking of cmd_n 
                    tc.cmd_n        = 1'b0;     //  To make sure cmd_n is not 1 which would prevent from entering into read state
                    tc.RDnWR        = 1'b0;        //  Write mode  
                    tc.Data_in_vld  = 1'b1; 
                    `uvm_info("wr_sequence",$sformatf("rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h", tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)   
                    addr_in_queue.push_back(tc.Addr_in);
                    #220;
                    tc.Data_in_vld  = 1'b1; 
                    finish_item(tc);
                
                end
        endtask
endclass