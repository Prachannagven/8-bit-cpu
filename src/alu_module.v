module alu (
    //Inputs to the ALU
    input wire [7:0] a,     //Operand 1
    input wire [7:0] b,     //Operand 2
    input wire [3:0] op,    //Operation Code. Each number corresponds to a different op.
    input wire c_in,        //Carry in bit

    //Outputs from the ALU
    output reg [7:0] res,   //Result
    output wire c_out,      //Carry out bit
    output wire zero,       //Zero Flag in case result of operation is 0
    output wire ovf         //Overflow flag 
);

    reg [8:0] temp;          //To catch the carry bit, adding one extra

    always @(*) begin
        case (op)
            4'b0000: temp = a & b;      //AND
            4'b0001: temp = a | b;      //OR
            4'b0010: temp = a ^ b;      //XOR
            4'b0011: temp = ~a;         //INV
            4'b0100: temp = a + b;      //ADD
            4'b0101: temp = a - b;      //SUB
            4'b0110: temp = a + 8'b1;   //INC
            4'b0111: temp = a - 8'b1;   //DEC
            4'b1000: temp = b;          //MOV
            4'b1001: temp = a;          //NOP
            default: temp = 9'b0;       //Setting to 0 otherwise
        endcase

        res = temp[7:0];                //Only the bottom 8 bits ofthe output
    end

    assign zero = (temp == 9'b0);                       //Zero flag if result is 0
    assign c_out = res[8];                              //Carry out
    assign ovf = (a[7] == b[7]) && (a[7] != res[7]);    //Overflow only if two pos numbers provide a neg or vice-versa
endmodule