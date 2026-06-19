module control_unit
(
input clk,
input reset,
output  [1:0] ImmSrc,
input [0:0]  func7_5,
output  [2:0]  ALUControl,
output  [1:0]  ALUSrcB,
output  RegWrite,
output  Branch,
input [6:0]  op,
output   PCUpdate,
output  [1:0]  ALUOp,
output  [1:0]  ResultSrc,
output  MemWrite,
input [3:0]  func3,
output  AdrSrc,
output  [1:0]  ALUSrcA,
output  IRWrite
);
typedef enum reg [31:0] { 
S9Jal,
S2MemAdr,
S7ALUWB,
S4MemWB,
S3MemRead,
S1Decode,
S0Fetch,
S5MemWrite,
S8ExecuteL,
S10Beq,
S6ExecuteR
    
} states_type;

states_type state, nextstate;

wire [31:0] limit;
reg [31:0] cnt = 0;
reg ena;

always_ff @(posedge clk)
    if (reset)
        cnt <= 0;
    else
    if (cnt == limit)
        cnt <= 0;
    else 
        cnt <= cnt + 1;
			 
assign ena = cnt == limit ;

always_ff @(posedge clk, posedge reset)
    if (reset) state <= S0Fetch;
    else if (ena) state <= nextstate;

always_comb
begin
limit = 0;
AdrSrc = 0;
IRWrite = 0;
ALUSrcA = 0;
ALUSrcB = 0;
ALUOp = 0;
ResultSrc = 0;
PCUpdate = 0;
Branch = 0;
RegWrite = 0;
MemWrite = 0;
ALUControl = 0;
ImmSrc = 0;

nextstate = S0Fetch;
case (state)
    S8ExecuteL : begin
        limit = 32'd0;
        ALUSrcA = 'b10;
        ALUSrcB = 'b01;
        ALUOp = 'b10;
        case(op)
            default : nextstate =S7ALUWB;
        endcase
end

    S7ALUWB : begin
        limit = 32'd0;
        ResultSrc = 'b00;
        RegWrite = 'b1;
        case(op)
            default : nextstate =S4MemWB;
        endcase
end

    S6ExecuteR : begin
        limit = 32'd0;
        ALUSrcA = 'b10;
        ALUSrcB = 'b00;
        ALUOp = 'b10;
        case(op)
            default : nextstate =S7ALUWB;
        endcase
end

    S10Beq : begin
        limit = 32'd0;
        ALUSrcA = 'b10;
        ALUSrcB = 'b00;
        ALUOp = 'b01;
        ResultSrc = 'b00;
        Branch = 'b0;
        case(op)
            default : nextstate =S4MemWB;
        endcase
end

    S3MemRead : begin
        limit = 32'd0;
        ResultSrc = 'b00;
        AdrSrc = 'b1;
        case(op)
            default : nextstate =S4MemWB;
        endcase
end

    S4MemWB : begin
        limit = 32'd0;
        ResultSrc = 'b01;
        RegWrite = 'b1;
        case(op)
            default : nextstate =S0Fetch;
        endcase
end

    S0Fetch : begin
        limit = 32'd9;
        AdrSrc = 'b0;
        IRWrite = 'b1;
        ALUSrcA = 'b00;
        ALUSrcB = 'b10;
        ALUOp = 'b00;
        ResultSrc = 'b10;
        PCUpdate = 'b1;
        case(op)
            default : nextstate =S1Decode;
        endcase
end

    S9Jal : begin
        limit = 32'd0;
        ALUSrcA = 'b01;
        ALUSrcB = 'b10;
        ALUOp = 'b00;
        ResultSrc = 'b00;
        PCUpdate = 'b0;
        case(op)
            default : nextstate =S7ALUWB;
        endcase
end

    S2MemAdr : begin
        limit = 32'd0;
        ALUSrcA = 'b10;
        ALUSrcB = 'b01;
        ALUOp = 'b00;
        case(op)
            0000011 : nextstate =S3MemRead;
            0100011 : nextstate =S5MemWrite;
        endcase
end

    S1Decode : begin
        limit = 32'd0;
        ALUSrcA = 'b01;
        ALUSrcB = 'b01;
        ALUOp = 'b00;
        case(op)
            0000011,0100011 : nextstate =S2MemAdr;
            0110011 : nextstate =S6ExecuteR;
            0010011 : nextstate =S8ExecuteL;
            1101111 : nextstate =S9Jal;
            1100011 : nextstate =S10Beq;
        endcase
end

    S5MemWrite : begin
        limit = 32'd0;
        ResultSrc = 'b00;
        AdrSrc = 'b1;
        MemWrite = 'b1;
        case(op)
            default : nextstate =S4MemWB;
        endcase
end

endcase


end

endmodule
    