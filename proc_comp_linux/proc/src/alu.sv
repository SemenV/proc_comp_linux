module alu #(parameter WIDTH = 32)(
input logic [2:0] ALUConrol,
input logic [WIDTH-1:0] A,
input logic [WIDTH-1:0] B,
output logic [WIDTH-1:0] ALUResult,
output logic Zero);

logic [WIDTH-1:0] muxRight0;
logic [WIDTH-1:0] Sum;
logic xor0;
logic xor1;
logic notAluC1;
logic andLeft;
logic Cout;
logic leftXor;
logic [WIDTH-1:0] extend101;
logic [WIDTH-1:0] or011;
logic [WIDTH-1:0] and010;
logic [WIDTH-1:0] diff001;
logic [WIDTH-1:0] sum000;

always_comb begin
	xor0 = ALUConrol[0] ^ B[WIDTH-1] ^ A[WIDTH-1];
	xor1 = A[WIDTH-1] ^ Sum[WIDTH-1];
	notAluC1 = ~ ALUConrol[1];
	andLeft = xor0 && xor1 && notAluC1;
	muxRight0 = ALUConrol[0] ? ((~B) + 1) : B; 
	{Cout,Sum}= muxRight0 + A;
	leftXor = andLeft ^ Sum[WIDTH-1];
	extend101 = {(WIDTH){leftXor}};
	or011 = A | B;
	and010 = A & B; 
	diff001 = Sum;
	sum000 = Sum;
	case (ALUConrol)
		{1'b0,1'b0,1'b0}: ALUResult = sum000;
		{1'b0,1'b0,1'b1}: ALUResult = diff001;
		{1'b0,1'b1,1'b0}: ALUResult = and010;
		{1'b0,1'b1,1'b1}: ALUResult = or011;
		{1'b1,1'b0,1'b1}: ALUResult = extend101;
		default: ALUResult = or011;
	endcase
	Zero = ~(|ALUResult);
	
	end
endmodule 