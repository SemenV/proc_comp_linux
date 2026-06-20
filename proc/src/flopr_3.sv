module flopr_3 #(parameter WIDTH=32)
(input logic clk,rst,
input [WIDTH-1:0] RD1, RD2,
output  logic [WIDTH-1:0] A,B);

always_ff @(posedge clk, posedge rst)
    if (rst) begin
        A <= 0;
        B <= 0;
    end
    else begin
            A <=RD1;
            B <= RD2;
        end

endmodule
