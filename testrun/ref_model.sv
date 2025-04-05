`uvm_analysis_imp_decl(_drv)

class ref_model extends uvm_component;
  `uvm_component_utils(ref_model)

  transaction transaction_from_drv;
  uvm_analysis_imp_drv #(transaction, ref_model) rcv_drv;
  uvm_analysis_port #(transaction) predicted_output_ap;

  virtual mem_ctrl_if mcif;

  typedef enum logic [2:0] {
    CMD_NOP     = 3'b000,
    CMD_ACT     = 3'b001,
    CMD_READ    = 3'b010,
    CMD_WRITE   = 3'b011,
    CMD_PRE     = 3'b100,
    CMD_REFRESH = 3'b101
  } cmd_t;

  typedef enum logic [3:0] {
    IDLE, ACT, READ, WRITE, PRE, REFRESH, READ_TO_READ_DELAY, READ_TO_WRITE_DELAY,
    WRITE_TO_READ_DELAY, REFRESH_TO_READ_DELAY, REFRESH_TO_WRITE_DELAY, ACT_TO_RW_DELAY,
    READ_TO_PRE_DELAY, WRITE_TO_PRE_DELAY
  } state_t;

  state_t current_state, next_state;
  logic [3:0] tCK_counter;
  logic [12:0] refresh_counter;
  logic refresh_needed;

  logic [11:0] active_col;
  logic [3:0] active_row;
  logic row_active;

  reg [31:0] mem [0:65535];

  event done_processing;

  function new(string name = "ref_model", uvm_component parent = null);
    super.new(name, parent);
    rcv_drv = new("rcv_drv", this);
    predicted_output_ap = new("predicted_output_ap", this);
    done_processing = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    transaction_from_drv = transaction::type_id::create("transaction_from_drv", this);
    if (!uvm_config_db#(virtual mem_ctrl_if)::get(this, "", "mcif", mcif))
      `uvm_error("REF_MODEL", "Failed to get virtual interface")
  endfunction

  virtual task write_drv(transaction t);
    transaction_from_drv = t;
    `uvm_info("REF_MODEL", $sformatf("Received transaction: %s", t.sprint()), UVM_MEDIUM)
    fork
      process_transaction(transaction_from_drv);
    join_none
  endtask

  task process_transaction(transaction t);
    state_t next_s;
    logic [3:0] next_tCK;
    logic [3:0] current_tCK;
    state_t current_s;
    logic [3:0] next_ar;
    logic [11:0] next_ac;
    logic next_ra;

    current_s = current_state;
    current_tCK = tCK_counter;
    next_s = current_s;
    next_tCK = current_tCK;
    next_ar = active_row;
    next_ac = active_col;
    next_ra = row_active;

    case (current_s)
      IDLE: begin
        if (refresh_needed) begin
          next_s = REFRESH;
          next_tCK = 5;
        end else if (!t.cmd_n) begin
          next_s = ACT;
          next_ar = t.Addr_in[15:12];
          next_ac = t.Addr_in[11:0];
        end
      end
      ACT: begin
        if (is_row_valid(t.Addr_in[15:12])) begin
          if (refresh_needed) begin
            next_s = REFRESH;
            next_tCK = 5;
          end else if (row_active && active_row != t.Addr_in[15:12]) begin
            next_s = PRE;
          end else begin
            next_ra = 1;
            if (is_col_valid(t.Addr_in[11:0])) begin
              next_s = ACT_TO_RW_DELAY;
              next_tCK = 5;
              next_ar = t.Addr_in[15:12];
              next_ac = t.Addr_in[11:0];
            end
          end
        end else begin
          next_s = IDLE;
        end
      end
      ACT_TO_RW_DELAY: begin
        if (current_tCK == 1) begin
          next_s = (t.RDnWR) ? READ : WRITE;
        end else begin
          next_tCK = current_tCK - 1;
        end
      end
      WRITE: begin
        if (refresh_needed) begin
          next_s = REFRESH;
          next_tCK = 5;
        end else if (t.Data_in_vld && !t.cmd_n) begin
          mem[t.Addr_in] = t.Data_in;
          if (t.RDnWR) begin
            next_s = WRITE_TO_READ_DELAY;
            next_tCK = 4;
          end else begin
            // Assuming consecutive writes go back to WRITE state immediately for simplicity
            next_s = WRITE;
          end
        end else if (!t.cmd_n) begin // Another command received
          next_s = (t.RDnWR) ? READ : ACT; // Example transition
          if (!t.RDnWR) next_ar = t.Addr_in[15:12];
        end
      end
      WRITE_TO_READ_DELAY: begin
        if (current_tCK == 1) begin
          next_s = READ;
        end else begin
          next_tCK = current_tCK - 1;
        end
      end
      READ: begin
        if (refresh_needed) begin
          next_s = REFRESH;
          next_tCK = 5;
        end else if (is_col_valid(t.Addr_in[11:0])) begin
          if (row_active && (active_row == t.Addr_in[15:12])) begin
            if (!t.cmd_n && !t.RDnWR) begin
              next_s = READ_TO_WRITE_DELAY;
              next_tCK = 4;
            end else if (!t.cmd_n && t.RDnWR) begin
              next_s = READ_TO_READ_DELAY;
              next_tCK = 2;
            end else if (!t.cmd_n && t.command == CMD_PRE) begin
              next_s = PRE;
            end
          end else if (!row_active && !t.cmd_n) begin
              next_s = ACT;
              next_ar = t.Addr_in[15:12];
              next_ac = t.Addr_in[11:0];
          end
        end
      end
      READ_TO_READ_DELAY: begin
        if (current_tCK == 1) begin
          // No action needed here, the next state will be READ
        end else begin
          next_tCK = current_tCK - 1;
        end
      end
      READ_TO_WRITE_DELAY: begin
        if (current_tCK == 1) begin
          next_s = WRITE;
        end else begin
          next_tCK = current_tCK - 1;
        end
      end
      PRE: begin
        next_ra = 0;
        if (refresh_needed) begin
          next_s = REFRESH;
          next_tCK = 5;
        end else if (!t.cmd_n && t.command == CMD_ACT) begin
          next_s = ACT;
          next_ar = t.Addr_in[15:12];
          next_ac = t.Addr_in[11:0];
        end else if (!t.cmd_n && t.command == CMD_IDLE) begin
          next_s = IDLE;
        end
      end
      REFRESH: begin
        // Simplified refresh: assuming it takes a fixed number of cycles
        if (current_tCK == 1) begin
          refresh_needed = 0;
          refresh_counter = 0;
          next_s = IDLE;
        end else begin
          next_tCK = current_tCK - 1;
        end
      end
      default: next_s = IDLE;
    endcase

    // Apply state and counter updates after considering the current transaction
    if (mcif.rst_n == 0) begin
      current_state <= IDLE;
      active_row <= '0;
      active_col <= '0;
      row_active <= 0;
      tCK_counter <= '0;
      refresh_counter <= '0;
      refresh_needed <= 0;
    end else if (mcif.clk'event and mcif.clk == 1) begin
      current_state <= next_s;
      tCK_counter <= (next_tCK > 0) ? next_tCK : '0;
      active_row <= next_ar;
      active_col <= next_ac;
      row_active <= next_ra;

      if (refresh_counter == 13'd319) begin
        refresh_needed <= 1;
      end else if (current_state != REFRESH) begin
        refresh_counter <= refresh_counter + 1;
      end
    end

    // Predict output after the READ delay
    if (current_s == READ && next_s != READ_TO_READ_DELAY && next_s != READ_TO_WRITE_DELAY) begin
      transaction predicted_txn = transaction::type_id::create("predicted_txn");
      predicted_txn.Data_out = mem[t.Addr_in];
      predicted_txn.data_out_vld = 1'b1;
      predicted_output_ap.write(predicted_txn);
    end else begin
      // For other states, output is not valid
      transaction predicted_txn = transaction::type_id::create("predicted_txn");
      predicted_txn.data_out_vld = 1'b0;
      predicted_output_ap.write(predicted_txn);
    end

    done_processing.trigger();
  endtask

  function logic is_col_valid(input logic [11:0] active_col);
    return (active_col >= 12'h000 && active_col <= 12'hFFF);
  endfunction

  function logic is_row_valid(input logic [3:0] active_row);
    return (active_row >= 4'h0 && active_row <= 4'hF);
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(done_processing);
    end
  endtask

endclass