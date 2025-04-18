class test extends uvm_test;
    `uvm_component_utils(test)
    
    env e;

    //sequences
    rd_sequence             rd_seq;         // read sequences
    cmd_n_sequence          cdn_seq;        // cmd_n ==1
    rd_sequence_rdm         rd_seq_rdm;        //random sequences
    rst_sequence            rst_seq;        //reset_n == 0
    wr_invld_sequence       wr_invld_seq;    // data_in_vald == 0
    wr_sequence             wr_seq;         // wr== 1 sequence

    scoreboard s;


    function new(input string path = "test",uvm_component parent = null);
        super.new(path,parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cdn_seq             = cmd_n_sequence::type_id::create("cdn_seq",this);
        rd_seq_rdm          = rd_sequence_rdm::type_id::create("rdm_seq",this);
        rst_seq             = rst_sequence::type_id::create("rst_seq",this);
        wr_invld_seq        = wr_invld_sequence::type_id::create("wr_invld_seq",this);
        wr_seq              = wr_sequence::type_id::create("wr_seq",this);
        rd_seq              = rd_sequence::type_id::create("rd_seq",this);
        e                   = env::type_id::create("e",this);

    endfunction


    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                wr_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                rd_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();
                
                wr_invld_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();


                wr_invld_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_invld_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_invld_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_invld_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                wr_invld_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                cdn_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                cdn_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                cdn_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                cdn_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                cdn_seq.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                rd_seq_rdm.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

                rd_seq_rdm.start(e.a.seqr);
                e.s.sb_done.wait_trigger();

        phase.drop_objection(this);
    endtask
endclass