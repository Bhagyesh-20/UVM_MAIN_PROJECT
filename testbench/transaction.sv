class transaction extends uvm_sequence_item;

    //inputs
    rand bit            rst_n;
    rand bit            cmd_n;
    rand bit            RDnWR;
    rand bit [15:0]     Addr_in;
    rand bit            Data_in_vld;
    rand bit [31:0]     Data_in;

    //outputs
    bit [31:0]  Data_out;
    bit         data_out_vld;
    bit [2:0]   command;
    bit [3:0]   RA;
    bit [11:0]  CA;
    bit         cs_n;

    function new(input string path ="transaction");
        super.new(path);
    endfunction

    `uvm_object_utils_begin(transaction)
        uvm_field_int(rst_n,UVM_DEFAULT)
        uvm_field_int(cmd_n,UVM_DEFAULT)
        uvm_field_int(RDnWR,UVM_DEFAULT)
        uvm_field_int(Addr_in,UVM_DEFAULT)
        uvm_field_int(Data_in_vld,UVM_DEFAULT)
        uvm_field_int(Data_in, UVM_DEFAULT)
        uvm_field_int(Data_out,UVM_DEFAULT)
        uvm_field_int(data_out_vld,UVM_DEFAULT)
        uvm_field_int(command,UVM_DEFAULT)
        uvm_field_int(RA,UVM_DEFAULT)
        uvm_field_int(CA,UVM_DEFAULT)
        uvm_field_int(cs_n,UVM_DEFAULT)
    `uvm_object_utils_end

endclass


