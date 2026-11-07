module uart_fsm_sv 
 #(parameter period = 13'd5208) 
(
(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "E1"  *)
input clk,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "F14"  *)
input fromRX,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "C3,A2,B3,A3,B4,A4,B5,A5" *)
output reg [7:0] value,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "D15" *)
output error,

(* altera_attribute = "-name IO_STANDARD \"3.3-V LVCMOS\"", chip_pin = "J14" *) 
input reset
);
//main idea - save all bits in shift reg. 
//catch start at right most bit (equal 0) 
//end stop at left most bit equal 0
//start, byte, stop 
parameter spi_array_size = 1 + 8 + 1;
reg [spi_array_size-1:0] spi_array;

reg clk_spi_2x = 0;
reg clk_spi = 0;

reg [31:0] Count_clk_spi_2x = 0;
typedef enum  {start, count, stop} states;

states cur_state = start;
states next_state = start;

wire clk_spi_set;

always @ ( posedge clk)
if(( Count_clk_spi_2x == ( period >> 1 >> 1  ) )) begin
    Count_clk_spi_2x <= 13'd0;
    clk_spi_2x = ~clk_spi_2x;
  end
else
  Count_clk_spi_2x <= Count_clk_spi_2x + 1'b1;


always_ff @(posedge clk_spi_2x)	
  if (clk_spi_set)
    clk_spi <= ~clk_spi;

assign clk_spi_set = ((next_state == count) || (next_state == stop) || (next_state == start));

assign clk_mux = clk_spi_set ? clk_spi : clk_spi_2x;


always_ff @(posedge clk_mux)
  if (~reset)
    spi_array <= 0;
  else
    spi_array <= {spi_array[spi_array_size - 1 - 1: spi_array_size - 1 - 1 - 8],fromRX};

always_ff @(posedge clk_mux)
  if (~reset)
    value <= 0;
  else if (cur_state == stop)
    value <= spi_array[spi_array_size - 1: spi_array_size - 1 - 7];


always_ff @(posedge clk_mux)
  if (~reset)
    cur_state <= start;
  else
    cur_state <= next_state; 

always_comb begin
  next_state = cur_state;
  case ( cur_state )
    start: 
      if( spi_array[0] == 0 ) 
        next_state = count;

    count: 
      if (spi_array[spi_array_size - 1] == 0)
        next_state = stop;

    stop:
      if (clk_spi_2x == 1) next_state = start;
  endcase
        
  end
	 
endmodule

