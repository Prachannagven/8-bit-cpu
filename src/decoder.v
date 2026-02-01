module decoder (
    input wire clk,
    input wire sys_rst,

    //From PRAM
    input wire [7:0] instr_byte,
    input wire [7:0] operand1,
    input wire [7:0] operand2,
    input wire cmd_start,

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

    //From SRAM
    input wire [7:0] sram_rd_data,

    //To Program Counter
    output reg pc_hlt,
    output reg jmp_en,
    output reg [8:0] jmp_addr,
    output reg [1:0] instr_size,

    //To SRAM
    output reg [7:0] sram_addr,
    output reg sram_rd_en,
    output reg sram_wr_en,
    output reg [7:0] sram_wr_data,

    //To LCD Driver
    output reg [7:0] lcd_data,
    output reg [7:0] data_loc,
    output reg loc_req,
    output reg strt,

    //To Register Block
    output reg [7:0] reg_wr_data,
    output reg [1:0] reg_wr_addr,
    output reg reg_wr_en,

    //To ALU
    output reg [2:0] alu_inst,
    output reg [7:0] op_1,
    output reg [7:0] op_2,
    output reg alu_en
);
    localparam STATE_INIT           = 3'd0;
    localparam STATE_FETCH          = 3'd1;
    localparam STATE_RETRIEVE       = 3'd2;
    localparam STATE_DECODE         = 3'd3;
    localparam STATE_EXECUTE_START  = 3'd4;
    localparam STATE_ALU_WAIT       = 3'd6;  // Wait for ALU result
    localparam STATE_EXECUTE_END    = 3'd5;

    reg [2:0] state;

    always @(posedge clk or posedge sys_rst) begin
        if (sys_rst) begin
            state <= STATE_INIT;
            pc_hlt <= 0;
            sram_rd_en <= 0;
            sram_wr_en <= 0;
            reg_wr_en <= 0;
            instr_size <= 1;
            jmp_addr <= 0;
            jmp_en <= 0;
            alu_en <= 0;
        end else begin
            case (state)
                STATE_INIT: begin
                    pc_hlt <= 0;
                    sram_rd_en <= 0;
                    sram_wr_en <= 0;
                    reg_wr_en <= 0;
                    // Don't reset instr_size here - PC needs to read the previous value
                    jmp_addr <= 0;
                    jmp_en <= 0;
                    alu_en <= 0;
                    if(cmd_start) begin
                        //IMPORTANT: THIS MIGHT CAUSE BAD PC MESSING UP 
                        pc_hlt <= 1;
                        state <= STATE_FETCH;                        
                    end
                    else begin
                        state <= STATE_INIT;
                    end
                end
                STATE_FETCH: begin
                    // Set default instr_size at start of new instruction
                    instr_size <= 1;
                    case (instr_byte[7:4])
                        4'b0000: state <= STATE_DECODE;
                        4'b0001: state <= STATE_DECODE;
                        4'b0010: state <= STATE_RETRIEVE;
                        4'b0011: state <= STATE_DECODE;
                        4'b1000: state <= STATE_DECODE;
                        4'b1001: state <= STATE_DECODE;
                        4'b1010: state <= STATE_DECODE;
                        4'b1011: state <= STATE_DECODE;
                        4'b1100: state <= STATE_DECODE;
                        4'b1101: state <= STATE_DECODE;
                        4'b1110: state <= STATE_DECODE;
                        4'b1111: state <= STATE_DECODE;
                        4'b0101: state <= STATE_DECODE;
                        default: state <= STATE_INIT;
                    endcase
                end

                STATE_RETRIEVE: begin
                    if (instr_byte[7:4] == 4'b0010) begin
                        sram_addr <= operand1;
                        sram_rd_en <= 1;
                    end
                    state <= STATE_DECODE;
                end

                STATE_DECODE: begin
                    case (instr_byte[7:4])
                        4'b0000: begin // MOV R1, R2
                            reg_wr_addr <= instr_byte[3:2];
                            case (instr_byte[1:0])
                                2'b00: reg_wr_data <= reg_a;
                                2'b01: reg_wr_data <= reg_b;
                                2'b10: reg_wr_data <= reg_c;
                                2'b11: reg_wr_data <= reg_d;
                            endcase
                            instr_size <= 1;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b0001: begin // MOV R, IMM
                            reg_wr_addr <= instr_byte[3:2];
                            reg_wr_data <= operand1;
                            instr_size <= 2;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b0010: begin // MOV R, [ADDR]
                            reg_wr_en <= 1;
                            reg_wr_addr <= instr_byte[3:2];
                            reg_wr_data <= sram_rd_data;
                            instr_size <= 2;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b0011: begin // MOV [ADDR], R
                            sram_addr <= operand1;
                            sram_wr_en <= 1;
                            case (instr_byte[3:2])
                                2'b00: sram_wr_data <= reg_a;
                                2'b01: sram_wr_data <= reg_b;
                                2'b10: sram_wr_data <= reg_c;
                                2'b11: sram_wr_data <= reg_d;
                            endcase
                            instr_size <= 2;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1000: begin  //AND R1, R2
                            alu_inst <= 3'b000;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            case (instr_byte[1:0])
                                2'b00: op_2 <= reg_a;
                                2'b01: op_2 <= reg_b;
                                2'b10: op_2 <= reg_c;
                                2'b11: op_2 <= reg_d;
                            endcase
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1001: begin  //OR R1, R2
                            alu_inst <= 3'b001;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            case (instr_byte[1:0])
                                2'b00: op_2 <= reg_a;
                                2'b01: op_2 <= reg_b;
                                2'b10: op_2 <= reg_c;
                                2'b11: op_2 <= reg_d;
                            endcase
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1010: begin  //XOR R1, R2
                            alu_inst <= 3'b010;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            case (instr_byte[1:0])
                                2'b00: op_2 <= reg_a;
                                2'b01: op_2 <= reg_b;
                                2'b10: op_2 <= reg_c;
                                2'b11: op_2 <= reg_d;
                            endcase
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1011: begin  //NOT R1
                            alu_inst <= 3'b011;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            op_2 <= 8'h0;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1100: begin  //ADD R1, R2
                            alu_inst <= 3'b100;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            case (instr_byte[1:0])
                                2'b00: op_2 <= reg_a;
                                2'b01: op_2 <= reg_b;
                                2'b10: op_2 <= reg_c;
                                2'b11: op_2 <= reg_d;
                            endcase
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1101: begin  //SUB R1, R2
                            alu_inst <= 3'b101;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            case (instr_byte[1:0])
                                2'b00: op_2 <= reg_a;
                                2'b01: op_2 <= reg_b;
                                2'b10: op_2 <= reg_c;
                                2'b11: op_2 <= reg_d;
                            endcase
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1110: begin  //INC R1
                            alu_inst <= 3'b110;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            op_2 <= 8'h0;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b1111: begin  //DEC R1
                            alu_inst <= 3'b111;
                            reg_wr_addr <= instr_byte[3:2];  // Destination is R1
                            case (instr_byte[3:2])
                                2'b00: op_1 <= reg_a;
                                2'b01: op_1 <= reg_b;
                                2'b10: op_1 <= reg_c;
                                2'b11: op_1 <= reg_d;
                            endcase
                            op_2 <= 8'h0;
                            state <= STATE_EXECUTE_START;
                        end
                        4'b0101: begin  //ALL JMP COMMANDS
                            case(instr_byte[1:0])
                                2'b00: begin        //JMP [ADDR]
                                    jmp_addr <= operand1;
                                    state <= STATE_EXECUTE_START;
                                end
                                2'b01: begin        //JZ [ADDR]
                                    if(reg_flags[1]) begin
                                        jmp_addr <= operand1;
                                        state <= STATE_EXECUTE_START;
                                    end
                                    else begin
                                        instr_size <= 2;
                                        state = STATE_EXECUTE_START;
                                    end
                                end
                                2'b10: begin        //JNZ [ADDR]
                                    if(!reg_flags[1]) begin
                                        jmp_addr <= operand1;
                                        state <= STATE_EXECUTE_START;
                                    end
                                    else begin
                                        instr_size <= 2;
                                        state = STATE_EXECUTE_START;
                                    end
                                end
                                2'b11: begin        //JOV [ADDR]
                                    if(reg_flags[0]) begin
                                        jmp_addr <= operand1;
                                        state <= STATE_EXECUTE_START;
                                    end
                                    else begin
                                        instr_size <= 2;
                                        state = STATE_EXECUTE_START;
                                    end
                                end
                            endcase
                        end
                    endcase
                end

                STATE_EXECUTE_START: begin
                    case (instr_byte[7:4])
                        4'b0000: begin   // MOV R1, R2
                            reg_wr_en <= 1;
                        end

                        4'b0001: begin  // MOV R, IMM
                            reg_wr_en <= 1;
                        end

                        4'b0010: begin  // MOV R, [ADDR]
                            reg_wr_en <= 1;
                        end

                        4'b0011: begin  // MOV [ADDR], R
                            sram_wr_en <= 1;
                        end

                        4'b1000: begin  // AND R1, R2
                            alu_en <= 1;
                        end
                        4'b1001: begin  // OR R1, R2
                            alu_en <= 1;
                        end
                        4'b1010: begin  // XOR R1, R2
                            alu_en <= 1;
                        end
                        4'b1011: begin  // NOT R
                            alu_en <= 1;
                        end
                        4'b1100: begin  // ADD R1, R2
                            alu_en <= 1;
                        end
                        4'b1101: begin  // SUB R1, R2
                            alu_en <= 1;
                        end
                        4'b1110: begin  // INC R
                            alu_en <= 1;
                        end
                        4'b1111: begin  // DEC R
                            alu_en <= 1;
                        end
                        4'b0101: begin
                            case (instr_byte[1:0])
                                2'b00: jmp_en <=1;
                                2'b01: jmp_en <= reg_flags[1];
                                2'b10: jmp_en <= reg_flags[1];
                                2'b11: jmp_en <= reg_flags[1];
                            endcase
                        end
                    endcase
                    // Determine next state based on instruction type
                    case (instr_byte[7:4])
                        4'b1000, 4'b1001, 4'b1010, 4'b1011, 
                        4'b1100, 4'b1101, 4'b1110, 4'b1111: begin
                            // ALU operations need an extra cycle for result
                            state <= STATE_ALU_WAIT;
                        end
                        default: begin
                            state <= STATE_EXECUTE_END;
                        end
                    endcase
                end

                STATE_ALU_WAIT: begin
                    // ALU result is now ready, proceed to writeback
                    state <= STATE_EXECUTE_END;
                end

                STATE_EXECUTE_END: begin
                    case (instr_byte[7:4])
                        4'b0000: begin  // MOV R1, R2
                            reg_wr_en <= 0;
                        end

                        4'b0001: begin  // MOV R, IMM
                            reg_wr_en <= 0;
                        end

                        4'b0010: begin  // MOV R, [ADDR]
                            reg_wr_en <= 0;
                        end

                        4'b1000: begin  // AND R1, R2
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1001: begin  // OR R1, R2
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1010: begin  // XOR R1, R2
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1011: begin  // NOT R
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1100: begin  // ADD R1, R2
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1101: begin  // SUB R1, R2
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1110: begin  // INC R
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b1111: begin  // DEC R
                            alu_en <= 0;
                            reg_wr_data <= res;
                            reg_wr_en <= 1;
                        end
                        4'b0101: begin
                            case (instr_byte[1:0])
                                2'b00: jmp_en <= 0;
                                2'b01: jmp_en <= 0;
                                2'b10: jmp_en <= 0;
                                2'b11: jmp_en <= 0;
                            endcase
                        end
                    endcase
                    state <= STATE_INIT;
                end
            endcase
        end
    end

endmodule
