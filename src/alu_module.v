module alu (
    //Inputs to the ALU
    input wire [7:0] a,     //Operand 1
    input wire [7:0] b,     //Operand 2
    input wire [2:0] op,    //Operation Code. Each number corresponds to a different op.
    input wire rst,         //System Reset

    //Outputs from the ALU
    output reg [7:0] res,   //Result
    output wire c_out,      //Carry out bit
    output wire zero,       //Zero Flag in case result of operation is 0
    output wire ovf         //Overflow flag 
);

    reg [8:0] temp;          //To catch the carry bit, adding one extra

    always @(*) begin
        if(rst) begin
            res <= 8'b0;
            c_out <= 1'b0;
            zero <= 1'b0;
            ovf <= 1'b0;
        end
        case (op)
            3'b000: temp = a & b;      //AND
            3'b001: temp = a | b;      //OR
            3'b010: temp = a ^ b;      //XOR
            3'b011: temp = ~a;         //INV
            3'b100: temp = a + b;      //ADD
            3'b101: temp = a - b;      //SUB
            3'b110: temp = a + 8'b1;   //INC
            3'b111: temp = a - 8'b1;   //DEC
            default: temp = 9'b0;       //Setting to 0 otherwise
        endcase

        res = temp[7:0];                //Only the bottom 8 bits ofthe output
    end

    assign zero = (temp == 9'b0);                       //Zero flag if result is 0
    assign c_out = res[8];                              //Carry out
    assign ovf = (a[7] == b[7]) && (a[7] != res[7]);    //Overflow only if two pos numbers provide a neg or vice-versa
endmodule