class env extends uvm_env;
    `uvm_component_utils(env)

    agent a;
    scoreboard s;
    ref_model rf_mdl;
    uvm_event data_ready_evt;

    function new(input string path = "env",uvm_component parent = null);
        super.new(path,parent);
        data_ready_evt = uvm_event_pool::get_global_pool().get("data_ready");

    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a       = agent::type_id::create("a",this);
        s       = scoreboard::type_id::create("s",this);
        rf_mdl  = ref_model::type_id::create("rf_mdl", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a.m.send.connect(s.recv_from_mon);
        a.m.send.connect(rf_mdl.rcv_mon);  
        rf_mdl.snd_sbd.connect(s.recv_from_ref);
    endfunction
endclass