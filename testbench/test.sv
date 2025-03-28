class test extends uvm_test;
    `uvm_component_utils(test)
    
    env e;

    //sequences
    rd_sequence             rd_seq;         // read sequences
    cmd_n_sequence          cdn_seq;        // cmd_n ==1
    randomize_sequence      rdm_seq;        //random sequences
    rst_sequence            rst_seq;        //reset_n == 0
    wr_invld_sequence       wr_nvld_seq;    // data_in_vald == 0
    wr_sequence             wr_seq;         // wr== 1 sequence



    function new(input string path = "test",uvm_component parent = null);
        super.new(path,parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.new(phase);
        cdn_seq             = cmd_n_sequence::type_id::create("cdn_seq",this);
        rdm_seq             = randomize_sequence::type_id::create("rdm_seq",this);
        rst_seq             = rst_sequence::type_id::create("rst_seq",this);
        wr_invld_sequence   = wr_nvld_seq::type_id::create("wr_nvld_seq",this);
        wr_seq              = wr_sequence::type_id::create("wr_seq",this);
        rd_seq              = rd_sequence::type_id::create("rd_seq",this);
        e                   = env::type_id::create("e",this);
    endfunction


    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
            rst_seq.start(e.a.seqr);
            cdn_seq.start(e.a.seqr);
            rdm_seq.start(e.a.seqr);
            wr_nvld_seq.start(e.a.seqr);
            wr_seq.start(e.a.seqr);
            rd_seq.start(e.a.seqr);
        phase.drop_objection(this);
    endtask

endclass