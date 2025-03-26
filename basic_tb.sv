`timescale 1ns/1ps

module mem_ctrl_tb;
    
    logic clk;
    logic rst_n;
    logic cmd_n;
    logic RDnWR;
    logic Data_in_vld;
    logic [15:0] Addr_in;
    logic [31:0] Data_in;
    wire [31:0] DQ; // Corrected: inout requires wire
    logic [31:0] Data_out;
    logic data_out_vld;
    logic [2:0] command;
    logic [3:0] RA;
    logic [11:0] CA;
    logic cs_n;
    
    // Instantiate the DUT
    mem_ctrl uut (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_n(cmd_n),
        .RDnWR(RDnWR),
        .Data_in_vld(Data_in_vld),
        .Addr_in(Addr_in),
        .Data_in(Data_in),
        .DQ(DQ),
        .Data_out(Data_out),
        .data_out_vld(data_out_vld),
        .command(command),
        .RA(RA),
        .CA(CA),
        .cs_n(cs_n)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Drive the bidirectional DQ correctly
    assign DQ = (RDnWR == 0 && Data_in_vld) ? Data_in : 'z;
    
    initial begin
        // Monitor key signals
      $monitor("Time=%0t | rst_n =%h| Addr=%h| cmd_n = %b |RDnWR = %b| DataIn=%h | DQ=%h | DataOut=%h | Cmd=%b | DataOutVld=%b|RA =%0b |CA = %0b | cs_n=%b",
                 $time,rst_n, Addr_in,cmd_n,RDnWR, Data_in, DQ, Data_out, command, data_out_vld,RA,CA, cs_n);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        cmd_n = 1;
        RDnWR = 0;
        Data_in_vld = 0;
        Addr_in = 16'h0000;
        Data_in = 32'h00000000;
        
        // Reset sequence
        #10 rst_n = 1;
      
        // Write operation
        #20 Addr_in = 16'h1001;
        Data_in = 32'hA5A5A5A5;
        Data_in_vld = 1;
        RDnWR = 0; // Write mode
        #10 Data_in_vld = 0;
        
        // Read operation
         cmd_n = 0;

        #50; 
      	Data_in = 32'h0;

      	Addr_in = 16'h1001;
        RDnWR = 1; // Read mode
        
        
        // Finish simulation
        #300;
      $finish;
    end
    
endmodule
