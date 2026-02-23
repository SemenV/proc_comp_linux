module flopr_0 #(parameter WIDTH=8)
(input logic clk,rst,
input logic EN,
input logic [WIDTH-1:0] PCNext,
output  logic [WIDTH-1:0] PC);

always_ff @(posedge clk, posedge rst)
	if (rst) q <= 0;
	else
	if (EN)
		PC <= PCNext;

endmodule 