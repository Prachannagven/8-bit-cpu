module decoder (
    //----- INPUTS TO DECODER -----//
    //From System
    input wire clk,
    input wire sys_rst,

    //From PRAM
    input wire [7:0] instr_byte,
    input wire [7:0] operand1,
    input wire [7:0] operand2,

    //From LCD Display
    input wire lcd_done,

    //From Registers
    input wire [7:0] reg_a,
    input wire [7:0] reg_b,
    input wire [7:0] reg_c,
    input wire [7:0] reg_d,
    input wire [7:0] reg_flags,

    //From ALU
    input wire [7:0] res,

    //To and From SRAM
    inout wire [7:0] sram_data,

    //----- OUTPUTS FROM DECODER -----//
    //To Program Counter
    output reg hlt,
    output reg jmp_en,
    output reg [8:0] jmp_addr,
    output reg [1:0] instr_size,

    //To SRAM
    output reg [7:0] sram_addr,
    output reg rd_en,
    output reg wr_en,

    //To LCD Driver
    output reg [7:0] lcd_data,
    output reg [7:0] data_loc,
    output reg loc_req,
    output reg strt,

    //To Register Block
    output reg [7:0] reg_data,
    output reg [1:0] reg_addr,

    //To ALU
    output reg [2:0] alu_inst,
    output reg [7:0] op_1,
    output reg [7:0] op_2
);

    // SRAM Tri-state control
    reg [7:0] sram_data_out;
    reg sram_drive;

    assign sram_data = sram_drive ? sram_data_out : 8'bz;

    // FSM States
    localparam STATE_FETCH     = 3'b000;
    localparam STATE_DECODE    = 3'b001;
    localparam STATE_WAIT_LCD  = 3'b010;
    localparam STATE_HALT      = 3'b011;

    reg [2:0] state;

    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            state <= STATE_FETCH;
            hlt <= 0;
            jmp_en <= 0;
            instr_size <= 1;
        end else begin
            case (state)
                STATE_FETCH: begin
                    // Reset control signals
                    hlt <= 0;
                    jmp_en <= 0;
                    alu_inst <= 3'b000;
                    instr_size <= 1;
                    rd_en <= 0;
                    wr_en <= 0;
                    strt <= 0;
                    sram_drive <= 0;

                    state <= STATE_DECODE;
                end

                STATE_DECODE: begin
                    case (instr_byte[7:4])
                        4'b0000: begin // MOV R1, R2
                            reg_addr <= instr_byte[3:2];
                            case (instr_byte[1:0])
                                2'b00: reg_data <= reg_a;
                                2'b01: reg_data <= reg_b;
                                2'b10: reg_data <= reg_c;
                                2'b11: reg_data <= reg_d;
                            endcase
                            instr_size <= 1;
                        end

                        4'b0001: begin // MOV R, IMM
                            reg_addr <= instr_byte[3:2];
                            reg_data <= operand1;
                            instr_size <= 2;
                        end

                        4'b0010: begin // MOV R, [ADDR]
                            reg_addr <= instr_byte[3:2];
                            sram_addr <= operand1;
                            rd_en <= 1;
                            instr_size <= 2;
                        end

                        4'b0011: begin // MOV [ADDR], R
                            sram_addr <= operand1;
                            case (instr_byte[3:2])
                                2'b00: sram_data_out <= reg_a;
                                2'b01: sram_data_out <= reg_b;
                                2'b10: sram_data_out <= reg_c;
                                2'b11: sram_data_out <= reg_d;
                            endcase
                            sram_drive <= 1;
                            wr_en <= 1;
                            instr_size <= 2;
                        end

                        4'b0100: begin // PRNT
                            if (instr_byte[1:0] == 2'b00) begin // PRNT REG
                                case (instr_byte[3:2])
                                    2'b00: lcd_data <= reg_a;
                                    2'b01: lcd_data <= reg_b;
                                    2'b10: lcd_data <= reg_c;
                                    2'b11: lcd_data <= reg_d;
                                endcase
                                strt <= 1;
                                loc_req <= 1;
                                data_loc <= reg_a;
                                state <= STATE_WAIT_LCD;
                            end else begin // PRNT [ADDR]
                                sram_addr <= operand1;
                                rd_en <= 1;
                                loc_req <= 1;
                                data_loc <= reg_a;
                                strt <= 1;
                                state <= STATE_WAIT_LCD;
                            end
                            instr_size <= 2;
                        end

                        4'b0101: begin // Jumps
                            jmp_addr <= operand1;
                            instr_size <= 2;
                            case (instr_byte[3:0])
                                4'b0000: jmp_en <= 1;                      // JMP
                                4'b0001: jmp_en <= reg_flags[0];          // JZ
                                4'b0010: jmp_en <= ~reg_flags[0];         // JNZ
                                4'b0011: jmp_en <= reg_flags[1];          // JOV
                            endcase
                        end

                        4'b0110: begin
                            instr_size <= 1; // NOP
                        end

                        4'b0111: begin
                            if (instr_byte[3:0] == 4'b0000)
                                hlt <= 1; // HLT
                            else if (instr_byte[3:0] == 4'b1111)
                                instr_size <= 3; // WAIT
                        end

                        4'b1000: begin // AND R1, R2
                            alu_inst <= 3'b000;
                            op_1 <= (instr_byte[3:2] == 2'b00) ? reg_a :
                                    (instr_byte[3:2] == 2'b01) ? reg_b :
                                    (instr_byte[3:2] == 2'b10) ? reg_c : reg_d;
                            op_2 <= (instr_byte[1:0] == 2'b00) ? reg_a :
                                    (instr_byte[1:0] == 2'b01) ? reg_b :
                                    (instr_byte[1:0] == 2'b10) ? reg_c : reg_d;
                            reg_addr <= instr_byte[3:2];
                            reg_data <= res;
                            instr_size <= 1;
                        end

                        // TODO: Add other ALU operations like OR, XOR, ADD, SUB, etc.

                    endcase
                    state <= STATE_FETCH;
                end

                STATE_WAIT_LCD: begin
                    if (lcd_done) begin
                        strt <= 0;
                        state <= STATE_FETCH;
                    end
                end

                STATE_HALT: begin
                    hlt <= 1;
                end
            endcase
        end
    end

endmodule
