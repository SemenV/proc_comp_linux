module swp
(
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
S7ALUWB,
S1Decode,
S10Beq,
S9Jal,
S6ExecuteR,
S2MemAdr,
S5MemWrite,
S8ExecuteL,
S4MemWB,
S0Fetch,
S3MemRead
    
} states_type;

states_type state, nextstate;

always_ff @(posedge clk, posedge reset)
    if (reset) state <= S0Fetch;
    else state <= nextstate;

always_comb
begin
case (state)
    S6ExecuteR : case(op)
        op : nextstate =S7ALUWB;
    endcase

    S2MemAdr : case(op)
        0000011 : nextstate =S3MemRead;
        0100011 : nextstate =S5MemWrite;
    endcase

    S0Fetch : case(op)
        op : nextstate =S1Decode;
    endcase

    S9Jal : case(op)
        op : nextstate =S7ALUWB;
    endcase

    S5MemWrite : case(op)
        op : nextstate =S4MemWB;
    endcase

    S7ALUWB : case(op)
        op : nextstate =S4MemWB;
    endcase

    S3MemRead : case(op)
        op : nextstate =S4MemWB;
    endcase

    S10Beq : case(op)
        op : nextstate =S4MemWB;
    endcase

    S1Decode : case(op)
        00000110100011 : nextstate =S2MemAdr;
        0110011 : nextstate =S6ExecuteR;
        0010011 : nextstate =S8ExecuteL;
        1101111 : nextstate =S9Jal;
        1100011 : nextstate =S10Beq;
    endcase

    S8ExecuteL : case(op)
        op : nextstate =S7ALUWB;
    endcase

    S4MemWB : case(op)
        op : nextstate =S0Fetch;
    endcase

endcase


end

endmodule
    