module cpu_top (
    input wire          sys_clk,                            //System Clock, Pin 52
    input wire          flash_MISO,                         //MISO connected to the SPI chip for SD card reading
    input wire          btn1,                               //Button for resetting, Pin 3
    input wire          btn2,                               //Button to initiate start, Pin 4

    output reg [7:0]    lcd_ctrl,                           //LCD Data lines
    output reg          lcd_en,                             //LCD Enable Lines
    output reg          lcd_rw,                             //LCD RW lines. This will always be set t0 1'b0, as we're writing only
    output reg          lcd_rs,                             //LCD RS line. This will be set low during setup and high during writing
    output reg          flash_MOSI,                         //MOSI for the sd card
    output reg          flash_clk,                          //clk for spi communication with the sd card
    output reg          flash_cs,                           //chip select for the spi communication with the sd card
    output reg [7:0]    leds                                //LEDs for debugging
);
//-------------- INITIALIZING INTERMEDIATE WIRES --------------//
    //System Level Wires
    wire sys_halt;
    wire sys_rst;
    assign sys_rst = btn1;

    //Wires with the program counter
    wire pc_instr_size;
    wire sys_jmp_en;
    wire sys_jmp_addr;
    wire code_addr;

    //Wire with the flash reader
    wire pram_wre;
    wire flash_dat;

    //Wires from PRAM
    wire data_out_0;
    wire data_out_1;
    wire data_out_2;
    wire cmd_start;

    //Wire to Flash Module
    wire read_start;

    //Wire for ALU stuffs
    wire [7:0]  alu_operand_1;
    wire [7:0]  alu_operand_2;
    wire [2:0]  alu_operation;
    wire        alu_en;
    wire [7:0]  alu_res;
    wire        alu_carry;
    wire        alu_zero;
    wire        alu_ovf;
//---------------------- END INIT OF WIRES _-------------------//



//-------------- INITIALIZING ALL MODULES --------------//
    program_counter pc (
        .clk(sys_clk),
        .rst(btn1),
        .jump_en(sys_jmp_en),
        .jump_addr(sys_jmp_addr),
        .instr_size(pc_instr_size),
        .adv(sys_halt),
        .count(code_addr)
    );

    pram sys_pram (
        .clk(sys_clk),
        .addr(pc_code_addr),
        .wre(pram_wre),
        .rst(sys_rst),
        .data_in(flash_dat),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .cmd_start(cmd_start)
    );

    flash flash_reader (
        .clk(sys_clk),
        .flash_MISO(flash_MISO),
        .flash_MOSI(flash_MOSI),
        .flash_clk(flash_clk),
        .flash_cs(flash_cs),
        .rst(sys_rst),
        .strt(read_start),
        .char_output(flash_dat)
    );

    alu alu (
        .clk(sys_clk),
        .a(alu_operand_1),
        .b(alu_operand_2),
        .op(alu_operation),
        .rst(sys_rst),
        .alu_en(alu_en),
        .res(alu_res),
        .c_out(alu_carry),
        .zero(alu_zero),
        .ovf(alu_ovf)
    );

    //Small change for commit
//--------------- END ALL INSTANTIATIONS ---------------//

//First step in the PC is initialization. This occurs every time the restart button is pressed.
    always @(posedge sys_clk) begin
        
    end

endmodule