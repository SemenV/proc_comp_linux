module test 
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

reg bps_4x = 0;
reg bps_2x = 0;

reg [31:0] Count_bps_4x = 0;
reg [31:0] bit_counter = 0;


always @ ( posedge clk)
if(( Count_bps_4x == ( period >> 1 >> 1  ) )) begin
    Count_bps_4x <= 13'd0;
    bps_4x = ~bps_4x;
  end
else
  Count_bps_4x <= Count_bps_4x + 1'b1;


always_ff @(posedge bps_4x)	
  if ((next_state == count) || (cur_state == count))
    bps_2x = ~bps_2x;


always_ff @(posedge clk_mux)
  if (~reset) begin
    bit_counter <= 0;
    value       <= 0;
  end
  else if (cur_state == count)
    begin
      bit_counter <= bit_counter + 1;
      value       <= {value[6:0],fromRX};
    end
    else
      bit_counter <= 0;

typedef enum logic [7:0] {start,start_delay,count,stop,stop_delay} states;
states cur_state = start;
states next_state = start;

wire clk_mux;
assign clk_mux = ((next_state == count) || (cur_state == count) )? bps_2x : bps_4x;

always_ff @(posedge clk_mux)
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
      stop        :                       next_state = stop_delay;
      stop_delay  :                       next_state = start;
    endcase
  end
endmodule 
