module flopr_4 #(parameter WIDTH=32)
(input logic clk,rst,
input [WIDTH-1:0] ALUResult,
output  logic [WIDTH-1:0] ALUOut);

always_ff @(posedge clk, posedge rst)
    if (rst)
        ALUOut <= 0;
    else begin
            ALUOut <= ALUResult;
        end

endmodule
