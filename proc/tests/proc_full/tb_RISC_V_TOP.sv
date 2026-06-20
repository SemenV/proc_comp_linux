
`timescale 1ns/100ps
module tb_RISC_V_TOP();

reg tb_clk = 0;
reg tb_rst = 0;

always tb_clk = #5 ~tb_clk;

RISC_V_TOP RISC_V_TOP_inst(
.clk(tb_clk),
.rst(tb_rst)
);

initial begin
    tb_rst <= 1;
    repeat (1) @(posedge tb_clk);
    tb_rst <= 0;

    repeat (100) @(posedge tb_clk);

    $finish;
end

endmodule
