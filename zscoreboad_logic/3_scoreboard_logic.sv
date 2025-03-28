module scb_logic;
    typedef struct { int data; time timestamp; } mem_struct;  

    time curr_time;//
    int memory_checker[int];     //
    mem_struct write_log[int];   //

    int Data_out;
    time write_time;//
    time latency;//

    time last_cmd_time[string];  //
    time tck = 5;  //
    time cmd_delays[string];  //


    function void init_delays();
        cmd_delays["READ_to_READ"] = 2 * tck;
        cmd_delays["READ_to_WRITE"] = 4 * tck;
        cmd_delays["WRITE_to_READ"] = 4 * tck;
        cmd_delays["REFRESH_to_RW"] = 5 * tck;
        cmd_delays["ACT_to_RW"] = 5 * tck;
        cmd_delays["RW_to_PRE"] = 4 * tck;
    endfunction

    task check(input [15:0] Addr_in, input [31:0] Data_in, input cmd_n, input RDnWR, input refresh_detected, input act_detected, input pre_detected);
        curr_time = $time;

        if (refresh_detected) begin
            if (last_cmd_time.exists("REFRESH") && curr_time - last_cmd_time["REFRESH"] < cmd_delays["REFRESH_to_RW"]) begin
                $display($time, "  ERROR: REFRESH to READ/WRITE violation! Required: %0t, Got: %0t", cmd_delays["REFRESH_to_RW"], curr_time - last_cmd_time["REFRESH"]);
            end
            last_cmd_time["REFRESH"] = curr_time;
            $display("  REFRESH issued at %0t", curr_time);
            return;
        end

        if (act_detected) begin
            last_cmd_time["ACT"] = curr_time;
            $display("  ACTIVATE issued at %0t", curr_time);
            return;
        end

        if (pre_detected) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["RW_to_PRE"]) begin
                $display($time, "  ERROR: READ/WRITE to PRECHARGE violation! Required: %0t, Got: %0t", cmd_delays["RW_to_PRE"], curr_time - last_cmd_time["READ"]);
            end
            last_cmd_time["PRE"] = curr_time;
            $display("  PRECHARGE issued at %0t", curr_time);
            return;
        end

        if (!cmd_n && RDnWR) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["READ_to_READ"]) begin
                $display($time, "  ERROR: READ to READ violation! Required: %0t, Got: %0t", cmd_delays["READ_to_READ"], curr_time - last_cmd_time["READ"]);
            end
            if (last_cmd_time.exists("WRITE") && curr_time - last_cmd_time["WRITE"] < cmd_delays["WRITE_to_READ"]) begin
                $display($time, "  ERROR: WRITE to READ violation! Required: %0t, Got: %0t", cmd_delays["WRITE_to_READ"], curr_time - last_cmd_time["WRITE"]);
            end

            last_cmd_time["READ"] = curr_time;

            if (memory_checker.exists(Addr_in)) begin
                Data_out = memory_checker[Addr_in];
                write_time = write_log[Addr_in].timestamp;
                latency = curr_time - write_time;
                $display("  READ Success | Addr: %0d | Data: %0d | Latency: %0t", Addr_in, Data_out, latency);
            end 
            else begin
                $display("  ERROR: No data written at Addr %0d", Addr_in);
            end
        end 

        else if (!cmd_n && !RDnWR) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["READ_to_WRITE"]) begin
                $display($time, "  ERROR: READ to WRITE violation! Required: %0t, Got: %0t", cmd_delays["READ_to_WRITE"], curr_time - last_cmd_time["READ"]);
            end

            memory_checker[Addr_in] = Data_in;
            write_log[Addr_in] = '{Data_in, curr_time}; 
            last_cmd_time["WRITE"] = curr_time;
            $display("  WRITE: Addr = %0d, Data = %0d at time %0t", Addr_in, Data_in, curr_time);
        end 
        else begin
            $display("cmd_n is 1, operation not performed");
        end
    endtask
          
    initial begin
        init_delays();

        #10 check(16'h1001, 32'hA5A5A5A5, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0); // ACTIVATE
        #10 check(16'h1001, 32'hA5A5A5A5, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0); // WRITE
        #20 check(16'h1001, 32'h0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);  // READ (valid)
        #10 check(16'h1001, 32'h0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);  // READ (should error, <2tCK)
        #20 check(16'h1001, 32'h0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1);  // PRECHARGE (valid)
        #3200 check(0, 0, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0);  // REFRESH
    end
endmodule


class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    transaction tc;
    uvm_analysis_imp #(transaction, scoreboard) recv;

    // Timing constraints
    time last_cmd_time[string];  // Tracks last issued time for each command type
    time tck = 5;  // Adjust based on your testbench
    time cmd_delays[string];  // Stores expected delays in tCK cycles

    // Memory model for storing write data
    int memory_checker[int];
    typedef struct { int data; time timestamp; } mem_struct;
    mem_struct write_log[int];

    function new(input string path = "scoreboard", uvm_component parent = null);
        super.new(path, parent);
        recv = new("recv", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc", this);
        init_delays();
    endfunction 

    function void init_delays();
        cmd_delays["READ_to_READ"] = 2 * tck;
        cmd_delays["READ_to_WRITE"] = 4 * tck;
        cmd_delays["WRITE_to_READ"] = 4 * tck;
        cmd_delays["REFRESH_to_RW"] = 5 * tck;
        cmd_delays["ACT_to_RW"] = 5 * tck;
        cmd_delays["RW_to_PRE"] = 4 * tck;
    endfunction

    function void write(transaction t);
        time curr_time = $time;

        // Handle REFRESH
        if (t.refresh_detected) begin
            if (last_cmd_time.exists("REFRESH") && curr_time - last_cmd_time["REFRESH"] < cmd_delays["REFRESH_to_RW"]) begin
                `uvm_error("SCOREBOARD", $sformatf("REFRESH to READ/WRITE violation! Required: %0t, Got: %0t", 
                            cmd_delays["REFRESH_to_RW"], curr_time - last_cmd_time["REFRESH"]))
                return;
            end
            last_cmd_time["REFRESH"] = curr_time;
            `uvm_info("SCOREBOARD", $sformatf("REFRESH issued at %0t", curr_time), UVM_MEDIUM)
            return;
        end

        // Handle ACTIVATE
        if (t.act_detected) begin
            last_cmd_time["ACT"] = curr_time;
            `uvm_info("SCOREBOARD", $sformatf("ACTIVATE issued at %0t", curr_time), UVM_MEDIUM)
            return;
        end

        // Handle PRECHARGE
        if (t.pre_detected) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["RW_to_PRE"]) begin
                `uvm_error("SCOREBOARD", $sformatf("READ/WRITE to PRECHARGE violation! Required: %0t, Got: %0t", 
                            cmd_delays["RW_to_PRE"], curr_time - last_cmd_time["READ"]))
                return;
            end
            last_cmd_time["PRE"] = curr_time;
            `uvm_info("SCOREBOARD", $sformatf("PRECHARGE issued at %0t", curr_time), UVM_MEDIUM)
            return;
        end

        // Handle READ
        if (t.cmd_n == 0 && t.RDnWR) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["READ_to_READ"]) begin
                `uvm_error("SCOREBOARD", $sformatf("READ to READ violation! Required: %0t, Got: %0t", 
                            cmd_delays["READ_to_READ"], curr_time - last_cmd_time["READ"]))
                return;
            end
            if (last_cmd_time.exists("WRITE") && curr_time - last_cmd_time["WRITE"] < cmd_delays["WRITE_to_READ"]) begin
                `uvm_error("SCOREBOARD", $sformatf("WRITE to READ violation! Required: %0t, Got: %0t", 
                            cmd_delays["WRITE_to_READ"], curr_time - last_cmd_time["WRITE"]))
                return;
            end

            last_cmd_time["READ"] = curr_time;

            if (memory_checker.exists(t.Addr_in)) begin
                int Data_out = memory_checker[t.Addr_in];
                time write_time = write_log[t.Addr_in].timestamp;
                time latency = curr_time - write_time;
                `uvm_info("SCOREBOARD", $sformatf("READ Success | Addr: %0d | Data: %0d | Latency: %0t", 
                            t.Addr_in, Data_out, latency), UVM_MEDIUM)
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("No data written at Addr %0d", t.Addr_in))
            end
        end 

        // Handle WRITE
        else if (t.cmd_n == 0 && !t.RDnWR) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["READ_to_WRITE"]) begin
                `uvm_error("SCOREBOARD", $sformatf("READ to WRITE violation! Required: %0t, Got: %0t", 
                            cmd_delays["READ_to_WRITE"], curr_time - last_cmd_time["READ"]))
                return;
            end

            memory_checker[t.Addr_in] = t.Data_in;
            write_log[t.Addr_in] = '{t.Data_in, curr_time}; 
            last_cmd_time["WRITE"] = curr_time;
            `uvm_info("SCOREBOARD", $sformatf("WRITE: Addr = %0d, Data = %0d at time %0t", 
                        t.Addr_in, t.Data_in, curr_time), UVM_MEDIUM)
        end 
        else begin
            `uvm_info("SCOREBOARD", "cmd_n is 1, operation not performed", UVM_LOW)
        end
    endfunction

endclass
