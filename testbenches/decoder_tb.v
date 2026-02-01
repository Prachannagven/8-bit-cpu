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

        #5 sys_rst = 0;

        // === Test MOV A, B ===
        @(posedge clk);
        pc_strt <= 1;
        instr_byte = 8'b00000001; // MOV A, B
        @(posedge clk); 
        pc_strt <= 0;

        repeat (3) @(posedge clk);
        #5;
        check("MOV A, B", reg_wr_addr == 2'b00 && reg_wr_data == reg_b);

        // === Test MOV D, IMM ===
        @(posedge clk);
        instr_byte = 8'h1C;
        pc_strt <= 1;
        operand1 = 8'h42;
        @(posedge clk);
        pc_strt <= 0;

        repeat (3) @(posedge clk);
        #5;
        check("MOV A, 0x42", reg_wr_addr == 2'b11 && reg_wr_data == 8'h42);


        // === Test MOV C, [0x51] === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte = 8'h28;
        operand1 = 8'h51;
        @(posedge clk);
        pc_strt <= 0;

        repeat (4) @(posedge clk);
        #5
        check("MOV C, [0x51]", reg_wr_addr == 2'b10 && sram_addr == 8'h51);

        // === Test MOV [0x75], B === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte = 8'h34;
        operand1 = 8'h75;
        @(posedge clk);
        pc_strt <= 0;

        repeat(3) @(posedge clk);
        #5
        check("MOV [0x75], B", sram_addr == 8'h75 && sram_wr_data == reg_b);

        
        // === Test AND A, B === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'h81;
        @(posedge clk);
        pc_strt <= 0;
        
        repeat (4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        #5;
        check("AND A, B", op_1 == reg_a && op_2 == reg_b && alu_inst == 3'b0);


        // === Test OR C, D === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'h9B;
        @(posedge clk);
        pc_strt <= 0;
        
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        #5;
        check("OR C, D", op_1 == reg_c && op_2 == reg_d && alu_inst == 3'b001);

        
        // === Test XOR A, B === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'hA1;
        @(posedge clk);
        pc_strt <= 0;
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        check("XOR A, B", op_1 == reg_a && op_2 == reg_b && alu_inst == 3'b010);

        // === Test NOT C === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'hB8;
        @(posedge clk);
        pc_strt <= 0;
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        check("NOT C", op_1 == reg_c && op_2 == 8'h0 && alu_inst == 3'b011);

        // === Test ADD C, D === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'b11001011;
        @(posedge clk);
        pc_strt <= 0;
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        check("ADD C, D", op_1 == reg_c && op_2 == reg_d && alu_inst == 3'b100);

        // === Test SUB A, B === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'hD1;
        @(posedge clk);
        pc_strt <= 0;
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        check("SUB A, B", op_1 == reg_a && op_2 == reg_b && alu_inst == 3'b101);
        
        // === Test INC D === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'b11101100;
        @(posedge clk);
        pc_strt <= 0;
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        check("INC C", op_1 == reg_d && op_2 == 8'h0 && alu_inst == 3'b110);

        // === Test DEC C === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'hF8;
        @(posedge clk);
        pc_strt <= 0;
        repeat(4) @(posedge clk);  // Extra cycle for ALU_WAIT state
        check("DEC C", op_1 == reg_c && op_2 == 8'h0 && alu_inst == 3'b111);

        // === Test JMP [0x62] === //
        @(posedge clk);
        pc_strt <= 1;
        instr_byte <= 8'h50;
        operand1 <= 8'h62;
        @(posedge clk);
        pc_strt <= 0;
        repeat(3) @(posedge clk);
        check("JMP [0x62]", jmp_addr == operand1);
        
        // === Test JZ [0x57] === //
        @(posedge clk);
        pc_strt <= 1;
        reg_flags <= 8'h02;  //Zero Flag Enabled
        instr_byte <= 8'h51;
        operand1 <= 8'h57;
        @(posedge clk);
        pc_strt <= 0;
        repeat(3) @(posedge clk);
        check("JZ [0x57]", jmp_addr == operand1);
        

        // === Test JZ [0x75] === //
        @(posedge clk);
        pc_strt <= 1;
        reg_flags <= 8'h00;  //Zero Flag Not Enabled
        instr_byte <= 8'h51;
        operand1 <= 8'h75;
        @(posedge clk);
        pc_strt <= 0;
        repeat(3) @(posedge clk);
        check("JZ [0x75]", jmp_addr == 8'h00 && jmp_en == 1'b0);
        

        // === Test JNZ [0x57] === //
        @(posedge clk);
        pc_strt <= 1;
        reg_flags <= 8'h09;  //Zero Flag Not Enabled
        instr_byte <= 8'h52;
        operand1 <= 8'h57;
        @(posedge clk);
        pc_strt <= 0;
        repeat(3) @(posedge clk); 
        check("JNZ [0x57]", jmp_addr == operand1);

        // === Test JNZ [0x75] === //
        @(posedge clk);
        pc_strt <= 1;
        reg_flags <= 8'h02;  //Zero Flag Enabled
        instr_byte <= 8'h52;
        operand1 <= 8'h75;
        @(posedge clk);
        pc_strt <= 0;
        repeat(3) @(posedge clk);
        check("JNZ [0x75]", jmp_addr == 8'h00 && jmp_en == 1'b0);

        // === Test JOV [0x65] === //
        @(posedge clk);
        pc_strt <= 1;
        reg_flags <= 8'h01;  //Overflow flag Enabled
        instr_byte <= 8'h53;
        operand1 <= 8'h65;
        @(posedge clk);
        pc_strt <= 0; 
        repeat(3) @(posedge clk);
        check("JOV [0x65]", jmp_addr == operand1);

        // === Test JOV [0x81] === //
        @(posedge clk);
        pc_strt <= 1;
        reg_flags <= 8'h00;  //Overflow flag enabled Not Enabled
        instr_byte <= 8'h53;
        operand1 <= 8'h81;
        @(posedge clk);
        pc_strt <= 0;
        repeat(3) @(posedge clk);
        check("JOV [0x81]", jmp_addr == 8'h00 && jmp_en == 1'b0);

        #1000;
        $display("Test completed.");
        $finish;
    end

endmodule
