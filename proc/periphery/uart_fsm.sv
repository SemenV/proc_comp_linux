module uart_fsm 
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
reg clk_spi;

reg [31:0] cnt_spi_2x = 0;
reg clk_spi_2x = 0;
always_ff @ ( posedge clk)
if(( cnt_spi_2x == ( period >> 1 >> 1  ) )) begin
    cnt_spi_2x <= 13'd0;
    clk_spi_2x = ~clk_spi_2x;
  end
else
  cnt_spi_2x <= cnt_spi_2x + 1'b1;

always_ff @(posedge clk_spi_2x)	
  if (rx_busy)
    clk_spi = ~clk_spi;

assign clock_global = rx_busy ? clk_spi : clk_spi_2x;


spi_fsm_rx spi_fsm_rx_inst (
  .clock_global(clock_global),
  .fromRX(fromRX),
  .reset(reset),
  .fifo_rx_rd_en(), //no
  .fifo_rx_empty(), //no
  .fifo_rx_data(value),
  .clk_spi_en_rx(rx_busy)
);


endmodule

module spi_fsm_rx (
  input wire clock_global,
  input wire fromRX,
  input wire reset,
  input wire fifo_rx_rd_en,
  output wire fifo_rx_empty,
  output wire [7:0] fifo_rx_data,
  output wire clk_spi_en_rx
);
reg fifo_rx_empty_reg = 1;
localparam rx_bits_start = 8'b00000001;
localparam rx_bits_stop  = 8'b10000000;
typedef logic [7:0] rx_bits;
rx_bits rx_bit_cur, rx_bit_next;

typedef enum  { rx, count, stop} rx_states;
rx_states rx_current, rx_next;

reg [7:0] fifo_rx_data_reg; 

wire count_st;
assign count_st = rx_current == count;

assign clk_spi_en_rx = ~((rx_current == rx) && (rx_next == rx));

assign fifo_rx_empty = fifo_rx_empty_reg; 

always_ff @(posedge clock_global or negedge reset)
  if (~reset)
    rx_current <= rx;
  else
    rx_current <= rx_next; 

always_comb
  begin
    rx_next = rx_current;

    case (rx_current)
      rx          : if ( fromRX == 0 )              rx_next = count;
      count       : if (rx_bit_cur == rx_bits_stop) rx_next = stop;
      stop        :                                 rx_next = rx;
    endcase
  end

always_ff @(posedge clock_global or negedge reset)
  if (~reset)
    rx_bit_cur <= rx_bits_start;
  else
    rx_bit_cur <= rx_bit_next; 

always_comb
  begin
    rx_bit_next = rx_bit_cur;

    case (rx_bit_cur)
      default: 
        if (count_st) 
          rx_bit_next = {rx_bit_cur[6:0],rx_bit_cur[7]};
        else 
          rx_bit_next = 8'd1;
    endcase
  end
  

  always_ff @(posedge clock_global or negedge reset)
  if (~reset)
    fifo_rx_data_reg <= 0;
  else
  if (count_st)
    fifo_rx_data_reg <= (rx_bit_cur &  {8{fromRX}});

  assign fifo_rx_data = fifo_rx_data_reg;

endmodule 

