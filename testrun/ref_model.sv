`uvm_analysis_imp_decl(_drv)


class ref_model extends uvm_component;
    `uvm_component_utils(ref_model)
    uvm_analysis_port #(transaction) send;
    transaction transaction_from_drv;

    uvm_event       read_done;
    uvm_event       write_done;

    virtual mem_ctrl_if mcif;

    uvm_analysis_imp_drv #(transaction,ref_model) recv_to_ref_drv;
   
    
    function new(string name = "ref_model", uvm_component parent = null);
        super.new(name, parent);
        read_done = new();
        write_done = new();
        recv_to_ref_drv = new("recv_to_ref_drv", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif))
            `uvm_error("REF_MODEL", "Failed to get virtual interface")
    endfunction

    virtual task main_phase(uvm_phase phase);
        `uvm_info("REF_MODEL", "Inside main_phase, waiting for events...", UVM_NONE)
        fork : fork_1
            begin
                write_done.wait_trigger();
                `uvm_info("REF_MODEL", "Write done event received from Driver", UVM_NONE)

                disable fork_1;
            end
            begin
                read_done.wait_trigger();
                `uvm_info("REF_MODEL", "Read done event received from Driver", UVM_NONE)

                disable fork_1;
            end
        join: fork_1
        `uvm_info("REF_MODEL", "Done event received from Driver", UVM_NONE)
        // send.write(transaction_from_drv);
    endtask

        

    virtual task dut(
        input  logic        clk,
        input  logic        rst_n,
        input  logic        cmd_n,
        input  logic        RDnWR,      
        input  logic [15:0] Addr_in,      
        input  logic        Data_in_vld,  
        input  logic [31:0] Data_in,    
        output logic [31:0] Data_out,     
        output logic        data_out_vld, 
        output  logic [2:0]  command,     
        output  logic [3:0]  RA,           
        output  logic [11:0] CA,           
        output  logic        cs_n
        //inout  logic [31:0] DQ,           
        );

        typedef enum logic [2:0] {
            CMD_NOP      = 3'b000,
            CMD_ACT      = 3'b001, 
            CMD_READ     = 3'b010, 
            CMD_WRITE    = 3'b011, 
            CMD_PRE      = 3'b100,
            CMD_REFRESH  = 3'b101  
        } cmd_t;

        typedef enum logic [3:0] {
            IDLE, ACT, READ, WRITE, PRE, REFRESH, READ_TO_READ_DELAY, READ_TO_WRITE_DELAY,
            WRITE_TO_READ_DELAY, REFRESH_TO_READ_DELAY, REFRESH_TO_WRITE_DELAY,ACT_TO_RW_DELAY,
            READ_TO_PRE_DELAY, WRITE_TO_PRE_DELAY
        } state_t;
    
        state_t state, next_state;
        logic [31:0]    DQ;
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
    
        reg [31:0]      mem [0:65535];
        reg [31:0]      mem_buffer[0:65535];

        
        if(mcif.rst_n == 1'b0)begin
            reset_dut();
        end
        
        else begin
            @(posedge mcif.clk)begin
                state               = next_state;
                active_row          = next_active_row;
                active_col          = next_active_col;
                row_active          = next_row_active;
                
                if(data_out_vld)begin
                    Data_out        = Data_out_buffer; //when read to read delay is there data_out_buffer will store the data like DQ
                    
                    read_done.trigger();
                end

                if (state == WRITE && Data_in_vld) begin
                    prev_row        = active_row;
                    prev_col        = active_col;
                    prev_data_in    = Data_in; 
                end
            end
        end

    endtask

    function logic is_col_valid(input logic [11:0] active_col);
        return (active_col >= 12'h000 && active_col <= 12'hFFF);
    endfunction
    
    function logic is_row_valid(input logic [3:0] active_row);
        return (active_row >= 4'h0 && active_row <= 4'hF);
    endfunction


    


    


    virtual task write_drv(transaction transaction_from_drv);
        `uvm_info("REF_MODEL",$sformatf("TRANSACTION received in reference_model from driver:"),UVM_MEDIUM)
        fork
        dut(mcif.clk,mcif.rst_n,transaction_from_drv.cmd_n,transaction_from_drv.RDnWR,transaction_from_drv.Addr_in,transaction_from_drv.Data_in_vld,transaction_from_drv.Data_in,transaction_from_drv.Data_out,transaction_from_drv.data_out_vld,transaction_from_drv.command,transaction_from_drv.RA,transaction_from_drv.CA,transaction_from_drv.cs_n);
        
        join_none
        
    endtask

   


   
   
    
endclass