module control_unit
(
input clk,
input reset,
output  AdrSrc,
output  IRWrite,
output  [1:0]  ALUSrcA,
output  [1:0]  ALUSrcB,
output  [1:0]  ALUOp,
output  [1:0]  ResultSrc,
output   PCUpdate,
output  Branch,
output  RegWrite,
output  MemWrite,
output  [2:0]  ALUControl,
output  [1:0] ImmSrc,
input [6:0]  op,
input [3:0]  func3,
input [0:0]  func7_5

);
typedef enum reg [31:0] { 
S0Fetch,
S7ALUWB,
S8ExecuteL,
S10Beq,
S9Jal,
S1Decode,
S4MemWB,
S2MemAdr,
S5MemWrite,
S3MemRead,
S6ExecuteR
    
} states_type;

states_type state, nextstate;

always_ff @(posedge clk, posedge reset)
    if (reset) state <= S0Fetch;
    else state <= nextstate;

always_comb
begin
nextstate = S0Fetch;
case (state)
    S6ExecuteR : begin
        ALUSrcA = 10;
        ALUSrcB = 00;
        ALUOp = 10;
        case(op)
            op : nextstate =S7ALUWB;
        endcase
end

    S2MemAdr : begin
        ALUSrcA = 10;
        ALUSrcB = 01;
        ALUOp = 00;
        case(op)
            0000011 : nextstate =S3MemRead;
            0100011 : nextstate =S5MemWrite;
        endcase
end

    S5MemWrite : begin
        ResultSrc = 00;
        AdrSrc = 1;
        MemWrite = 1;
        case(op)
            op : nextstate =S4MemWB;
        endcase
end

    S9Jal : begin
        ALUSrcA = 01;
        ALUSrcB = 10;
        ALUOp = 00;
        ResultSrc = 00;
        PCUpdate = 0;
        case(op)
            op : nextstate =S7ALUWB;
        endcase
end

    S7ALUWB : begin
        ResultSrc = 00;
        RegWrite = 1;
        case(op)
            op : nextstate =S4MemWB;
        endcase
end

    S8ExecuteL : begin
        ALUSrcA = 10;
        ALUSrcB = 01;
        ALUOp = 10;
        case(op)
            op : nextstate =S7ALUWB;
        endcase
end

    S10Beq : begin
        ALUSrcA = 10;
        ALUSrcB = 00;
        ALUOp = 01;
        ResultSrc = 00;
        Branch = 0;
        case(op)
            op : nextstate =S4MemWB;
        endcase
end

    S1Decode : begin
        ALUSrcA = 01;
        ALUSrcB = 01;
        ALUOp = 00;
        case(op)
            00000110100011 : nextstate =S2MemAdr;
            0110011 : nextstate =S6ExecuteR;
            0010011 : nextstate =S8ExecuteL;
            1101111 : nextstate =S9Jal;
            1100011 : nextstate =S10Beq;
        endcase
end

    S3MemRead : begin
        ResultSrc = 00;
        AdrSrc = 1;
        case(op)
            op : nextstate =S4MemWB;
        endcase
end

    S4MemWB : begin
        ResultSrc = 01;
        RegWrite = 1;
        case(op)
            op : nextstate =S0Fetch;
        endcase
end

    S0Fetch : begin
        AdrSrc = 0;
        IRWrite = 1;
        ALUSrcA = 00;
        ALUSrcB = 10;
        ALUOp = 00;
        ResultSrc = 10;
        PCUpdate = 1;
        case(op)
            op : nextstate =S1Decode;
        endcase
end

endcase


end

endmodule
    