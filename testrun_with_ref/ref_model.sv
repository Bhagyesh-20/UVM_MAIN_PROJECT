class ref_model extends uvm_component;
    `uvm_component_utils(ref_model)
    
    uvm_analysis_imp    #(transaction,ref_model)    rcv_mon;
    uvm_analysis_port   #(transaction)              snd_sbd;       
    
    transaction t;
    virtual mem_ctrl_if mcif;

    uvm_event done_op;
    int       memory_checker[int];

    function new(input string path = "ref_model", uvm_component parent = null);
        super.new(path, parent);
        done_op = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        t = transaction::type_id::create("t"); 
        rcv_mon = new("rcv_mon", this);
        snd_sbd = new("snd_sbd",this);

        if(!uvm_config_db#( virtual mem_ctrl_if)::get(this,"","mcif",mcif))
            `uvm_error("REF_MODEL","Unable to access config db")
    endfunction

   
    virtual function void write(transaction tc);
        t = tc;
        `uvm_info("REF_MODEL",$sformatf("DATA SENT FROM MON CLASS : rst_n = %0b | cmd_n = %0b | RDnWR = %0b | Addr_in = %0h | Data_in_vld = %0b | Data_in = %0h memory:%0p",t.rst_n, t.cmd_n, t.RDnWR, t.Addr_in, t.Data_in_vld, t.Data_in,memory_checker),UVM_NONE)
        
        if(t.cmd_n == 0 && t.RDnWR)begin
            if (memory_checker.exists(t.Addr_in)) begin
                t.expected_RA                = t.Addr_in[15:12];
                t.expected_CA                = t.Addr_in[11:0];
                t.expected_data_out          = memory_checker[t.Addr_in];
                t.expected_cs_n              = 1'b0;
                `uvm_info("REF_MDL",$sformatf("Scorebaord triggered event"),UVM_NONE)
                snd_sbd.write(t);
            end
        end

        else if(t.cmd_n == 0 && !t.RDnWR && t.Data_in_vld)begin
            if(!memory_checker.exists(t.Addr_in))begin
                memory_checker[t.Addr_in] = t.Data_in;
                `uvm_info("REF_MODEL", $sformatf("WRITE: Addr = %0h, Data = %0h", t.Addr_in, t.Data_in), UVM_NONE)

            end
            else begin
                if(memory_checker[t.Addr_in]!=t.Data_in)begin
                    `uvm_info("REF_MODEL", $sformatf("WRITE: Addr = %0h, Data = %0h", t.Addr_in, t.Data_in), UVM_NONE)

                end
                else begin
                    return;
                end
            end
        end

        else if(t.cmd_n == 0 && !t.Data_in_vld)begin
            `uvm_info("REF_MODEL","Data in is not vld no write operations can be performed",UVM_NONE)

        end

        else begin
            `uvm_info("REF_MODEL","cmd_n is 1, no operations can be performed",UVM_NONE)

        end
    endfunction
endclass