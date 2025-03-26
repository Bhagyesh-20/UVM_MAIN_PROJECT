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

typedef enum logic [2:0] {
    IDLE, ACT, READ, WRITE, PRE, REFRESH
} state_t;

state_t state, next_state;

logic [3:0] tCK_counter;
logic [12:0] refresh_counter; 
logic  refresh_needed;

logic [11:0] active_col;
logic [3:0] active_row;
logic       row_active;

logic [31:0] read_data_buffer;
logic [1:0]  read_delay_counter;

logic [3:0]  next_active_row;
logic [11:0] next_active_col;
logic        next_row_active;
logic [3:0]  next_tCK_counter;
logic [31:0] next_read_data_buffer;
logic [1:0]  next_read_delay_counter;
logic [2:0] command_buffer;
logic [31:0] Data_out_buffer;

reg [31:0] mem [0:65535];

assign RA = active_row;
assign CA = active_col;
assign cs_n = (state == IDLE);
assign DQ   = (state == WRITE) ? Data_in : 32'bz; 
assign command = command_buffer;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state               <= IDLE;
        active_row          <= 4'b0000;
        active_col          <= 4'b0000;
        row_active          <= 1'b0;
        // tCK_counter         <= 4'b0000;
        read_data_buffer    <= 32'b0;
        read_delay_counter  <= 2'b0;
        data_out_vld        <= 1'b0;
        Data_out     <= 32'b0;
    end 
    else begin
        state <= next_state;
        active_row <= next_active_row;
        active_col <= next_active_col;
        row_active <= next_row_active;
        // tCK_counter <= next_tCK_counter;
        read_data_buffer <= next_read_data_buffer;
        read_delay_counter <= next_read_delay_counter;
	    Data_out <= next_read_data_buffer;
        data_out_vld <= 1'b1;
    end
end

always_comb begin
    next_state = state;
    command_buffer  = CMD_NOP;
    next_active_row = active_row;
    next_active_col = active_col;
    next_row_active = row_active;
    next_tCK_counter = tCK_counter;
    next_read_data_buffer = read_data_buffer;
    next_read_delay_counter = read_delay_counter;

    case(state)
        IDLE : begin
            if(!cmd_n)
                next_state = ACT;
            else
                next_state = PRE;
        end

        ACT : begin
            command_buffer = CMD_ACT;
            next_active_row = Addr_in[15:12];
            next_active_col = Addr_in[11:0];

            if(refresh_needed)begin
                next_state = REFRESH;
            end
            
            else if (row_active && (active_row != next_active_row))begin
                next_state = PRE;
            end
            
            else if(!cmd_n) begin
                next_row_active = 1;
                next_state = (RDnWR) ? READ : WRITE;
                next_tCK_counter = 5;
            end

            else begin
                next_state = ACT;
            end
        end

        WRITE : begin
            command_buffer = CMD_WRITE;
                mem[Addr_in] <= Data_in;
                next_tCK_counter = 4; 
                next_state = PRE;
        end

        READ : begin
            command_buffer = CMD_READ;
            next_tCK_counter = 2;
            next_read_data_buffer = mem[Addr_in];
            next_state = PRE;
        end

        PRE : begin
            command_buffer = CMD_PRE;
            next_row_active = 0;
            next_tCK_counter = 4; 
            next_state = ACT;
        end

        REFRESH: begin
            command_buffer = CMD_REFRESH;
            next_tCK_counter = 5; 
            // refresh_needed = 0;    // Reset refresh flag
            next_state = IDLE;
        end

    endcase
end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= 13'd0;
            refresh_needed  <= 1'b0;  
        end 
        else if (refresh_counter == 13'd320) begin
            refresh_needed <= 1'b1;   
            refresh_counter <= 13'd0;
        end 
         else if (state == REFRESH) begin
             refresh_needed <= 1'b0;   
        end
        else begin
            refresh_counter <= refresh_counter + 1;
        end
    end



    always @(posedge clk or negedge rst_n)begin
        
        if(!rst_n)begin
             tCK_counter <= 4'b0000;
        end

        else if (tCK_counter > 0) begin
            tCK_counter <= next_tCK_counter;
            tCK_counter <= tCK_counter - 1; 
        end

    end


endmodule
