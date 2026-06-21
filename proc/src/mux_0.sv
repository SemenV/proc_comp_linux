module mux_0 #(parameter WIDTH = 32)
(input logic [WIDTH-1:0] mux0_0_i,mux0_1_i,
input logic  control,
output logic [WIDTH-1:0] mux_0_o);

always_comb
    case (control)
        {1'b0}: mux_0_o = mux0_0_i;
        {1'b1}: mux_0_o =mux0_1_i;
    endcase

endmodule
