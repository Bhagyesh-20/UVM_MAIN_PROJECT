class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    virtual mem_ctrl_if mcif;
    
    bit             expected_data_out_vld;
    bit             expected_cs_n;
    bit [31:0]      expected_data_out;
    int             memory_checker[int];
    bit [3:0]       expected_RA;
    bit [11:0]      expected_CA;

    uvm_event sb_done;
    transaction tc;
    uvm_analysis_imp #(transaction,scoreboard) recv;

    function new(input string path = "scoreboard",uvm_component parent = null);
        super.new(path,parent);
        recv = new("recv",this);
        sb_done = new();
        
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc");
        if (!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif)) begin
            `uvm_fatal("SBD", "mcif interface handle is NULL. Check interface connection.")
        end
    endfunction 


    function void write(transaction t);
        tc = t;
       //`uvm_info("SBD_ARR",$sformatf("Transaction received: %p data_out_vld_if: %0b data_out_vld_tr: %0b",memory_checker, mcif.data_out_vld,tc.data_out_vld), UVM_NONE)
        
        //READ OPER's
        if (tc.cmd_n == 0 && tc.RDnWR) begin
            if (memory_checker.exists(tc.Addr_in)) begin
                expected_data_out       = memory_checker[tc.Addr_in];
                expected_RA             = tc.Addr_in[15:12];
                expected_CA             = tc.Addr_in[11:0];
                expected_data_out_vld   = 1'b1;
                expected_cs_n           = 1'b0;

                if(mcif.data_out_vld && tc.data_out_vld && tc.command!=3'b010 && mcif.command!=3'b010)begin
                    compare_RA(expected_RA,tc.RA);                  // checking of Row Address
                    compare_CA(expected_CA,tc.CA);                  // checking of Col Address
                    compare_CN(expected_cs_n,tc.cs_n);              // checking of cs_n bit
                    fork 
                        compare_DO(expected_data_out,tc.Data_out);      // checking of Data_out
                    join_none
                end
            end 
            else begin
                sb_done.trigger();
                `uvm_error("SBD", $sformatf("No data written at Addr %0h", tc.Addr_in))
            end
        end
        // write oper's
        else if (tc.cmd_n == 0 && !tc.RDnWR && tc.Data_in_vld) begin
            if(!memory_checker.exists(tc.Addr_in))begin
                memory_checker[tc.Addr_in] = tc.Data_in;
                `uvm_info("SBD", $sformatf("WRITE: Addr = %0h, Data = %0h", tc.Addr_in, tc.Data_in), UVM_NONE)
                sb_done.trigger();
            end
            
            else begin
                if(memory_checker[tc.Addr_in]!=tc.Data_in)begin
                    `uvm_info("SBD", $sformatf("WRITE: Addr = %0h, Data = %0h", tc.Addr_in, tc.Data_in), UVM_NONE)
                    sb_done.trigger();
                end
                else begin
                    sb_done.trigger();
                    return;
                end
            end
           
        end 

        else begin
            `uvm_info("SBD", "cmd_n is 1 or data_in is not vld, operation not performed", UVM_NONE)
            sb_done.trigger();
            return;
        end
    endfunction

    function void compare_RA(input [3:0] from_sbd,input [3:0] from_tc);
            if(from_sbd == from_tc)begin
                `uvm_info("SBD_READ_RA","RA Success",UVM_NONE);
            end
            else begin
                `uvm_error("SBD_READ_RA",$sformatf("RA failure expected = %0h | got = %0h",from_sbd,from_tc));
            end
    endfunction

    function void compare_CA(input [11:0] from_sbd,input [11:0] from_tc);
            if(from_sbd == from_tc)begin
                `uvm_info("SBD_READ_CA","CA Success",UVM_NONE);
            end
            else begin
                `uvm_error("SBD_READ_CA",$sformatf("CA failure expected = %0h | got = %0h",from_sbd,from_tc));
            end
    endfunction


    function void compare_CN(input from_sbd,input from_tc);
        if(from_sbd == from_tc )begin
            `uvm_info("SBD_READ_CN","Csn Success",UVM_NONE);
        end
        else begin
            `uvm_error("SBD_READ_CN",$sformatf("Csn failure expected = %0h | got = %0h",from_sbd,from_tc));
        end
    endfunction

    task compare_DO(input bit [31:0] from_sbd, input bit [31:0] from_tc);
        @(posedge mcif.clk);
        begin
            
            if (from_sbd == from_tc) begin
                `uvm_info("SBD_READ_DO", $sformatf("Data out success had = %0h expected = %0h | got = %0h | mcif_command = %0d | tc_command = %0d", memory_checker[tc.Addr_in], from_sbd, from_tc,mcif.command,tc.command), UVM_NONE);
            end
            else begin
                `uvm_error("SBD_READ_DO", $sformatf("Data out failure expected = %0h | got = %0h | mcif_command = %0d | tc_command = %0d", from_sbd, from_tc, mcif.command,tc.command));
            end
            sb_done.trigger();
        end
    endtask
endclass