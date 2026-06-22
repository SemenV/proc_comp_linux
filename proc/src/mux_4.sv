module mux_4 #(parameter WIDTH = 32)
(input logic [WIDTH-1:0] WriteData,ImmExt,
input logic [1:0] ALUSrcB,
output logic [WIDTH-1:0] SrcB);

always_comb
    case ({ALUSrcB})
        {2'b00}: SrcB =WriteData;
        {2'b01}: SrcB =ImmExt;
        {2'b10}: SrcB =4;
        default: SrcB =0;
    endcase

endmodule
