class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    transaction tc;
    uvm_analysis_imp #(transaction,scoreboard) recv;

    function new(input string path = "scoreboard",uvm_component parent = null);
        super.new(path,parent);
        recv = new("recv",this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc",this);
    endfunction 

    typedef struct {int data; time timestamp;} mem_struct;
    
    time        curr_time;
    time        write_time;
    time        latency;
    time        tck = 5;

    time        last_cmd_time[string];
    time        cmd_delay[string];

    int         memory_checker[int];
    int         RA;
    int         CA;
    bit         expdata_out_vld;
    mem_struct  write_log[int];

    function void init_delays();
        cmd_delays["READ_to_READ"] = 2 * tck;
        cmd_delays["READ_to_WRITE"] = 4 * tck;
        cmd_delays["WRITE_to_READ"] = 4 * tck;
        cmd_delays["REFRESH_to_RW"] = 5 * tck;
        cmd_delays["ACT_to_RW"] = 5 * tck;
        cmd_delays["RW_to_PRE"] = 4 * tck;
    endfunction

    virtual function void write(transaction t);
        tc        = t;
        curr_time = $time;

        if(tc.refresh_detected)begin
            if(last_cmd_time.exists("REFRESH") && curr_time - last_cmd_time["REFRESH"]<cmd_delays["REFRESH_to_RW"])begin
                `uvm_error("SBD", $sformatf("REFRESH to READ/WRITE violation! Required: %0t, Got: %0t", 
                cmd_delays["REFRESH_to_RW"], curr_time - last_cmd_time["REFRESH"]))
                return;
            end
            last_cmd_time["REFRESH"] = curr_time;
            `uvm_info("SBD", $sformatf("REFRESH issued at %0t",curr_time), UVM_NONE)
            return;
        end

        if(tc.act_detected)begin
            last_cmd_time["ACT"] = curr_time;
            `uvm_info("SBD", $sformatf("ACTIVATE issued at %0t", curr_time), UVM_NONE)
        end

        if (tc.pre_detected) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["RW_to_PRE"]) begin
                `uvm_error("SBD", $sformatf("READ/WRITE to PRECHARGE violation! Required: %0t, Got: %0t", 
                            cmd_delays["RW_to_PRE"], curr_time - last_cmd_time["READ"]))
                return;
            end
            last_cmd_time["PRE"] = curr_time;
            `uvm_info("SBD", $sformatf("PRECHARGE issued at %0t", curr_time), UVM_NONE)
            return;
        end

        //READ OPER's
        if (tc.cmd_n == 0 && tc.RDnWR) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["READ_to_READ"]) begin
                `uvm_error("SBD", $sformatf("READ to READ violation! Required: %0t, Got: %0t", 
                            cmd_delays["READ_to_READ"], curr_time - last_cmd_time["READ"]))
                return;
            end

            if (last_cmd_time.exists("WRITE") && curr_time - last_cmd_time["WRITE"] < cmd_delays["WRITE_to_READ"]) begin
                `uvm_error("SBD", $sformatf("WRITE to READ violation! Required: %0t, Got: %0t", 
                            cmd_delays["WRITE_to_READ"], curr_time - last_cmd_time["WRITE"]))
                return;
            end

            last_cmd_time["READ"] = curr_time;

            if (memory_checker.exists(tc.Addr_in)) begin

                expected_data_out   = memory_checker[tc.Addr_in];
                expected_RA         = Addr_in[15:12];
                expected_CA         = Addr_in[11:0];
                expdata_out_vld     = 1'b1;
                expected_cs_n       = 1'b0;
                time write_time     = write_log[tc.Addr_in].timestamp;
                time latency        = curr_time - write_time;

                if((expected_data_out == tc.Data_out) && (expected_CA == tc.CA) && (expected_RA == tc.RA) && (expdata_out_vld == tc.data_out_vld) && (expected_cs_n == tc.cs_n))begin
                    `uvm_info("SBD", $sformatf("READ Success | Addr: %0h | Data: %0h | Latency: %0t", tc.Addr_in, Data_out, latency), UVM_NONE)
                end

                else begin
                    `uvm_error("SBD",$sformatf("READ Failure Expected Data = %0h "))
                end

            end 
            else begin
                `uvm_error("SBD", $sformatf("No data written at Addr %0d", tc.Addr_in))
            end
        end

        else if (t.cmd_n == 0 && !t.RDnWR) begin
            if (last_cmd_time.exists("READ") && curr_time - last_cmd_time["READ"] < cmd_delays["READ_to_WRITE"]) begin
                `uvm_error("SBD", $sformatf("READ to WRITE violation! Required: %0t, Got: %0t", 
                            cmd_delays["READ_to_WRITE"], curr_time - last_cmd_time["READ"]))
                return;
            end

            memory_checker[tc.Addr_in] = tc.Data_in;
            write_log[tc.Addr_in] = '{tc.Data_in, curr_time}; 
            last_cmd_time["WRITE"] = curr_time;
            `uvm_info("SBD", $sformatf("WRITE: Addr = %0d, Data = %0d at time %0t", 
                        tc.Addr_in, tc.Data_in, curr_time), UVM_NONE)
        end 
        else begin
            `uvm_info("SBD", "cmd_n is 1, operation not performed", UVM_NONE)
        end

    endfunction

endclass