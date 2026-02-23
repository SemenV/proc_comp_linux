module flopr_3 #(parameter WIDTH=32)
(input logic clk,rst,
input [WIDTH-1:0] RD1, RD2,
output  logic [WIDTH-1:0] A);

always_ff @(posedge clk, posedge rst)
	if (rst) begin 
		RD1 <= 0; 
		RD2 <= 0;
	end
	else begin
			RD1 <= 0; 
			RD2 <= 0;
		end
		

endmodule 