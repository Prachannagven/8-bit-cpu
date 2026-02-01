`timescale 1ns/1ns

module cpu_tb;
    // Inputs
    reg sys_clk;
    reg btn1;  // Reset
    reg btn2;  // Start
    reg flash_MISO;

    // Outputs
    wire [7:0] lcd_ctrl;
    wire lcd_en;
    wire lcd_rw;
    wire lcd_rs;
    wire flash_MOSI;
    wire flash_clk;
    wire flash_cs;
    wire [7:0] leds;

    // Instantiate the CPU
    cpu_top uut (
        .sys_clk(sys_clk),
        .flash_MISO(flash_MISO),
        .btn1(btn1),
        .btn2(btn2),
        .lcd_ctrl(lcd_ctrl),
        .lcd_en(lcd_en),
        .lcd_rw(lcd_rw),
        .lcd_rs(lcd_rs),
        .flash_MOSI(flash_MOSI),
        .flash_clk(flash_clk),
        .flash_cs(flash_cs),
        .leds(leds)
    );

    // Clock generation - 27MHz = ~37ns period
    always #18 sys_clk = ~sys_clk;

    // Pre-load PRAM with test program
    initial begin
        // Simple test program:
        // MOV A, 0x42      ; A = 0x42
        // MOV B, 0x10      ; B = 0x10
        // ADD A, B         ; A = A + B = 0x52
        // MOV C, A         ; C = A = 0x52
        
        // Wait for module instantiation
        #1;
        
        // Load program into PRAM
        // MOV A, 0x42  -> opcode: 0x10 (MOV R, IMM with R=A=00), operand: 0x42
        uut.sys_pram.mem[0] = 8'h10;  // MOV A, IMM
        uut.sys_pram.mem[1] = 8'h42;  // IMM = 0x42
        
        // MOV B, 0x10  -> opcode: 0x14 (MOV R, IMM with R=B=01), operand: 0x10
        uut.sys_pram.mem[2] = 8'h14;  // MOV B, IMM
        uut.sys_pram.mem[3] = 8'h10;  // IMM = 0x10
        
        // ADD A, B     -> opcode: 0xC1 (ADD R1, R2 with R1=A=00, R2=B=01)
        uut.sys_pram.mem[4] = 8'hC1;  // ADD A, B
        
        // MOV C, A     -> opcode: 0x08 (MOV R1, R2 with R1=C=10, R2=A=00)
        uut.sys_pram.mem[5] = 8'h08;  // MOV C, A
        
        // NOP (just filler)
        uut.sys_pram.mem[6] = 8'h00;
        uut.sys_pram.mem[7] = 8'h00;
    end

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        // Initialize
        sys_clk = 0;
        btn1 = 1;  // Reset active
        btn2 = 0;
        flash_MISO = 0;

        // Hold reset
        #100;
        btn1 = 0;  // Release reset

        // Monitor execution every clock cycle for first few instructions
        $display("=== Starting CPU Execution ===");
        
        repeat(80) begin
            @(posedge sys_clk);
            #1;
            $display("T=%0t PC=%d St=%d instr=%02h alu_en=%b op1=%02h op2=%02h res=%02h wr_en=%b wr_addr=%d wr_data=%02h A=%02h B=%02h", 
                $time, 
                uut.pc_inst.pc, 
                uut.dec_inst.state,
                uut.data_out_0,
                uut.dec_alu_en,
                uut.dec_op_1,
                uut.dec_op_2,
                uut.alu_res,
                uut.dec_reg_wr_en,
                uut.dec_reg_wr_addr,
                uut.dec_reg_wr_data,
                uut.reg_map.cpu_regs[0],
                uut.reg_map.cpu_regs[1]);
        end

        // Check results
        $display("=== CPU Test Results ===");
        $display("Register A: 0x%02h (expected: 0x52)", uut.reg_map.cpu_regs[0]);
        $display("Register B: 0x%02h (expected: 0x10)", uut.reg_map.cpu_regs[1]);
        $display("Register C: 0x%02h (expected: 0x52)", uut.reg_map.cpu_regs[2]);
        $display("Register D: 0x%02h (expected: 0x00)", uut.reg_map.cpu_regs[3]);
        $display("PC: %d", uut.pc_inst.pc);
        $display("Decoder State: %d", uut.dec_inst.state);
        
        if (uut.reg_map.cpu_regs[0] == 8'h52 && 
            uut.reg_map.cpu_regs[1] == 8'h10 &&
            uut.reg_map.cpu_regs[2] == 8'h52) begin
            $display("[PASS] CPU executed program correctly!");
        end else begin
            $display("[FAIL] CPU execution failed.");
        end

        $finish;
    end

endmodule
