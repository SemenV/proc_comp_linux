module uart_sv 
 #(parameter period = 13'd5208) 
(
(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "E1"  *)
input clk,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "F14"  *)
input fromRX,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "F13"  *)
output spi_data_o,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "C3,A2,B3,A3,B4,A4,B5,A5" *)
output  [7:0] value,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "D15" *)
output error,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "J14" *) 
input reset
);
wire [7:0] fifo_rx_data;
wire [7:0] fifo_tx_data;
wire fifo_rx_empty;
wire rx_busy;
wire fifo_rx_rd_en;

wire tx_str;
wire tx_busy;

wire clk_spi_en_tx;
wire clk_spi_en_rx;
wire clock_global;

reg [31:0] cnt_spi_2x = 0;
reg clk_spi_2x = 0;
always_ff @ ( posedge clk)
if(( cnt_spi_2x == ( period >> 1 >> 1  ) )) begin
    cnt_spi_2x <= 13'd0;
    clk_spi_2x = ~clk_spi_2x;
  end
else
  cnt_spi_2x <= cnt_spi_2x + 1'b1;


uart_loopback_fsm uart_loopback_fsm_inst(
  .clk(clk_spi_2x),
  .rst_n(reset),
  .clock_global(clock_global),
  .fifo_rx_data(fifo_rx_data),
  .fifo_rx_empty(fifo_rx_empty),
  .fifo_rx_rd_en(fifo_rx_rd_en),
  .rx_busy(rx_busy),
  .clk_spi_en_rx(clk_spi_en_rx),

  .tx_data(fifo_tx_data),
  .tx_str(tx_str),
  .tx_busy(tx_busy),
  .clk_spi_en_tx(clk_spi_en_tx)
);

uart_rx_sv uart_rx_sv_inst (
  .clk_spi_en_rx(clk_spi_en_rx),
  .fromRX(fromRX),
  .clock_global(clock_global),
  .reset(reset),
  .fifo_rx_rd_en(fifo_rx_rd_en),
  .fifo_rx_empty(fifo_rx_empty),
  .rx_busy(rx_busy),
  .fifo_rx_data(fifo_rx_data)
);

assign value = fifo_rx_data;

uart_tx uart_tx_inst (
  .rst_n(reset),
  .tx_str(tx_str),
  .tx_data(fifo_tx_data),
  .tx_busy(tx_busy),
  .tx_out(spi_data_o),
  .clk_spi_en_tx(clk_spi_en_tx),
  .clock_global(clock_global)
);

endmodule


module uart_rx_sv (
  input wire clock_global,
  input wire fromRX,
  input wire reset,
  input wire fifo_rx_rd_en,
  output reg fifo_rx_empty = 1,
  output wire rx_busy,
  output wire [7:0] fifo_rx_data,
  output wire clk_spi_en_rx
);

wire trans;

reg [31:0] bit_counter = 0;
typedef enum logic [7:0] {start,count,stop} states;
states cur_state = start;
states next_state = start;

wire clk_mux;

assign clk_spi_en_rx = ((next_state == count) || (next_state == stop) || (next_state == start));
assign rx_busy = ~((cur_state == next_state) && (next_state == start));
assign trans = ((cur_state == count) && (next_state == stop));

always_ff @(posedge clock_global or negedge reset)
  if (~reset)
  fifo_rx_empty <= 1;
  else
  if (trans)
    fifo_rx_empty <= 0;
  else if (fifo_rx_rd_en)
    fifo_rx_empty <= 1;

always_ff @(posedge clock_global or negedge reset)
  if (~reset) begin
    bit_counter <= 0;
    fifo_rx_data <= 0;
  end
  else if (cur_state == count)
    begin
      bit_counter <= bit_counter + 1;
      fifo_rx_data <= {fromRX,fifo_rx_data[7:1]};
    end
  else
    bit_counter <= 0;

always_ff @(posedge clock_global or negedge reset)
  if (~reset)
    cur_state <= start;
  else
    cur_state <= next_state; 

always_comb
  begin
    next_state = cur_state;

    case (cur_state)
      start       : if ( fromRX == 0 )    next_state = count;
      count       : if (bit_counter == 7) next_state = stop;
      stop        :                       next_state = start;
    endcase
  end
endmodule 


module uart_loopback_fsm #(
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic [DATA_WIDTH-1:0] fifo_rx_data,
    input  logic                  fifo_rx_empty,
    output logic                  fifo_rx_rd_en,
    input  logic                  rx_busy,

    output logic [DATA_WIDTH-1:0] tx_data,
    output logic                  tx_str,
    input  logic                  tx_busy,
    output logic stt = 0,

    input wire clk_spi_en_rx,
    input wire clk_spi_en_tx,
    output wire clock_global
);


  typedef enum logic [2:0] {
    ST_IDLE_RX,
    ST_READ_FIFO,
    ST_LATCH_DATA,
    ST_SEND_TX,
    ST_WAIT_TX_START,
    ST_WAIT_TX_DONE
  } state_t;
    

  state_t state, next_state;
  logic [DATA_WIDTH-1:0] data_reg;
  reg clk_spi = 0;
  wire clk_mux_en;

  always_ff @(posedge clk)	
    if (clk_mux_en)
      clk_spi = ~clk_spi;

  assign clk_mux_en = (clk_spi_en_rx ) || ( clk_spi_en_tx && ( ( state == ST_WAIT_TX_DONE ) || (state == ST_WAIT_TX_START ) ) );
  assign clock_global = clk_mux_en ? clk_spi : clk;

  always_ff @(posedge clock_global or negedge rst_n) begin
    if (!rst_n)
      state <= ST_IDLE_RX;
    else
      state <= next_state;
  end


  always_comb begin
    next_state = state;
    case (state)
      ST_IDLE_RX: begin
        if ((~rx_busy) && (~fifo_rx_empty))
          next_state = ST_READ_FIFO;
      end

      ST_READ_FIFO: begin
        next_state = ST_LATCH_DATA;
      end

      ST_LATCH_DATA: begin
        next_state = ST_SEND_TX;
      end

      ST_SEND_TX: begin
        if (~tx_busy)
          next_state = ST_WAIT_TX_START;
      end

      ST_WAIT_TX_START: begin
        if (tx_busy)
          next_state = ST_WAIT_TX_DONE;
      end

      ST_WAIT_TX_DONE: begin
        if (~tx_busy)
          next_state = ST_IDLE_RX;
      end

      default: next_state = state;
    endcase
  end

  always_ff @(posedge clock_global or negedge rst_n) begin
    if (!rst_n) begin
      fifo_rx_rd_en <= 1'b0;
      tx_str        <= 1'b0;
      tx_data       <= '0;
      data_reg      <= '0;
    end else begin
      fifo_rx_rd_en <= 1'b0;
      tx_str        <= 1'b0;

      case (state)
        ST_READ_FIFO: begin
          fifo_rx_rd_en <= 1'b1;
        end

        ST_LATCH_DATA: begin
          data_reg <= fifo_rx_data;
        end

        ST_SEND_TX: begin
          if (!tx_busy) begin
            tx_data <= data_reg;
            tx_str  <= 1'b1;
          end
        end
      endcase
    end
  end

endmodule


module uart_tx (
    input  wire       rst_n,
    input  wire       clock_global,
    input  wire       tx_str,
    input  wire [7:0] tx_data,
    output wire       tx_busy,
    output wire       tx_out,
    output wire       clk_spi_en_tx
);

  typedef enum logic [7:0] {STATE_START,STATE_WRITE,STATE_STOP} states_tx;
  states_tx cur_state_tx = STATE_START;
  states_tx next_state_tx = STATE_START;

  reg load_en;
  reg shift_en;

  reg [7:0] tx_buf;
  reg [2:0] bit_cnt;

  assign clk_spi_en_tx = ((cur_state_tx == STATE_START && next_state_tx == STATE_WRITE) || (cur_state_tx == STATE_WRITE) || (cur_state_tx == STATE_STOP));

  always_ff @(posedge clock_global or negedge rst_n)
    if (~rst_n)
      tx_out <= 1'b1;
  else 
    if ((cur_state_tx == STATE_START) && (next_state_tx == STATE_WRITE))
      tx_out <= 1'b0;
    else if (cur_state_tx == STATE_STOP) 
      tx_out <= 1'b1;
    else if (cur_state_tx == STATE_WRITE)
      tx_out <= tx_buf[0];
    else
      tx_out <= 1;
  
  always @(posedge clock_global or negedge rst_n) begin
      if (!rst_n)
          cur_state_tx <= STATE_START;
      else
          cur_state_tx <= next_state_tx;
  end

  always_comb begin
    next_state_tx = cur_state_tx;
    load_en    = 1'b0;
    shift_en   = 1'b0;
    tx_busy    = 1'b0;

    case (cur_state_tx)
      STATE_START: begin
        if (tx_str) begin
          load_en    = 1'b1;
          tx_busy    = 1'b1;
          next_state_tx = STATE_WRITE;
        end else begin
          tx_busy    = 1'b0;
          next_state_tx = STATE_START;
        end
      end

      STATE_WRITE: begin
        shift_en = 1'b1;
        tx_busy  = 1'b1;

        if (bit_cnt == 3'd7)
          next_state_tx = STATE_STOP;
        else
          next_state_tx = STATE_WRITE;
      end

      STATE_STOP: begin
        tx_busy    = 1'b1;
        next_state_tx = STATE_START;
      end

      default: begin
        next_state_tx = cur_state_tx;
      end
    endcase
  end

  always @(posedge clock_global or negedge rst_n) begin
    if (!rst_n) begin
      tx_buf  <= 8'hFF;
      bit_cnt <= 3'd0;
    end else begin
      if (load_en) begin
        tx_buf  <= {tx_data};
        bit_cnt <= 3'd0;
      end else if (shift_en) begin
        tx_buf  <= {1'b1,tx_buf[7:1]};
        bit_cnt <= bit_cnt + 3'd1;
      end
    end
  end

endmodule