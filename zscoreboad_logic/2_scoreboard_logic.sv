module scb_logic;
   typedef struct { int data; time timestamp; } mem_struct;  

   time curr_time;
   int memory_checker[int];     
   mem_struct write_log[int];   

   int Data_out;
   time write_time;
   time latency;

   time last_refresh_time = 0;  // 🔹 Track Last Refresh Time
   int refresh_count = 0;
   time refresh_interval = 3200;  // 🔹 Expected Refresh Interval (3.2µs)

   task check(input [15:0] Addr_in, input [31:0] Data_in, input cmd_n, input RDnWR, input refresh_detected);
       curr_time = $time;  

       if (refresh_detected) begin
           refresh_count++;
           
           // 🔹 Check if refresh is happening at the correct interval
           if (last_refresh_time != 0) begin
               automatic time refresh_gap = curr_time - last_refresh_time;
               if (refresh_gap < refresh_interval - 100 || refresh_gap > refresh_interval + 100) begin
                 $display($time, " ERROR: Refresh timing mismatch! Expected: %0t, Got: %0t", refresh_interval, refresh_gap);
               end else begin
                 $display(" REFRESH CHECK PASSED | Time Since Last Refresh: %0t refresh count = %0d", refresh_gap, refresh_count);
               end
           end
           
           last_refresh_time = curr_time;  // Update Last Refresh Time
       end 
       else if (!cmd_n) begin  
           if (RDnWR) begin
               if (memory_checker.exists(Addr_in)) begin
                   Data_out = memory_checker[Addr_in];
                   $display("Read successful | Addr: %0d | Data: %0d | Latency: %0t", Addr_in, Data_out, latency);
                   end
               end 
               else begin
                   $display(" ERROR: No data written at Addr %0d", Addr_in);
               end
           end 
           else begin
               memory_checker[Addr_in] = Data_in;
               write_log[Addr_in] = '{Data_in, curr_time}; 
               $display(" Write: Addr = %0d, Data = %0d at time %0t", Addr_in, Data_in, curr_time);
           end 
       else begin
           $display(" cmd_n is 1, operation not performed");
       end
   endtask
         
   initial begin
       #10 check(16'h1001, 32'hA5A5A5A5, 1'b0, 1'b1, 1'b0);
       #10 check(16'h1001, 32'hA5A5A5A5, 1'b0, 1'b0, 1'b0);
       #10 check(16'h2000, 32'hdeadbeef, 1'b0, 1'b0, 1'b0);
       #3200 check(0, 0, 1'b1, 1'b1, 1'b1);  // 🔹 Simulating a Refresh Event
        #10 check(16'h1001, 32'h5A5A5A5A, 1'b0, 1'b0, 1'b0);
       #3200 check(0, 0, 1'b1, 1'b1, 1'b1);  // 🔹 Another Refresh
        #10 check(16'h1001, 32'hA5A5A5A5, 1'b0, 1'b1, 1'b0);
   end
endmodule
