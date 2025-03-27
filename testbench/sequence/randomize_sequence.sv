class randomize_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(randomize_sequence)

    transaction tc;

    function new(input string path = "randomize_sequence");
        super.new(path);
    endfunction

    virtual task body();
        tc = transaction::type_id::create("tc",this);
        repeat(5) begin
            start_item(tc);
                tc.randomize();
                `UVM_INFO("RNDM_SEQ",$sformatf("rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h", tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in),UVM_NONE)
            finish_item(tc);
            get_reponse(tc);
        end
    endtask
endclass