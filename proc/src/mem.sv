module mem (
input wire clk,
input wire rst,
input wire ena,
input wire [31:0] adr,
output reg [31:0] dout,
output reg [31:0] din
);

parameter mem_len = 136;

reg [(mem_len - 1):0][7:0] mem ;


always_ff @(posedge clk)
    if (rst) begin
        {mem[0],mem[1],mem[2],mem[3]} <= 32'b000000001001_00000_010_01000_0000011;
    end
    else
        if (ena)
            mem[adr] <= din;

assign dout = {mem[adr],mem[adr+1],mem[adr+2],mem[adr+3]};

endmodule
