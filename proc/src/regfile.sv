module regfile(
input logic clk,
input logic we3,
input logic [4:0] a1,a2,a3,
input logic [31:0] wd3,
output logic [31:0] rd1,rd2,
input wire rst
);

logic [31:0][31:0] rf;

always_ff @(posedge clk)
    if (rst)
        rf <= '0;
    else
        if (we3)
            rf[a3] <= wd3;

assign rd1 = (a1 != 0 ) ? rf[a1] : 0;
assign rd2 = (a2 != 0 ) ? rf[a2] : 0;

endmodule
