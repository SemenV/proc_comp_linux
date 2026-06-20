module RISC_V_TOP(
input clk,
input rst
);


logic [31:0] Result;
logic [31:0] Adr;
logic [31:0] PC;
logic [31:0] data_back_0;
logic [31:0] data_4m_mem;
logic [31:0] Data;
logic PCWrite;
logic AdrSrc;
logic IRWrite;
logic RegWrite;
logic [31:0] regf_a1_i,regf_a2_i,regf_a3_i;
logic [31:0] RD1,RD2,A,B;
logic [31:0] OldPC;
logic AluSrcA;
logic [31:0] SrcA,SrcB;
logic [31:0] ImmExt;
logic AluSrcB;
logic [2:0] ALUControl;
logic [31:0] ALUResult;
logic Zero;
logic [31:0] ALUOut;
logic ResultSrc;

assign regf_a1_i = data_4m_mem[19:15];
assign regf_a2_i = data_4m_mem[24:20];
assign regf_a3_i = data_4m_mem[11:7];


flopr_0 flopr_0_inst (
.clk(clk),
.rst(rst),
.EN(PCWrite),
.PCNext(Result),
.PC(PC)
);

mux_0 mux_0_inst (
.mux0_0_i(PC),
.mux0_1_i(data_back_0),
.control(AdrSrc),
.mux_0_o(Adr)
);

mem mem_inst(
.clk(clk),
.rst(rst),
.adr(Adr),
.din(),
.dout(data_4m_mem)
);

flopr_1 flopr_1_inst (
.clk(clk),
.rst(rst),
.EN(IRWrite),
.PC(PC),
.RD(data_4m_mem),
.Instr(),
.OldPC(OldPC)
);

flopr_2 flopr_2_inst (
.clk(clk),
.rst(rst),
.EN(1'b1),
.ReadData(data_4m_mem),
.Data(Data)
);

regfile regfile_inst (
.clk(clk),
.rst(rst),
.we3(RegWrite),
.a1(regf_a1_i),
.a2(regf_a2_i),
.a3(regf_a3_i),
.wd3(data_back_0),
.rd1(RD1),
.rd2(RD2)
);

flopr_3 flopr__inst_q (
.clk(clk),
.rst(rst),
.RD1(RD1),
.RD2(RD2),
.A(A),
.B(B)
);

mux_3 mux_3_inst (
.AluSrcA(AluSrcA),
.PC(PC),
.OldPC(OldPC),
.A(A),
.SrcA(SrcA)
);

mux_4 mux_4_inst (
.WriteData(B),
.ImmExt(ImmExt),
.AluSrcB(AluSrcB),
.SrcB(SrcB)
);

alu alu_inst (
.ALUControl(ALUControl),
.A(SrcA),
.B(SrcB),
.ALUResult(ALUResult),
.Zero(Zero)
);

flopr_4 flopr_4_inst (
.clk(clk),
.rst(rst),
.AluResult(AluResult),
.ALUOut(ALUOut)
);

mux_5 mux_5_inst (
.ResultSrc(ResultSrc),

.ALUOut(ALUOut),
.Data(Data),
.ALUResult(AluResult),

.Result(data_back_0)
);


endmodule
