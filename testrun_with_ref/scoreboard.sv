`uvm_analysis_imp_decl(_ref)
`uvm_analysis_imp_decl(_mon)
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    virtual mem_ctrl_if mcif;
    uvm_event sb_done;
    transaction tc;
    transaction ex;

    uvm_analysis_imp_ref  #(transaction, scoreboard) recv_from_mon;
    uvm_analysis_imp_mon  #(transaction, scoreboard) recv_from_ref;


    function new(input string path = "scoreboard",uvm_component parent = null);
        super.new(path,parent);
        recv_from_mon = new("recv_from_mon",this);
        recv_from_ref = new("recv_from_ref",this);
        sb_done       = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc",this);
        ex = transaction::type_id::create("ex",this);
        if (!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif)) begin
            `uvm_fatal("SBD", "mcif interface handle is NULL. Check interface connection.")
        end
    endfunction 

    virtual function void write_ref(transaction e);
        `uvm_info("SBD_REF",$sformatf("Data received from rf_mdl to the scoreboard"),UVM_NONE)
        sb_done.trigger();
    endfunction

    virtual function void write_mon(transaction t);
        sb_done.trigger();
    endfunction


    function void comparison();
    endfunction

    // virtual function void check_phase(uvm_phase phase);
    //     super.check_phase(phase);
    //     `uvm_info("SBD_CP",$sformatf("tc from dut : %0p",tc),UVM_NONE);
        
    //     `uvm_info("SBD_CP",$sformatf("ex from dut : %0p",ex),UVM_NONE);
    //     `uvm_info("SBD_CP","Check phase",UVM_NONE);
    // endfunction


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

    // function void compare_DO(input bit [31:0] from_sbd, input bit [31:0] from_tc);
    //         if (from_sbd == from_tc) begin
    //             `uvm_info("SBD_READ_DO", $sformatf("Data out success expected = %0h | got = %0h | mcif_command = %0d | tc_command = %0d", from_sbd, from_tc,mcif.command,tc.command), UVM_NONE);
    //         end
    //         else begin
    //             `uvm_error("SBD_READ_DO", $sformatf("Data out failure expected = %0h | got = %0h | mcif_data_out = %0h | mcif_command = %0d | tc_command = %0d", from_sbd, from_tc,mcif.Data_out, mcif.command,tc.command));
    //         end
    // endfunction
endclass



