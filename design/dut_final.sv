module mem_ctrl (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cmd_n,
    input  logic        RDnWR,      
    input  logic [15:0] Addr_in,      
    input  logic        Data_in_vld,  
    input  logic [31:0] Data_in,    
    output logic [31:0] Data_out,     
    output logic        data_out_vld, 
    output logic [2:0]  command,     
    output logic [3:0]  RA,           
    output logic [11:0] CA,           
    inout  logic [31:0] DQ,           
    output logic        cs_n          
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

logic [3:0]     tCK_counter;
logic [12:0]    refresh_counter; 
logic           refresh_needed;

logic [11:0]    active_col;
logic [3:0]     active_row;
logic           row_active;

logic [31:0]    read_data_buffer;
logic [1:0]     read_delay_counter;

logic [3:0]     next_active_row;
logic [11:0]    next_active_col;
logic           next_row_active;
logic [3:0]     next_tCK_counter;
logic [31:0]    next_read_data_buffer;
logic [1:0]     next_read_delay_counter;
logic [2:0]     command_buffer;
logic [31:0]    Data_out_buffer;

reg [31:0]      mem [0:65535];
reg [31:0]      mem_buffer[0:65535];
// assign RA =     active_row;
// assign CA =     active_col;
assign cs_n =   !(is_col_valid(active_col)&&is_row_valid(active_row));
assign DQ   =   (state == WRITE) ? Data_in : 32'bz;
assign DQ   =   (state == READ) ? mem[Addr_in] : 32'bz;
assign command = command_buffer;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state               <= IDLE;
        active_row          <= 4'b0000;
        active_col          <= 4'b0000;
        row_active          <= 1'b0;
        read_data_buffer    <= 32'b0;
        read_delay_counter  <= 2'b0;
        data_out_vld        <= 1'b0;
        Data_out            <= 32'b0;
    end

    else begin
        state               <= next_state;
        mem                 <= mem_buffer;
        active_row          <= next_active_row;
        active_col          <= next_active_col;
        row_active          <= next_row_active;
        read_data_buffer    <= next_read_data_buffer;
        read_delay_counter  <= next_read_delay_counter;
	    Data_out            <= DQ;
        data_out_vld        <= 1'b1;
    end
end

always_comb begin
    next_state              = state;
    command_buffer          = CMD_NOP;
    next_active_row         = active_row;
    next_active_col         = active_col;
    next_row_active         = row_active;
    next_tCK_counter        = tCK_counter;
    next_read_data_buffer   = read_data_buffer;
    next_read_delay_counter = read_delay_counter;

    case(state)
        IDLE : begin
            if(!cmd_n)
                next_state = ACT;
            else
                next_state = PRE;
        end

        ACT : begin
            command_buffer  =   CMD_ACT;
            next_active_row =   Addr_in[15:12];  // Extract row address
            next_active_col =   Addr_in[11:0];   // Extract column address
        
            if (is_row_valid(next_active_row)) begin
                if (refresh_needed) begin
                    next_state = REFRESH;
                end 
                else if (row_active && (active_row != next_active_row)) begin
                    next_state = PRE;
                end 
                else begin
                    next_row_active     = 1;
                    next_state          = ACT_TO_RW_DELAY; // New delay state before READ/WRITE
                    next_tCK_counter    = 5; // Set delay counter
                end
            end
        end
        
        

        WRITE : begin
                command_buffer      = CMD_WRITE;
                if (Data_in_vld) begin
                    mem_buffer[Addr_in] <= Data_in;
                    next_tCK_counter = 4; 
                    next_state = WRITE_TO_PRE_DELAY;
                end else begin
                    next_state = WRITE; 
                end
            end

        READ : begin
            command_buffer          = CMD_READ; //2
            next_tCK_counter        = 2; // READ to READ delay
            next_read_data_buffer   = mem_buffer[Addr_in];
            {RA,CA}                 = Addr_in;
            if (is_col_valid(Addr_in[11:0])) begin
                if (row_active && (active_row == Addr_in[15:12])) begin
                    if (!cmd_n && !RDnWR) begin
                        next_state = READ_TO_WRITE_DELAY; 
                        next_tCK_counter = 4;
                    end 
                    else begin
                        next_state = READ_TO_READ_DELAY; 
                        next_tCK_counter = 2;
                    end
                end else begin
                    next_state = READ_TO_PRE_DELAY;  
                   	next_tCK_counter = 4;

                end
            end
          
        end
        
        

        PRE : begin
            command_buffer      = CMD_PRE;
            next_row_active     = 0;
            
            
                if (next_active_row != active_row) begin
                    next_state = ACT;
                end 
                else if(refresh_needed)begin
                    next_state = REFRESH;
                end
                else begin
                    next_state = IDLE;
                end

        end
        

        REFRESH: begin
            command_buffer      = CMD_REFRESH;
            next_tCK_counter    = 5; 
            next_state          = ACT;
        end

        READ_TO_WRITE_DELAY: begin
            if(tCK_counter == 0)begin
                next_state          = WRITE;
                next_tCK_counter    = 4;
            end
        end

        READ_TO_READ_DELAY : begin
            if (tCK_counter == 0) begin
                next_state = READ; 
            end else begin
                next_state = READ_TO_READ_DELAY;
            end
        end
        
        WRITE_TO_READ_DELAY : begin
            if (tCK_counter == 0) begin
                next_state = READ; 
            end else begin
                next_state = WRITE_TO_READ_DELAY;
            end
        end

        REFRESH_TO_READ_DELAY : begin
            if (tCK_counter == 0) begin
                next_state = READ; 
            end else begin
                next_state = REFRESH_TO_READ_DELAY;
            end
        end

        REFRESH_TO_WRITE_DELAY : begin
            if (tCK_counter == 0) begin
                next_state = WRITE; 
            end else begin
                next_state = REFRESH_TO_WRITE_DELAY;
            end
        end


        ACT_TO_RW_DELAY: begin
            if (tCK_counter == 0) begin
                next_state = (RDnWR) ? READ : WRITE; // Transition to READ/WRITE after delay
            end else begin
                next_state = ACT_TO_RW_DELAY; // Wait until counter reaches 0
            end
        end


        WRITE_TO_PRE_DELAY: begin
            if(tCK_counter == 0) begin
                next_state = PRE;
            end
            else begin
                next_state = WRITE_TO_PRE_DELAY;
            end
        end

        READ_TO_PRE_DELAY: begin
            if(tCK_counter == 0) begin
                next_state = PRE;
            end
            else begin
                next_state = READ_TO_PRE_DELAY;
            end
        end
        
    endcase
end

    //For refresh
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= 13'd0;
            refresh_needed  <= 1'b0;  
        end 
        else if (refresh_counter >= 13'd320) begin
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


    //For command Delays 
    always @(posedge clk or negedge rst_n)begin
        
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


    function logic is_col_valid(input logic [11:0] active_col);
        return (active_col >= 12'h000 && active_col <= 12'hFFF);
    endfunction
    
    function logic is_row_valid(input logic [3:0] active_row);
        return (active_row >= 4'h0 && active_row <= 4'hF);
    endfunction



endmodule