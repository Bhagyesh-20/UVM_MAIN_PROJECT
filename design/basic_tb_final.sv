`timescale 1ns/1ps

module mem_ctrl_tb;
    
    logic clk;
    logic rst_n;
    logic cmd_n;
    logic RDnWR;
    logic Data_in_vld;
    logic [15:0] Addr_in;
    logic [31:0] Data_in;
    wire [31:0] DQ; // Bidirectional data bus
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
    
    // Clock generation (100MHz clock -> 10ns period)
    always #5 clk = ~clk;

    // Bidirectional DQ handling
    assign DQ = (!RDnWR && Data_in_vld) ? Data_in : 'z;
    
    // Task for Write Operation (Only writes when Data_in_vld is HIGH)
    task write(input [15:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            Addr_in = addr;
            Data_in = data;
            Data_in_vld = 1;
            RDnWR = 0; // Write mode
            cmd_n = 0;
          repeat (20) @(posedge clk);
            Data_in_vld = 0; // De-assert after one cycle
            @(posedge clk);
            cmd_n = 1;
            $display("[WRITE] Addr: %h, Data: %h", addr, data);
        end
    endtask
  
    // Task for Write Operation when Data_in_vld is 0 (Should not write)
    task write_invld(input [15:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            Addr_in = addr;
            Data_in = data;
            RDnWR = 0; // Write mode
            cmd_n = 0;
            @(posedge clk);
            Data_in_vld = 0; // Keep invalid
            @(posedge clk);
            cmd_n = 1;
            $display("[WRITE_INVLD] Addr: %h, Data: %h (SHOULD NOT WRITE)", addr, data);
        end
    endtask

    // Task for Read Operation
    task read(input [15:0] addr);
        begin
            @(posedge clk);
            Addr_in = addr;
            RDnWR = 1; // Read mode
            cmd_n = 0;
            @(posedge clk);
            cmd_n = 1;
            repeat(3) @(posedge clk); // Simulate tCAS delay
            $display("[READ] Addr: %h, DataOut: %h, Valid: %b", addr, Data_out, data_out_vld);
        end
    endtask

    initial begin
        
        // Monitor key signals
        $monitor($time, " Data_in_vld=%b | rst_n=%h | Addr=%h | cmd_n=%b | RDnWR=%b | DataIn=%h | DQ=%h | DataOut=%h | Cmd=%d | DataOutVld=%b | RA=%0b | CA=%0b | cs_n=%b", 
                 Data_in_vld, rst_n, Addr_in, cmd_n, RDnWR, Data_in, DQ, Data_out, command, data_out_vld, RA, CA, cs_n);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        cmd_n = 0;
        RDnWR = 0;
        Data_in_vld = 0;
        Addr_in = 16'h0000;
        Data_in = 32'h00000000;
        
        // Reset sequence
        #20 rst_n = 1;
      
        // WRITE - Address 0x1001, Data A5A5A5A5
        #100 write(16'h1001, 32'hA5A5A5A5);
        
        // WRITE - Address 0x2000, Data DEADBEEF
        #200 write(16'h2000, 32'hDEADBEEF);

        // WRITE with Data_in_vld = 0 (Should NOT write)
        #300 write_invld(16'h3000, 32'h12345678);
        
        // READ - Address 0x1001
        #400 read(16'h1001);
        
        // READ - Address 0x2000
        #500 read(16'h2000);
        
        // READ - Address 0x3000 (Should return unknown or 0 if not written)
        #600 read(16'h3000);

        // Refresh test
        #700;
        
        // READ after refresh (Check if data remains)
        #800 read(16'h1001);
        #900 read(16'h2000);
        
        #1000;
        $finish;
    end
    
endmodule
