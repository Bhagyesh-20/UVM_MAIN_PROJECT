interface mem_ctrl_if();
    
    logic        clk;
    logic        rst_n;
    logic        cmd_n;
    logic        RDnWR;      
    logic [15:0] Addr_in;      
    logic        Data_in_vld;  
    logic [31:0] Data_in;
    logic [31:0] Data_out;     
    logic        data_out_vld; 
    logic [2:0]  command;
    logic [3:0]  RA;           
    logic [11:0] CA;           
    logic        cs_n;  
    wire        DQ;

    modport DUT (input clk, rst_n, cmd_n, RDnWR, Addr_in, Data_in_vld, Data_in,
                 output Data_out, data_out_vld, command, RA, CA, cs_n, 
                 inout DQ);

    modport TB (output cmd_n, RDnWR, Addr_in, Data_in_vld, Data_in,
                input Data_out, data_out_vld, command, RA, CA, cs_n);

endinterface