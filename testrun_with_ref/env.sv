class env extends uvm_env;
    `uvm_component_utils(env)

    agent a;
    scoreboard s;
    ref_model rf_mdl;
    //uvm_event data_ready;

    function new(input string path = "env",uvm_component parent = null);
        super.new(path,parent);
      //  data_ready = new("data_ready"); 
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a       = agent::type_id::create("a",this);
        s       = scoreboard::type_id::create("s",this);
        rf_mdl  = ref_model::type_id::create("rf_mdl", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // a.m.set_event(data_ready);  // Monitor gets the event
        // s.set_event(data_ready); 
        a.m.send.connect(s.recv_from_mon_to_sbd);
        a.d.send_to_ref_drv.connect(rf_mdl.recv_from_drv_to_ref_mdl);  
        rf_mdl.send_to_sbd.connect(s.recv_from_ref);
    endfunction
endclass