module flopr_2 #(parameter WIDTH=32)
(input logic clk,rst,
input logic EN,
input [WIDTH-1:0] ReadData,
output  logic [WIDTH-1:0] Data);

always_ff @(posedge clk, posedge rst)
	if (rst) q <= 0;
	else
		if (EN)  begin
			Instr <= RD;
			OldPC <= PC;
		end
		

endmodule 