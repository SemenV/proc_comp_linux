module mux_3 #(parameter WIDTH = 32)
(input logic [WIDTH-1:0] A,OldPC,PC,
input logic [1:0] AluSrcA,
output logic [WIDTH-1:0] SrcA);

always_comb
    case ({AluSrcA})
        {2'b00}: SrcA =PC;
        {2'b01}: SrcA =OldPC;
        {2'b10}: SrcA =A;
        default: SrcA =0;
    endcase

endmodule
