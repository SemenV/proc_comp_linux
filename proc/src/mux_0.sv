module mux_0 #(parameter WIDTH = 32)
(input logic [WIDTH-1:0] d0,d1,
input logic  s,
output logic [WIDTH-1:0] y);
//assign y = s[1] ? d2 : (s[0] ? d1 : d0);
always_comb
	case (s)
		//{2'b00}: y =d0;
		//{2'b01}: y =d1;
	endcase	

endmodule