module alu (
    // Inputs to the ALU
    input wire [7:0] a,      // Operand 1
    input wire [7:0] b,      // Operand 2
    input wire [2:0] op,     // Operation Code
    input wire rst,          // System Reset

    // Outputs from the ALU
    output reg [7:0] res,    // Result
    output reg c_out,        // Carry out bit
    output reg zero,         // Zero Flag
    output reg ovf           // Overflow Flag
);

    reg [8:0] temp;          // For intermediate result with carry

    always @(*) begin
        if (rst) begin
            temp   = 9'b0;
            res    <= 8'b0;
            c_out  = 1'b0;
            zero   = 1'b0;
            ovf    = 1'b0;
        end else begin
            case (op)
                3'b000: temp = a & b;           // AND
                3'b001: temp = a | b;           // OR
                3'b010: temp = a ^ b;           // XOR
                3'b011: temp = {1'b0, ~a};      // NOT (only `a` is inverted)
                3'b100: temp = a + b;           // ADD
                3'b101: temp = a - b;           // SUB
                3'b110: temp = a + 1;           // INC
                3'b111: temp = a - 1;           // DEC
                default: temp = 9'b0;
            endcase

            res   = temp[7:0];
            c_out = temp[8];
            zero  = (temp[7:0] == 8'b0);

            // Overflow logic only applies to ADD and SUB
            case (op)
                3'b100: ovf = (a[7] == b[7]) && (res[7] != a[7]); // ADD
                3'b101: ovf = (a[7] != b[7]) && (res[7] != a[7]); // SUB
                default: ovf = 1'b0;
            endcase
        end
    end

endmodule
