class env extends uvm_env;
    `uvm_component_utils(env)

    agent a;
    scoreboard s;
   // ref_model rf_mdl;

    function new(input string path = "env",uvm_component parent = null);
        super.new(path,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a       = agent::type_id::create("a",this);
        s       = scoreboard::type_id::create("s",this);
     //   rf_mdl  = ref_model::type_id::create("rf_mdl", this);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
      //  a.d.send_to_ref_drv.connect(rf_mdl.recv_to_ref_drv);  
        a.m.send.connect(s.recv);
    endfunction

endclass