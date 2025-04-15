class rd_sequence extends uvm_sequence#(transaction); // extends keyword add kiya
    `uvm_object_utils(rd_sequence)

    transaction tc;
    
    function new(input string path = "rd_sequence");
        super.new(path);
    endfunction

    virtual task body();
        tc = transaction::type_id::create("tc");
            start_item(tc);
            if (addr_in_queue.size() > 0) begin
                int index = $urandom_range(0, addr_in_queue.size() - 1);                
                tc.Addr_in = addr_in_queue[index]; 
            end 
            else begin
                if(!tc.randomize())begin
                    `uvm_error("RD_SEQ", "Randomization failed")
                end
            end
            tc.rst_n = 1'b1;    // Reset is deasserted
            tc.cmd_n = 1'b0;    // Command valid
            tc.RDnWR = 1'b1;    // Read mode
            
            `uvm_info("RD_SEQ", $sformatf("rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h", 
                    tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in), UVM_NONE)

            finish_item(tc);
    endtask

endclass
