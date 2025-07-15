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

    //From SRAM
    input wire [7:0] sram_rd_data,

    //----- OUTPUTS FROM DECODER -----//
    //To Program Counter
    output reg pc_hlt,
    output reg jmp_en,
    output reg [8:0] jmp_addr,
    output reg [1:0] instr_size,

    //To SRAM
    output reg [7:0] sram_addr,
    output reg sram_rd_en,
    output reg sram_wr_en,
    output reg sram_wr_data,

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
    output reg [7:0] op_2
);

    // FSM States
    localparam STATE_FETCH          = 4'b0000;
    localparam STATE_FETCH_START    = 4'b0001;
    localparam STATE_DECODE         = 4'b0011;
    localparam STATE_RETRIEVE       = 4'b0100;
    localparam STATE_RETRIEVE_START = 4'b0101;
    localparam STATE_RETRIEVE_DONE  = 4'b0110;
    localparam STATE_EXECUTE        = 4'b0111;
    localparam STATE_HALT           = 4'b1000;
    localparam STATE_WAIT           = 4'b1001;
    localparam STATE_PRNT           = 4'b1010;

    reg [3:0] state;

    reg [7:0] temp_sram_data = 8'b0;


    always @(posedge clk) begin
        if (sys_rst) begin
            pc_hlt <= 0;
            state <= STATE_FETCH_START;
        end
        else begin
            case (state)
                STATE_FETCH_START: begin
                    pc_hlt <= 1;
                    reg_wr_en <= 0;
                    state <= STATE_FETCH_START;
                end 
                STATE_FETCH_START: begin
                    pc_hlt <= 0;
                    state <= STATE_DECODE;
                end
                STATE_DECODE: begin
                    if(instr_byte[7:4] == 8'b0010) begin
                        state <= STATE_RETRIEVE;
                    end
                    else begin
                        state <= STATE_EXECUTE;
                    end
                end
                STATE_RETRIEVE: begin
                    sram_addr <= operand1;
                    state <= STATE_RETRIEVE_START;
                end
                STATE_RETRIEVE_START: begin
                    sram_rd_en <= 1;
                    temp_sram_data <=sram_rd_data;
                    state <= STATE_RETRIEVE_DONE;
                end
                STATE_RETRIEVE_DONE: begin
                    sram_rd_en <= 0;
                    state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    case (instr_byte[7:4])
                        //MOV R1, R2
                        4'b0000: begin
                            reg_wr_en <= 1;
                            reg_wr_addr <= instr_byte[3:2];
                            case (instr_byte[1:0])
                                2'b00 : reg_wr_data <= reg_a;
                                2'b01 : reg_wr_data <= reg_b;
                                2'b10 : reg_wr_data <= reg_c;
                                2'b11 : reg_wr_data <= reg_d;
                            endcase
                        end 
                        //MOV R, IMM
                        4'b0001: begin
                            reg_wr_addr <= instr_byte[3:2];
                            reg_wr_data <= operand1;
                            reg_wr_en <= 1;
                        end
                        //MOV R, [ADDR]
                        4'b0010: begin
                            reg_wr_addr <= instr_byte[3:2];
                            reg_wr_data <= temp_sram_data;
                            reg_wr_en <= 1;
                        end
                    endcase
                end
            endcase
        end
    end

    

endmodule
