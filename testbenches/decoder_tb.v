`timescale 1ns/1ns

module decoder_tb;

    // Inputs
    reg clk;
    reg sys_rst;
    reg [7:0] instr_byte;
    reg [7:0] operand1;
    reg [7:0] operand2;
    reg lcd_done;
    reg [7:0] reg_a, reg_b, reg_c, reg_d, reg_flags;
    reg [7:0] res;
    reg [7:0] sram_data;
    reg pc_strt;

    // Outputs
    wire pc_hlt, jmp_en, sram_rd_en, sram_wr_en, reg_wr_en;
    wire [1:0] instr_size, reg_wr_addr;
    wire [8:0] jmp_addr;
    wire [7:0] sram_addr, lcd_data, data_loc, reg_wr_data, sram_wr_data;
    wire [2:0] alu_inst;
    wire [7:0] op_1, op_2;

    // Instantiate decoder
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
        .sram_wr_data(sram_wr_data),
        .loc_req(),
        .strt(),
        .reg_wr_data(reg_wr_data),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_en(reg_wr_en),
        .alu_inst(alu_inst),
        .op_1(op_1),
        .op_2(op_2),
        .cmd_start(pc_strt)
    );

    // Clock generation
    always #13 clk = ~clk;

    // Task to check result
    task check;
        input [1023:0] name;
        input condition;
        begin
            if (condition)
                $display("[PASS] %s", name);
            else
                $display("[FAIL] %s", name);
        end
    endtask

    initial begin
        $dumpfile("decoder_tb.vcd");
        $dumpvars(0, decoder_tb);

        // Initial state
        clk = 0;
        pc_strt = 0;
        sys_rst = 1;
        instr_byte = 0;
        operand1 = 0;
        operand2 = 0;
        lcd_done = 0;
        reg_a = 8'h11;
        reg_b = 8'h22;
        reg_c = 8'h33;
        reg_d = 8'h44;
        reg_flags = 0;
        res = 8'hAA;
        sram_data = 8'h00;

        #15 sys_rst = 0;

        // === Test MOV A, B ===
        pc_strt <= 1;
        instr_byte = 8'b00000001; // MOV A, B
        #30; // Wait for FSM to complete execution
        pc_strt <= 0;
        #100;

        check("MOV A, B", reg_wr_addr == 2'b00 && reg_wr_data == 8'h22);

        // === Test MOV D, IMM ===
        instr_byte = 8'h1C;
        pc_strt <= 1;
        #30
        pc_strt <= 0;
        operand1 = 8'h42;
        #100;

        check("MOV A, 0x42", reg_wr_addr == 2'b11 && reg_wr_data == 8'h42);

        // === Test MOV C, [0x51] === //
        pc_strt <= 1;
        #30
        pc_strt <= 0;
        instr_byte = 8'h28;
        operand1 = 8'h51;
        #120;

        check("MOV C, [0x51]", reg_wr_addr == 2'b10 && sram_addr == 8'h51);

        // === Test MOV [0x75], B === //
        pc_strt <= 1;
        #30;
        pc_strt <= 0;
        instr_byte = 8'h34;
        operand1 = 8'h75;
        #120;

        check("MOV [0x51], B", sram_addr == 8'h75 && sram_wr_data == 8'h22);

        // === Test AND A, B === //
        pc_strt = 1;
        #30;
        pc_strt = 0;
        instr_byte = 8'h81;
        #100;
        check("AND A, B", op_1 == 8'h11 && op_2 == 8'h22 && alu_inst == 3'b0);
        
        $display("Test completed.");
        $finish;
    end

endmodule
