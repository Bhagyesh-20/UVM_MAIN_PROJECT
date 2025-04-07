
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    virtual mem_ctrl_if mcif;
    
    uvm_event   sb_done;
    transaction tc;
    transaction expected;

    // ref_model rf_mdl;
    //monitor m;
    uvm_analysis_imp        #(transaction,scoreboard) recv_from_mon_to_sbd;
    uvm_blocking_put_imp #(transaction, scoreboard) recv_from_ref;




    function new(input string path = "scoreboard",uvm_component parent = null);
        super.new(path,parent);
        recv_from_mon_to_sbd        = new("recv_from_mon_to_sbd",this);
        recv_from_ref               = new("recv_from_ref",this);
        sb_done = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc          = transaction::type_id::create("tc");
        expected = transaction::type_id::create("expected");
        // rf_mdl      = ref_model::type_id::create("rf_mdl",this);
        //m           = monitor::type_id::create("m",this);
        if (!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif)) begin
            `uvm_fatal("SBD", "mcif interface handle is NULL. Check interface connection.")
        end
    endfunction 

   task put(transaction tr);
    expected = tr;
    `uvm_info("SBD", $sformatf("Received from refmodel: RA=%h CA=%h Data=%h", 
    tr.expected_RA, tr.expected_CA, tr.expected_data_out), UVM_NONE)

   endtask

    function void write(transaction t);
        
        `uvm_info("SBD","DATA GOT from monitor",UVM_NONE)
        tc = t;
        
        `uvm_info("SBD", $sformatf("mcif.data_out_vld=%0b, tc.data_out_vld=%0b, tc.command=%0b, mcif.command=%0b",
        mcif.data_out_vld, tc.data_out_vld, tc.command, mcif.command), UVM_NONE)
        
        if( tc.command!=3'b010 && mcif.command!=3'b010 && tc.RDnWR)begin
            fork
             compare_RA(expected.expected_RA,tc.RA);                  // checking of Row Address
             compare_CA(expected.expected_CA,tc.CA);                  // checking of Col Address
             compare_CN(expected.expected_cs_n,tc.cs_n);              // checking of cs_n bit
             compare_DO(expected.expected_data_out,tc.Data_out);      // checking of Data_out
            sb_done.trigger();
            join_none
        end
            
        else begin
            `uvm_info("SBD","Else block",UVM_NONE);
            sb_done.trigger();
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
                `uvm_info("SBD_READ_DO", $sformatf("Data out success expected = %0h | got = %0h | mcif_command = %0d | tc_command = %0d", from_sbd, from_tc,mcif.command,tc.command), UVM_NONE);
            end
            else begin
                `uvm_error("SBD_READ_DO", $sformatf("Data out failure expected = %0h | got = %0h | mcif_command = %0d | tc_command = %0d", from_sbd, from_tc, mcif.command,tc.command));
            end
            sb_done.trigger();
        end
    endtask
endclass