module mux_5 #(parameter WIDTH = 32)
(input logic [WIDTH-1:0]
    ALUOut,
    Data,
    ALUResult,
input logic [1:0] ResultSrc,
output logic [WIDTH-1:0] Result);

always_comb
    case ({ResultSrc})
        {2'b00}: Result =ALUOut;
        {2'b01}: Result =Data;
        {2'b10}: Result =ALUResult;
        default: Result =0;
    endcase

endmodule
