`timescale 1ns/1ns

module decoder_tb;

    // ----- Inputs ----- //
    //From System
    reg clk;
    reg sys_rst;
    //From PRAM
    reg [7:0] instr_byte;
    reg [7:0] operand1;
    reg [7:0] operand2;
    
    //FROM LCD
    reg lcd_done;

    //From Registers
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg [7:0] reg_c;
    reg [7:0] reg_d;
    reg [7:0] reg_flags;

    //From ALU
    reg [7:0] res;

    //From SRAM
    wire [7:0] sram_data;

    // ----- Outputs -----//
    //To Program Counter
    wire pc_hlt;
    wire jmp_en;
    wire [8:0] jmp_addr;
    wire [1:0] instr_size;

    //To SRAM
    wire [7:0] sram_addr;
    wire sram_rd_en;
    wire sram_wr_en;
    wire sram_wr_data;

    //To LCD
    wire [7:0] lcd_data;
    wire [7:0] data_loc;
    wire loc_req;
    wire strt;

    //To Register Block
    wire [7:0] reg_data;
    wire [1:0] reg_addr;
    wire reg_wr_en;

    //To ALU
    wire [2:0] alu_inst;
    wire [7:0] op_1;
    wire [7:0] op_2;

    // Assign dummy SRAM data
    assign sram_rd_data = 8'h55;

    // Instantiate the decoder
    decoder uut (
        .clk(clk),
        .sys_rst(sys_rst),
        .instr_byte(instr_byte),
        .operand1(operand1),
        .operand2(operand2),
        .lcd_done(lcd_done),
        .reg_a(reg_a),
        .reg_b(reg_b),
        .reg_c(reg_c),
        .reg_d(reg_d),
        .reg_flags(reg_flags),
        .res(res),
        .sram_rd_data(sram_data),
        .pc_hlt(pc_hlt),
        .jmp_en(jmp_en),
        .jmp_addr(jmp_addr),
        .instr_size(instr_size),
        .sram_addr(sram_addr),
        .sram_rd_en(sram_rd_en),
        .sram_wr_en(sram_wr_en),
        .lcd_data(lcd_data),
        .data_loc(data_loc),
        .loc_req(loc_req),
        .strt(strt),
        .reg_wr_data(reg_data),
        .reg_wr_addr(reg_addr),
        .reg_wr_en(reg_wr_en),
        .alu_inst(alu_inst),
        .op_1(op_1),
        .op_2(op_2)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Task to check expected values
    task check;
        input [8*32:1] testname;
        input condition;
        begin
            if (condition)
                $display("[PASS] %s", testname);
            else
                $display("[FAIL] %s", testname);
        end
    endtask

    // Test Sequence
    initial begin
        // VCD dump
        $dumpfile("decoder_tb.vcd");
        $dumpvars(0, decoder_tb);

        // Initial values
        clk = 0;
        sys_rst = 1;
        instr_byte = 8'h00;
        operand1 = 8'h00;
        operand2 = 8'h00;
        lcd_done = 0;
        reg_a = 8'h11;
        reg_b = 8'h22;
        reg_c = 8'h33;
        reg_d = 8'h44;
        reg_flags = 8'b00000000;
        res = 8'hAA;

        // Wait one clock cycle, then release reset
        #10 sys_rst = 0;

        // === Test 1: MOV A, IMM ===
        // Opcode: 0001 00xx => MOV A, IMM
        instr_byte = 8'b00010000; // MOV A, IMM
        operand1 = 8'h42;         // Immediate value
        #50;
        check("MOV A, IMM", reg_data == 8'h42 && reg_addr == 2'b00 && instr_size == 2);

        $display("All tests completed.");
        $finish;
    end

endmodule
