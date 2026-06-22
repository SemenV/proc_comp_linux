module RISC_V_TOP(
input clk,
input rst
);

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
logic [1:0] AluSrcA;
logic [31:0] SrcA,SrcB;
logic [31:0] ImmExt;
logic [1:0] AluSrcB;
logic [2:0] ALUControl;
logic [31:0] ALUResult;
logic Zero;
logic [31:0] ALUOut;
logic [1:0] ResultSrc;
logic [31:0] op;
logic [31:0] Instr;
logic [31:0] func3;
logic [31:0] func7_5;
logic [1:0] ALUOp;
logic [1:0] ImmSrc;
logic MemWrite;

assign regf_a1_i = data_4m_mem[19:15];
assign regf_a2_i = data_4m_mem[24:20];
assign regf_a3_i = data_4m_mem[11:7];

assign op = Instr[6:0];
assign func3 = Instr [14:12];
assign func7_5 = Instr[30];


flopr_0 flopr_0_inst (
.clk(clk),
.rst(rst),
.EN(PCWrite),
.PCNext(data_back_0),
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
.ena(MemWrite),
.din(),
.dout(data_4m_mem)
);

flopr_1 flopr_1_inst (
.clk(clk),
.rst(rst),
.EN(IRWrite),
.PC(PC),
.RD(data_4m_mem),
.Instr(Instr),
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
.ALUResult(ALUResult),
.ALUOut(ALUOut)
);

mux_5 mux_5_inst (
.ResultSrc(ResultSrc),

.ALUOut(ALUOut),
.Data(Data),
.ALUResult(ALUResult),

.Result(data_back_0)
);

aludec ad(
.opb5(op[5]),
.funct3(funct3),
.func7_5(func7_5),
.ALUOp(ALUOp),
.ALUControl(ALUControl)
);

extend extend_inst(
.Instr(Instr[31:7]),
.ImmSrc(op[6:5]),
.ImmExt(ImmExt)
);

control_unit control_unit_inst(
.clk(clk),
.reset(rst),
.op(op),
.func3(func3),
.func7_5(func7_5),
.AdrSrc(AdrSrc),
.IRWrite(IRWrite),
.ALUSrcA(ALUSrcA),
.ALUSrcB(ALUSrcB),
.ResultSrc(ResultSrc),
// .PCWrite(PCWrite),
// .Branch,
.RegWrite(RegWrite),
.MemWrite(MemWrite),
.ALUOp(ALUOp)


);


endmodule
