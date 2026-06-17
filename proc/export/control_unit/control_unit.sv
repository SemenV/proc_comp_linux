module control_unit
(
input IRWrite,
input MemWrite,
input AdrSrc,
input PCWrite,
input op,
input funct3,
input funct7,

output reg RegWrite,
output reg ImmSrc,
output reg ALUSrcA,
output reg ALUSrcB1,
output reg ALUControl,
output reg ResultSrc
);
typedef enum { S0Fetch,
S1Decode,
S2MemAdr,
S3MemRead,
S4MemWB,
S5MemWrite,
S6ExecuteR,
S7ALUWB,
S8ExecuteL,
S9Jal,
S10Beq } state_ty;

state_ty state, nextstate;

always_ff @(posedge clk, posedge reset)
if (reset) state <= S0Fetch;
else state <= nextstate;


always_comb 
 case (state)
S0Fetch : case (op)
     op  : nextstate = S1Decode;
    default: nextstate = state;
endcase
S1Decode : case (op)
    0000011 : nextstate = S2MemAdr;
    0100011 : nextstate = S2MemAdr;
    default: nextstate = state;
endcase
S2MemAdr : case (op)
    0000011 : nextstate = S3MemRead;
    default: nextstate = state;
endcase
S3MemRead : case (op)
     op  : nextstate = S4MemWB;
    default: nextstate = state;
endcase


S2MemAdr : case (op)
    0100011 : nextstate = S5MemWrite;
    default: nextstate = state;
endcase
S5MemWrite : case (op)
     op  : nextstate = S4MemWB;
    default: nextstate = state;
endcase



S1Decode : case (op)
    0110011 : nextstate = S6ExecuteR;
    default: nextstate = state;
endcase
S6ExecuteR : case (op)
     op  : nextstate = S7ALUWB;
    default: nextstate = state;
endcase
S7ALUWB : case (op)
     op  : nextstate = S4MemWB;
    default: nextstate = state;
endcase



S1Decode : case (op)
    0010011 : nextstate = S8ExecuteL;
    default: nextstate = state;
endcase
S8ExecuteL : case (op)
     op  : nextstate = S7ALUWB;
    default: nextstate = state;
endcase
S7ALUWB : case (op)
     op  : nextstate = S4MemWB;
    default: nextstate = state;
endcase



S1Decode : case (op)
    1101111 : nextstate = S9Jal;
    default: nextstate = state;
endcase
S9Jal : case (op)
     op  : nextstate = S7ALUWB;
    default: nextstate = state;
endcase
S7ALUWB : case (op)
     op  : nextstate = S4MemWB;
    default: nextstate = state;
endcase



S1Decode : case (op)
    1100011 : nextstate = S10Beq;
    default: nextstate = state;
endcase
S10Beq : case (op)
     op  : nextstate = S4MemWB;
    default: nextstate = state;
endcase



    default: nextstate = state;
endcase
endmodule
