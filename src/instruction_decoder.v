// decoder.v
`timescale 1ns/1ns

module decoder (
    input wire [7:0] instr_byte,
    input wire [7:0] operand1,
    input wire [7:0] operand2,

    output reg [1:0] reg_dst,
    output reg [1:0] reg_src,
    output reg [7:0] imm,
    output reg [7:0] mem_addr,
    output reg [3:0] alu_op,
    output reg reg_write_en,
    output reg mem_read_en,
    output reg mem_write_en,
    output reg lcd_print,
    output reg jump_en,
    output reg halt,
    output reg [1:0] pc_ctrl, // 00: next, 01: JMP, 10: JZ, 11: JNZ/JOV
    output reg [1:0] instr_len
);

    wire [3:0] opcode = instr_byte[7:4];
    wire [1:0] bits_3_2 = instr_byte[3:2];
    wire [1:0] bits_1_0 = instr_byte[1:0];

    always @(*) begin
        // Default values
        instr_len      = 2'd1;
        reg_write_en   = 0;
        mem_read_en    = 0;
        mem_write_en   = 0;
        lcd_print      = 0;
        jump_en        = 0;
        halt           = 0;
        pc_ctrl        = 2'b00;
        alu_op         = 4'b0000;
        reg_dst        = bits_3_2;
        reg_src        = bits_1_0;
        imm            = operand1;
        mem_addr       = operand1;

        case (opcode)
            4'b0000: begin // MOV R1, R2
                reg_write_en = 1;
                instr_len = 2'd1;
            end
            4'b0001: begin // MOV R, IMM
                reg_write_en = 1;
                instr_len = 2'd2;
            end
            4'b0010: begin // MOV R, [ADDR]
                reg_write_en = 1;
                mem_read_en = 1;
                instr_len = 2'd2;
            end
            4'b0011: begin // MOV [ADDR], R
                mem_write_en = 1;
                instr_len = 2'd2;
            end
            4'b0100: begin
                case (instr_byte[1:0])
                    2'b00: begin // PRNT R
                        lcd_print = 1;
                        instr_len = 2'd1;
                    end
                    2'b11: begin // PRNT [ADDR]
                        lcd_print = 1;
                        mem_read_en = 1;
                        instr_len = 2'd2;
                    end
                    default: begin
                        lcd_print = 0;
                    end
                endcase
            end
            4'b0101: begin // Jumps
                jump_en = 1;
                instr_len = 2'd2;
                case (instr_byte[3:0])
                    4'b0000: pc_ctrl = 2'b01; // JMP
                    4'b0001: pc_ctrl = 2'b10; // JZ
                    4'b0010: pc_ctrl = 2'b11; // JNZ
                    4'b0011: pc_ctrl = 2'b00; // JOV (use flag externally)
                    default: pc_ctrl = 2'b00;
                endcase
            end
            4'b0110: begin // NOP
                instr_len = 2'd1;
            end
            4'b0111: begin
                case (instr_byte[3:0])
                    4'b0000: begin halt = 1; instr_len = 2'd1; end
                    4'b1111: begin // WAIT
                        instr_len = 2'd3;
                    end
                endcase
            end
            4'b1000: begin alu_op = 4'b0001; reg_write_en = 1; instr_len = 2'd1; end // AND
            4'b1001: begin alu_op = 4'b0010; reg_write_en = 1; instr_len = 2'd1; end // OR
            4'b1010: begin alu_op = 4'b0011; reg_write_en = 1; instr_len = 2'd1; end // XOR
            4'b1011: begin alu_op = 4'b0100; reg_write_en = 1; instr_len = 2'd1; end // NOT
            4'b1100: begin alu_op = 4'b0101; reg_write_en = 1; instr_len = 2'd1; end // ADD
            4'b1101: begin alu_op = 4'b0110; reg_write_en = 1; instr_len = 2'd1; end // SUB
            4'b1110: begin alu_op = 4'b0111; reg_write_en = 1; instr_len = 2'd1; end // INC
            4'b1111: begin alu_op = 4'b1000; reg_write_en = 1; instr_len = 2'd1; end // DEC
            default: begin
                // Unknown opcode; treat as NOP
                instr_len = 2'd1;
            end
        endcase
    end
endmodule
