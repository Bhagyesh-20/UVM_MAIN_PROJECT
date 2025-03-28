module scb_logic;
    typedef struct {int data, time timestamp} mem_struct;
    
    time curr_time;

    int memory_checker[int];    
    mem_entry write_log[int];
    int Data_out;
    time write_time;
    time latency;

    task check(input [15:0] Addr_in, input [31:0] Data_in, input cmd_n, input RDnWR);
            curr_time = $time;  // Capture the current simulation time
          
              if (cmd_n) begin
                 if (RDnWR) begin
                    // Read operation
                    if (memory_checker.exists(Addr_in)) begin
                        Data_out = memory_checker[Addr_in];
                        write_time = write_log[Addr_in].timestamp;
          
                       // Calculate delay
                        latency = curr_time - write_time;
                      
                       // Check if latency meets expected range (adjust as needed)
                       if (latency < 10 || latency > 50) begin
                          $display("ERROR: Read timing mismatch at Addr %0d | Expected: 10-50, Got: %0t", Addr_in, latency);
                       end else begin
                          $display("Read successful at Addr %0d | Data: %0d | Latency: %0t", Addr_in, Data_out, latency);
                       end
                    end else begin
                       $display("No data written at this address");
                    end
                 end else begin
                    // Write operation
                    memory_checker[Addr_in] = Data_in;
                    write_log[Addr_in] = '{Data_in, curr_time}; // Store write time
                    $display("Write: Addr = %0d, Data = %0d at time %0t", Addr_in, Data_in, curr_time);
                 end
              end else begin
                 $display("cmd_n is 0, operation not performed");
              end
           endtask
          
           initial begin
            #10 check(16'h1001,32'hA5A5A5A5,1'b1,1'b1);	// Should not perform any read or write
            #10 check(16'h1001,32'hA5A5A5A5,1'b0,1'b1);	// 1st read should display no operations performed till now
            
            #10 check(16'h1001,32'hA5A5A5A5,1'b0,1'b0); // 1st write of the address 16'h1001
            #10 check(16'h1001,32'hA5A5A5A5,1'b0,1'b1);	// 1st read  of the address 16'h1001
            
            #10 check(16'h2000,32'hdeadbeef,1'b0,1'b0); // 1st write of the address 16'h2000
            #10 check(16'h2000,32'hdeadbeef,1'b0,1'b1); // 1st read  of the address 16'h2000
            
            
            #10 check(16'h1001,32'h5A5A5A5A,1'b0,1'b0); // 2nd write of the address 16'h1001
            #10 check(16'h1001,32'hA5A5A5A5,1'b0,1'b1);	// 2nd read  of the address 16'h1001
          end
          


endmodule