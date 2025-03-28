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

    function void write(transaction t);
        
    endfunction

endclassp