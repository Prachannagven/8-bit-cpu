module cpu_top (
    input wire          sys_clk,                            //System Clock, Pin 52
    input wire          flash_MISO,                         //MISO connected to the SPI chip for SD card reading
    input wire          btn1,                               //Button for resetting, Pin 3
    input wire          btn2,                               //Button to initiate start, Pin 4

    output wire [7:0]   lcd_ctrl,                           //LCD Data lines
    output wire         lcd_en,                             //LCD Enable Lines
    output wire         lcd_rw,                             //LCD RW lines. This will always be set t0 1'b0, as we're writing only
    output wire         lcd_rs,                             //LCD RS line. This will be set low during setup and high during writing
    output wire         flash_MOSI,                         //MOSI for the sd card
    output wire         flash_clk,                          //clk for spi communication with the sd card
    output wire         flash_cs,                           //chip select for the spi communication with the sd card
    output reg [7:0]    leds                                //LEDs for debugging
);

    // System Level Wires
    wire sys_rst;
    assign sys_rst = btn1;

    //Wires with the program counter
    wire [1:0] pc_instr_size;
    wire [8:0] pc_code_addr;

    //Wire with the flash reader
    wire [7:0] flash_dat;

    //Wires from PRAM
    wire [7:0] data_out_0;
    wire [7:0] data_out_1;
    wire [7:0] data_out_2;
    wire cmd_start;

    //Wire for ALU stuffs
    wire [7:0]  alu_res;
    wire        alu_carry;
    wire        alu_zero;
    wire        alu_ovf;

    // Register Map wires - outputs from register map
    wire [7:0] reg_a;
    wire [7:0] reg_b;
    wire [7:0] reg_c;
    wire [7:0] reg_d;
    wire [7:0] reg_flags;

    // Decoder output wires
    wire dec_pc_hlt;
    wire dec_jmp_en;
    wire [8:0] dec_jmp_addr;
    wire [1:0] dec_instr_size;
    wire [7:0] dec_sram_addr;
    wire dec_sram_rd_en;
    wire dec_sram_wr_en;
    wire [7:0] dec_sram_wr_data;
    wire [7:0] dec_lcd_data;
    wire [7:0] dec_data_loc;
    wire dec_loc_req;
    wire dec_lcd_strt;
    wire [7:0] dec_reg_wr_data;
    wire [1:0] dec_reg_wr_addr;
    wire dec_reg_wr_en;
    wire [2:0] dec_alu_inst;
    wire [7:0] dec_op_1;
    wire [7:0] dec_op_2;
    wire dec_alu_en;

    // LCD Driver wires
    wire lcd_done;

    // SRAM wires
    wire [7:0] sram_data_out;


    // Module Instantiations
    program_counter pc_inst (
        .clk(sys_clk),
        .rst(sys_rst),
        .jump_en(dec_jmp_en),
        .jump_addr(dec_jmp_addr),
        .instr_size(dec_instr_size),
        .halt(dec_pc_hlt),
        .pc(pc_code_addr)
    );

    pram sys_pram (
        .clk(sys_clk),
        .addr(pc_code_addr),
        .wre(1'b0),                     // Not writing to PRAM during execution
        .rst(sys_rst),
        .data_in(flash_dat),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .cmd_start(cmd_start)
    );

    flashNav flash_reader (
        .clk(sys_clk),
        .flash_MISO(flash_MISO),
        .flash_MOSI(flash_MOSI),
        .flash_clk(flash_clk),
        .flash_cs(flash_cs),
        .rst(sys_rst),
        .strt(1'b0),
        .char_addr(6'b0),
        .char_output(flash_dat)
    );

    alu alu_inst (
        .clk(sys_clk),
        .a(dec_op_1),
        .b(dec_op_2),
        .op(dec_alu_inst),
        .rst(sys_rst),
        .alu_en(dec_alu_en),
        .res(alu_res),
        .c_out(alu_carry),
        .zero(alu_zero),
        .ovf(alu_ovf)
    );

    register_map reg_map (
        .clk(sys_clk),
        .rst(sys_rst),
        .wr_addr(dec_reg_wr_addr),
        .wr_data(dec_reg_wr_data),
        .wr_en(dec_reg_wr_en),
        .overflow_flag(alu_ovf),
        .zero_flag(alu_zero),
        .carry_flag(alu_carry),
        .reg_a(reg_a),
        .reg_b(reg_b),
        .reg_c(reg_c),
        .reg_d(reg_d),
        .flags(reg_flags)
    );

    decoder dec_inst (
        .clk(sys_clk),
        .sys_rst(sys_rst),
        .instr_byte(data_out_0),
        .operand1(data_out_1),
        .operand2(data_out_2),
        .cmd_start(cmd_start),
        .lcd_done(lcd_done),
        .reg_a(reg_a),
        .reg_b(reg_b),
        .reg_c(reg_c),
        .reg_d(reg_d),
        .reg_flags(reg_flags),
        .res(alu_res),
        .sram_rd_data(sram_data_out),
        .pc_hlt(dec_pc_hlt),
        .jmp_en(dec_jmp_en),
        .jmp_addr(dec_jmp_addr),
        .instr_size(dec_instr_size),
        .sram_addr(dec_sram_addr),
        .sram_rd_en(dec_sram_rd_en),
        .sram_wr_en(dec_sram_wr_en),
        .sram_wr_data(dec_sram_wr_data),
        .lcd_data(dec_lcd_data),
        .data_loc(dec_data_loc),
        .loc_req(dec_loc_req),
        .strt(dec_lcd_strt),
        .reg_wr_data(dec_reg_wr_data),
        .reg_wr_addr(dec_reg_wr_addr),
        .reg_wr_en(dec_reg_wr_en),
        .alu_inst(dec_alu_inst),
        .op_1(dec_op_1),
        .op_2(dec_op_2),
        .alu_en(dec_alu_en)
    );

    lcd_driver lcd_drv (
        .clk(sys_clk),
        .rst(sys_rst),
        .start(dec_lcd_strt),
        .data_in(dec_lcd_data),
        .char_loc(dec_data_loc),
        .data_loc_req(dec_loc_req),
        .done_tick(lcd_done),
        .lcd_data(lcd_ctrl),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en)
    );

    sram sram_inst (
        .clk(sys_clk),
        .rst(sys_rst),
        .addr(dec_sram_addr),
        .data_in(dec_sram_wr_data),
        .we(dec_sram_wr_en),
        .data_out(sram_data_out)
    );

    // LED debugging output
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst) begin
            leds <= 8'b0;
        end else begin
            // Show current state on LEDs for debugging
            leds <= data_out_0;  // Show current instruction byte
        end
    end

endmodule