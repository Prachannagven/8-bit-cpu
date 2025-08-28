# Starting with the move commands
MOVSTRUCTIONS:
MOV A, B
MOV C, 0x75
MOV [0x52], D
MOV A, [0x01]

# ALU Based Instructions
ALUSTRUCTIONS:
    ADD A, B
    SUB C, D
    AND A, C
    OR B, D
    XOR A, D

# Jump Instructions
JMP [0x42]
JZ [0x01]
JNZ ALUSTRUCTIONS
JOV [0x10]

# Additional Instructions
PRNT [0x51]
NOP
HLT