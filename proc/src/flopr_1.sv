module flopr_1 #(parameter WIDTH=32)
(input logic clk,rst,
input logic EN,
input logic [WIDTH-1:0] PC,
input logic [WIDTH-1:0] RD,
output  logic [WIDTH-1:0] Instr,
output  logic [WIDTH-1:0] OldPC);

always_ff @(posedge clk, posedge rst)
    if (rst) begin
        Instr <= 0;
        OldPC <= 0;
    end
    else
        if (EN)  begin
            Instr <= RD;
            OldPC <= PC;
        end

endmodule
