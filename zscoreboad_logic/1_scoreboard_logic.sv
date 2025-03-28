module scb_logic;

   typedef struct {int data,time timestamp} mem_entry;
   

   bit cmd_n;
   bit RDnWR;
   int Addr_in; 
   int Data_in;
   int Data_in_vld;
   
   int RA;
   int CA;

      // Associative array to store memory data
      int memory_checker[int];
   
      task check(input [15:0] Addr_in, input [31:0] Data_in, input cmd_n, input RDnWR);
         if (!cmd_n) begin
            if (RDnWR) begin // Read oper
               if (memory_checker.num() == 0) begin
                  $display("No operations performed till now");
               end 
               else if (memory_checker.exists(Addr_in)) begin
                  int Data_out = memory_checker[Addr_in];
                  {RA, CA}     = Addr_in;
                  $display("Memory at Addr_in = %0d contains Data = %0d", RA = , CA = , Data_out);
               end 
               else begin
                  $display("No data written at this address");
               end
            end 
            else begin  // Write oper
               memory_checker[Addr_in] = Data_in;
               $display("Memory at Addr_in = %0d updated with Data = %0d", Addr_in, Data_in);
            end
         end 
         else begin
            $display("cmd_n is 0, operation not performed");
         end
      endtask

      initial begin
      #10 check(16'h1001,32'A5A5A5A5,1'b0,1'b0); // 1st write
      end


   endmodule
   


//    typedef struct {
//       int data;
//       time timestamp;
//   } mem_entry;
  
//   int memory_checker[int];  // Associative array for memory storage
//   mem_entry write_log[int]; // Store write times
  
//   task check(input [15:0] Addr_in, input [31:0] Data_in, input cmd_n, input RDnWR);
//      time curr_time = $time;  // Capture the current simulation time
  
//      if (cmd_n) begin
//         if (RDnWR) begin
//            // Read operation
//            if (memory_checker.exists(Addr_in)) begin
//               int Data_out = memory_checker[Addr_in];
//               time write_time = write_log[Addr_in].timestamp;
  
//               // Calculate delay
//               time latency = curr_time - write_time;
              
//               // Check if latency meets expected range (adjust as needed)
//               if (latency < 10 || latency > 50) begin
//                  $display("ERROR: Read timing mismatch at Addr %0d | Expected: 10-50, Got: %0t", Addr_in, latency);
//               end else begin
//                  $display("Read successful at Addr %0d | Data: %0d | Latency: %0t", Addr_in, Data_out, latency);
//               end
//            end else begin
//               $display("No data written at this address");
//            end
//         end else begin
//            // Write operation
//            memory_checker[Addr_in] = Data_in;
//            write_log[Addr_in] = '{Data_in, curr_time}; // Store write time
//            $display("Write: Addr = %0d, Data = %0d at time %0t", Addr_in, Data_in, curr_time);
//         end
//      end else begin
//         $display("cmd_n is 0, operation not performed");
//      end
//   endtask
  