module uart_fsm_sv 
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


wire rx_busy;

wire [7:0] rx_fifo;
wire [7:0] tx_fifo;
assign tx_fifo = rx_fifo;

wire catch_data;

reg tx_start1,tx_start2,tx_start3,tx_start4,tx_start5,tx_start6;

reg [31:0] Count_clk_spi_2x = 0;
reg clk_spi_2x = 0;
always @ ( posedge clk )
if ( Count_clk_spi_2x == ( period >> 1 >> 1 )) begin
    Count_clk_spi_2x <= 13'd0;
    clk_spi_2x = ~clk_spi_2x;
  end
else
  Count_clk_spi_2x <= Count_clk_spi_2x + 1'b1;


always_ff @(posedge clk_spi_2x)
begin
  tx_start1 <= catch_data;
  tx_start2 <= tx_start1;
  tx_start3 <= tx_start2;
  tx_start4 <= tx_start3;
  tx_start5 <= tx_start4;
  tx_start6 <= tx_start5;
end




uart_fsm_tx_sv uart_fsm_tx_sv_inst(
  .clk_spi_2x(clk_spi_2x),
  .reset(reset),
  .send(~rx_busy),
  .start_str(tx_start6),
  .tx_fifo(tx_fifo),
  .done(),
  .spi_data_o(spi_data_o)
);



assign value = rx_fifo;

uart_fsm_rx_sv uart_fsm_rx_sv_inst(
  .clk_spi_2x(clk_spi_2x),
  .reset(reset),
  .fromRX(fromRX),
  .catch_data(catch_data),
  .busy(rx_busy),
  .rx_fifo(rx_fifo)
);

endmodule

module uart_fsm_tx_sv #(spi_array_size = 1 + 8 + 1) (
  input wire clk_spi_2x,
  input wire reset,
  input wire send,
  input wire start_str,
  input wire [7:0] tx_fifo,
  output reg done,
  output reg spi_data_o = '1
);
reg clk_spi = 0;
typedef enum  {start_tx, tx_b0,tx_b1,tx_b2,tx_b3,tx_b4,tx_b5,tx_b6,tx_b7, stop_tx} states_tx;
states_tx cur_state_tx = start_tx;
states_tx next_state_tx = start_tx;
reg [7:0] data = '0;
wire clk_spi_start;
wire is_counting;

always_ff @(posedge clk_spi_2x)
  if (clk_spi_start)
    clk_spi <= ~clk_spi;

assign clk_spi_start = ((next_state_tx == tx_b0) || (is_counting) || (next_state_tx == stop_tx) || (next_state_tx == start_tx)) ;

always_ff @(posedge clk_spi)
  if (~reset) begin
    data <= '0;
    spi_data_o <= 1;
  end
  else if (next_state_tx == tx_b0) begin
    data <= tx_fifo;
    spi_data_o <= 0;
  end
  else if (is_counting) begin
    data <= {data[6:0],1'b1};
    spi_data_o <= data[7];
  end 
  else if (cur_state_tx == stop_tx)
    spi_data_o <= 1;
  else
    spi_data_o <= 1;

always_ff @(posedge clk_spi)
  if (~reset)
    cur_state_tx <= start_tx;
  else
    cur_state_tx <= next_state_tx;

always_comb begin
next_state_tx = cur_state_tx;
is_counting = 0;
case ( cur_state_tx )
  start_tx: 
    if( start_str == 1 ) 
      next_state_tx = tx_b0;

  tx_b0,tx_b1,tx_b2,tx_b3,tx_b4,tx_b5,tx_b6,tx_b7: begin 
    is_counting = 1;
    case (cur_state_tx)
      tx_b0: next_state_tx = tx_b1;
      tx_b1: next_state_tx = tx_b2;
      tx_b2: next_state_tx = tx_b3;
      tx_b3: next_state_tx = tx_b4;
      tx_b4: next_state_tx = tx_b5;
      tx_b5: next_state_tx = tx_b6;
      tx_b6: next_state_tx = tx_b7;
      tx_b7: next_state_tx = stop_tx;
      default: next_state_tx = cur_state_tx;
    endcase
  end

  stop_tx: next_state_tx = start_tx;
endcase
end

endmodule



module uart_fsm_rx_sv #(spi_array_size = 1 + 8 + 1) (
  input wire clk_spi_2x,
  input wire reset,
  input wire fromRX,
  output wire catch_data,
  output reg busy,
  output reg [7:0] rx_fifo = '0
);
//main idea - save all bits in shift reg. 
//catch start at right most bit (equal 0) 
//end stop at left most bit equal 0
//start, byte, stop 

reg clk_spi = 0;
assign catch_data = cur_state == start;
wire is_counting;

typedef enum  {start, b0,b1,b2,b3,b4,b5,b6,b7, stop} states;

states cur_state = start;
states next_state = start;

wire clk_spi_set;

assign busy = ~clk_spi_set;

always_ff @(posedge clk_spi_2x)	
  if (clk_spi_set)
    clk_spi <= ~clk_spi;

assign clk_spi_set = (is_counting || (next_state == b0) || (next_state == stop) || (next_state == start));

assign clk_mux = clk_spi_set ? clk_spi : clk_spi_2x;

always_ff @( posedge clk_mux )
  if (~reset)
    rx_fifo <= 0;
  else if (is_counting)
    rx_fifo <= {rx_fifo[6:0],fromRX};
  

always_ff @(posedge clk_mux)
  if (~reset)
    cur_state <= start;
  else
    cur_state <= next_state; 

always_comb begin
  next_state = cur_state;
  is_counting = 0;
  case ( cur_state )
    start: 
      if( fromRX == 0 ) 
        next_state = b0;

    b0,b1,b2,b3,b4,b5,b6,b7: begin 
      is_counting = 1;
      case (cur_state)
        b0: next_state = b1;
        b1: next_state = b2;
        b2: next_state = b3;
        b3: next_state = b4;
        b4: next_state = b5;
        b5: next_state = b6;
        b6: next_state = b7;
        b7: next_state = stop;
        default: next_state = cur_state;
      endcase
    end

    stop: next_state = start;
  endcase
        
  end
	 
endmodule

