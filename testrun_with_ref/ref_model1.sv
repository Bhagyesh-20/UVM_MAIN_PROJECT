class ref_model extends uvm_component;
    `uvm_component_utils(ref_model)
    
    uvm_analysis_port #(transaction) send_to_sbd;
    uvm_blocking_put_imp #(transaction,ref_model) recv_to_ref_drv;

    transaction tc;
    virtual mem_ctrl_if mcif;

    transaction tmp_tc[$];

    uvm_event done_op;

    function new(input string path = "ref_model", uvm_component parent = null);
        super.new(path, parent);
        send_to_sbd = new("send_to_sbd", this); /// for sending to scoreboard
        done_op = new("done_op");
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tc = transaction::type_id::create("tc"); 
        recv_to_ref_drv = new("recv_to_ref_drv", this);
        if(!uvm_config_db#( virtual mem_ctrl_if)::get(this,"","mcif",mcif))
            `uvm_error("RF_MDL","Unable to access config db")
    endfunction

   
    virtual task put(transaction t);
        tc = t;
        `uvm_info("REF_MODEL","Received from driver",UVM_LOW)
      
        model (mcif.clk,mcif.rst_n,tc.cmd_n,tc.RDnWR,tc.Addr_in,tc.Data_in_vld,tc.Data_in,tc.Data_out,tc.data_out_vld,tc.command,tc.RA,tc.CA,tc.cs_n);
    endtask

    function logic is_col_valid(input logic [11:0] active_col);
        return (active_col >= 12'h000 && active_col <= 12'hFFF);
    endfunction
    
    function logic is_row_valid(input logic [3:0] active_row);
        return (active_row >= 4'h0 && active_row <= 4'hF);
    endfunction

    logic clk;
    logic rst_n;
    logic cmd_n;
    logic RDnWR;
    logic [15:0] Addr_in;
    logic Data_in_vld;
    logic [31:0] Data_in;
    logic [31:0] Data_out;
    logic data_out_vld;
    logic [2:0] command;
    logic [3:0] RA;
    logic [11:0] CA;
    logic cs_n;


    typedef enum logic [3:0] {
        IDLE, ACT, READ, WRITE, PRE, REFRESH, READ_TO_READ_DELAY, READ_TO_WRITE_DELAY,
        WRITE_TO_READ_DELAY, REFRESH_TO_READ_DELAY, REFRESH_TO_WRITE_DELAY,ACT_TO_RW_DELAY,
        READ_TO_PRE_DELAY, WRITE_TO_PRE_DELAY
    } state_t;

    typedef enum logic [2:0] {
        CMD_NOP      = 3'b000,
        CMD_ACT      = 3'b001, 
        CMD_READ     = 3'b010, 
        CMD_WRITE    = 3'b011, 
        CMD_PRE      = 3'b100,
        CMD_REFRESH  = 3'b101  
    } cmd_t;

    state_t state, next_state;

    logic [3:0]     tCK_counter;
    logic [12:0]    refresh_counter; 
    logic           refresh_needed;

    logic [11:0]    active_col;
    logic [3:0]     active_row;

    logic [11:0]    prev_col;
    logic [3:0]     prev_row;
    logic [31:0]    prev_data_in;

    logic           row_active;

    logic [3:0]     next_active_row;
    logic [11:0]    next_active_col;

    logic           next_row_active;
    logic [3:0]     next_tCK_counter;


    logic [2:0]     command_buffer;

    logic [31:0]      mem [0:65535];
    logic [31:0]      mem_buffer[0:65535];

    logic [31:0]     Data_out_buffer;


    task model (input clk,input rst_n,input cmd_n,input RDnWR,input Addr_in,input Data_in_vld,input Data_in,output Data_out,output data_out_vld,output command,output RA,output CA,output cs_n);
        fork
            command  = command_buffer;
            cs_n     = !(is_col_valid(active_col)&&is_row_valid(active_row));
            begin
            @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    state               = IDLE;
                    active_row          = 4'b0000;
                    active_col          = 1'b0;
                    Data_out            = 32'b0;
                end 
                
                else begin
                    state               = next_state; 
                    active_row          = next_active_row;
                    active_col          = next_active_col;
                    row_active          = next_row_active;
        
                    if(data_out_vld)begin
                        Data_out        = Data_out_buffer; 
                        done_op.trigger();
                    end
        
                    if (state == WRITE && Data_in_vld) begin
                        prev_row        = active_row;
                        prev_col        = active_col;
                        prev_data_in    = Data_in; 
                    end
                end
            end
        end
        begin
                @(state or row_active or active_row or active_col or refresh_needed or cmd_n or RDnWR or Data_in_vld or prev_row or prev_col or prev_data_in or Addr_in or Data_in or tCK_counter)begin
                    next_state              = state;
                    command_buffer          = CMD_NOP;
                    next_active_row         = active_row;
                    next_active_col         = active_col;
                    next_row_active         = row_active;
                    next_tCK_counter        = tCK_counter;
                    mem                     = mem_buffer;
                    Data_out_buffer         = mem[Addr_in];
                    
                    case(state)
                        
                        IDLE: begin
                            command_buffer  =   CMD_NOP;
                            data_out_vld    =   0;
                            if(refresh_needed)begin
                                next_state  = REFRESH;
                            end
                            else if(!cmd_n)begin
                                next_state  = ACT;
                            end
                            else begin
                                next_state  = IDLE;
                            end
                        end
        
                        ACT : begin
                            command_buffer  = CMD_ACT;
                            next_active_row = tc.Addr_in[15:12];
                            next_active_col = tc.Addr_in[11:0];
                            data_out_vld    = 0;
        
                            if(is_row_valid(next_active_row))begin
                                if(refresh_needed)begin
                                    next_state = REFRESH;
                                end
                                else if(row_active && active_row!=next_active_row)begin
                                    next_state = PRE;
                                end
                                else begin
                                    next_row_active = 1;
                                    if(is_col_valid(next_active_col))begin
                                        next_state = ACT_TO_RW_DELAY;
                                        next_tCK_counter = 5;
                                    end
                                    else begin
                                        next_state = ACT;
                                    end
                                end
                            end
                        end
        
                        WRITE : begin
                            command_buffer   = CMD_WRITE;
                            data_out_vld     = 0;
                            
                            if (refresh_needed) begin
                                next_state = REFRESH;
                            end
                            else if (Data_in_vld) begin
                                mem_buffer[tc.Addr_in] = Data_in;
                                done_op.trigger();
                                if (!cmd_n) begin
                                    if (RDnWR) begin  
                                        if (active_row == next_active_row) begin
                                            next_tCK_counter = 4;
                                            next_state       = WRITE_TO_READ_DELAY;
                                        end
                                        else begin
                                            next_tCK_counter = 4;
                                            next_state       = WRITE_TO_PRE_DELAY;
                                        end
                                    end
                                    else begin
                                        if(prev_col!= next_active_row && prev_row!=next_active_row && prev_data_in!= Data_in)begin
                                            next_state = WRITE; 
                                        end
                                        else begin
                                            next_state = ACT;
                                        end
                                    end
                                end
                                else begin
                                    next_state = IDLE;
                                end
                            end
                            else begin
                                next_state = ACT;
                            end
                        end
                        
                        READ : begin
                                command_buffer          = CMD_READ;
                                next_tCK_counter        = 2;
        
                            if(refresh_needed)begin
                                next_state = REFRESH;
                            end
                            else if(is_col_valid(tc.Addr_in[11:0]))begin
                                
                                if (row_active && (active_row == tc.Addr_in[15:12])) begin
                                    if (!cmd_n && !RDnWR) begin
                                        next_state = READ_TO_WRITE_DELAY; 
                                        next_tCK_counter = 4;
                                    end 
                                    else if (!cmd_n && RDnWR) begin 
                                        next_state = READ_TO_READ_DELAY;
                                        next_tCK_counter = 2;
                                    end
                                    else begin
                                        next_state = IDLE;  
                                    end
                                end 
                                else begin
                                    next_state = READ_TO_PRE_DELAY;  
                                    next_tCK_counter = 4;
                                end
                            end
                            else begin
                                next_state = ACT;
                            end
                        end
        
                        PRE : begin
                            data_out_vld        = 0;
                            command_buffer      = CMD_PRE;
                            next_row_active     = 0;
                            
                            if(is_row_valid(next_active_row))begin
                                if(refresh_needed)begin
                                    next_state = REFRESH;
                                end
        
                                else if (next_active_row != active_row) begin    
                                    next_state = ACT;
                                end 
                                else begin
                                    next_state = IDLE;
                                end
                            end
                            else begin
                                next_state = IDLE;
                            end
                        end
        
                        REFRESH : begin
                            data_out_vld            = 0;
                            if(is_row_valid(next_active_row))begin
                                command_buffer      = CMD_REFRESH;
                                 for(int i= 0;i<4096;i++)begin
                                     mem[{active_row, i[11:0]}] = mem_buffer[{active_row, i[11:0]}];
                                 end
                                next_tCK_counter    = 5; 
                                next_state          = IDLE;
                              
                            end
        
                            else begin
                                next_state = REFRESH;
                            end        
                        end
                        
                        READ_TO_WRITE_DELAY : begin
                            data_out_vld    = 0;
                            if(tCK_counter == 0)begin
                                next_state          = WRITE;
                                next_tCK_counter    = 4;
                            end
                            else begin
                                next_state = READ_TO_WRITE_DELAY;
                            end
                        end
                
                        READ_TO_READ_DELAY : begin
        
                            if (tCK_counter == 0) begin
                                RA = tc.Addr_in[15:12];
                                CA = tc.Addr_in[11:0];                                
                                
                                data_out_vld = 1'b1;
                                next_state   = READ; 
                            
                            end
                            
                            else if(tCK_counter == 1)begin
                                data_out_vld = 1'b0;
                            end 
        
                            else begin
                                next_state = READ_TO_READ_DELAY;
                            end
                        end
                        
                        WRITE_TO_READ_DELAY : begin
                            data_out_vld    = 0;
                            if (tCK_counter == 0) begin
                                next_state = READ; 
                            end 
                            else begin
                                next_state = WRITE_TO_READ_DELAY;
                            end
                        end
                
                        REFRESH_TO_READ_DELAY : begin
                            data_out_vld =   0;
                            if (tCK_counter == 0) begin
                                next_state = READ; 
                            end else begin
                                next_state = REFRESH_TO_READ_DELAY;
                            end
                        end
                
                        REFRESH_TO_WRITE_DELAY : begin
                            data_out_vld    = 0;
                            if (tCK_counter == 0) begin
                                next_state = WRITE; 
                            end else begin
                                next_state = REFRESH_TO_WRITE_DELAY;
                            end
                        end
                
                
                        ACT_TO_RW_DELAY : begin
                            data_out_vld    = 0;
                            if (tCK_counter == 0) begin
                                next_state = (RDnWR) ? READ : WRITE; // Transition to READ/WRITE after delay
                            end else begin
                                next_state = ACT_TO_RW_DELAY; 
                            end
                        end
                
                
                        WRITE_TO_PRE_DELAY : begin
                            data_out_vld    =   0;
                            if(tCK_counter == 0) begin
                                next_state = PRE;
                            end
                            else begin
                                next_state = WRITE_TO_PRE_DELAY;
                            end
                        end
                
                        READ_TO_PRE_DELAY : begin
                            data_out_vld    =   0;
                            if(tCK_counter == 0) begin
                                next_state = PRE;
                            end
                            else begin
                                next_state = READ_TO_PRE_DELAY;
                            end
                        end            
                    endcase
                end
            end
            begin
                
            
                @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        refresh_counter <= 13'd0;
                        refresh_needed  <= 1'b0;  
                    end 
                    else if (refresh_counter >= 13'd300  && refresh_counter <= 13'd340) begin
                        refresh_needed  <= 1'b1;   
                        refresh_counter <= 13'd0;
                    end 
                    else if (state == REFRESH) begin
                        refresh_needed <= 1'b0;   
                    end
                    else begin
                        refresh_counter <= refresh_counter + 1;
                    end
                end

                @(posedge clk or negedge rst_n)begin
            
                    if(!rst_n)begin
                        tCK_counter    <= 4'b0000;
                    end
        
                    else if (tCK_counter > 0) begin
                        tCK_counter     <= tCK_counter-1; 
                    end
        
                    else begin
                        tCK_counter     <= next_tCK_counter;
                    end
                end
            end
        join
    endtask

    task run_phase(uvm_phase phase);
        //phase.raise_objection(this);  
            done_op.wait_trigger();
            `uvm_info("RF_MDL",
            $sformatf("DATA SENT TO SBD rst_n:%0b cmd_n:%0b RDnWR:%0b Addr_in:%0h Data_in_vld:%0b Data_in:%0h tc.command:%0d Data_out:%0h",
                tc.rst_n, tc.cmd_n, tc.RDnWR, tc.Addr_in, tc.Data_in_vld, tc.Data_in, tc.command, tc.Data_out),
            UVM_NONE)
                    
          //  send_to_sbd.write(tc);
        //phase.drop_objection(this);
    endtask
endclass