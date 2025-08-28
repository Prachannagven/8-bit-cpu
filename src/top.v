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
    wire [7:0] sys_jmp_addr;
    wire [7:0] pc_code_addr;

    //Wire with the flash reader
    wire pram_wre;
    wire [7:0] flash_dat;

    //Wires from PRAM
    wire [7:0] data_out_0;
    wire [7:0] data_out_1;
    wire [7:0] data_out_2;
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

    // Register Map wires
    wire [7:0] reg_data_out_1;
    wire [7:0] reg_data_out_2;
    wire [7:0] reg_data_in;
    wire [2:0] reg_addr_1;
    wire [2:0] reg_addr_2;
    wire [2:0] reg_addr_in;
    wire reg_write_en;

    // Instruction Decoder wires
    wire [2:0] dec_alu_op;
    wire dec_alu_en;
    wire [2:0] dec_reg_addr_1;
    wire [2:0] dec_reg_addr_2;
    wire [2:0] dec_reg_addr_in;
    wire dec_reg_write_en;
    wire [7:0] dec_reg_data_in;
    wire dec_jmp_en;
    wire [7:0] dec_jmp_addr;
    wire dec_lcd_en;
    wire [7:0] dec_lcd_data;
    wire dec_lcd_rs;
    wire dec_lcd_rw;
    wire dec_lcd_ctrl;
    wire dec_halt;
    wire dec_pram_wre;
    wire dec_read_start;
    wire dec_led_en;
    wire [7:0] dec_led_data;

    // LCD Driver wires
    wire lcd_ready;

    // SRAM wires
    wire [7:0] sram_data_out;
    wire [7:0] sram_data_in;
    wire [7:0] sram_addr;
    wire sram_we;

    // PRAM wires (already defined above)
//---------------------- END INIT OF WIRES _-------------------//



//-------------- INITIALIZING ALL MODULES --------------//
    program_counter pc (
        .clk(sys_clk),
        .rst(sys_rst),
        .jump_en(dec_jmp_en),
        .jump_addr(dec_jmp_addr),
        .instr_size(pc_instr_size),
        .adv(dec_halt),
        .count(pc_code_addr)
    );

    pram sys_pram (
        .clk(sys_clk),
        .addr(pc_code_addr),
        .wre(dec_pram_wre),
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
        .strt(dec_read_start),
        .char_output(flash_dat)
    );

    alu alu (
        .clk(sys_clk),
        .a(reg_data_out_1),
        .b(reg_data_out_2),
        .op(dec_alu_op),
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
        .addr_1(dec_reg_addr_1),
        .addr_2(dec_reg_addr_2),
        .addr_in(dec_reg_addr_in),
        .data_in(dec_reg_data_in),
        .write_en(dec_reg_write_en),
        .data_out_1(reg_data_out_1),
        .data_out_2(reg_data_out_2)
    );

    instruction_decoder decoder (
        .clk(sys_clk),
        .rst(sys_rst),
        .instr_0(data_out_0),
        .instr_1(data_out_1),
        .instr_2(data_out_2),
        .alu_op(dec_alu_op),
        .alu_en(dec_alu_en),
        .reg_addr_1(dec_reg_addr_1),
        .reg_addr_2(dec_reg_addr_2),
        .reg_addr_in(dec_reg_addr_in),
        .reg_write_en(dec_reg_write_en),
        .reg_data_in(dec_reg_data_in),
        .jmp_en(dec_jmp_en),
        .jmp_addr(dec_jmp_addr),
        .lcd_en(dec_lcd_en),
        .lcd_data(dec_lcd_data),
        .lcd_rs(dec_lcd_rs),
        .lcd_rw(dec_lcd_rw),
        .lcd_ctrl(), // Not used directly
        .halt(dec_halt),
        .pram_wre(dec_pram_wre),
        .read_start(dec_read_start),
        .led_en(dec_led_en),
        .led_data(dec_led_data)
    );

    lcd_driver lcd (
        .clk(sys_clk),
        .rst(sys_rst),
        .en(dec_lcd_en),
        .data(dec_lcd_data),
        .rs(dec_lcd_rs),
        .rw(dec_lcd_rw),
        .lcd_ctrl(lcd_ctrl),
        .lcd_en(lcd_en),
        .lcd_rw(lcd_rw),
        .lcd_rs(lcd_rs),
        .ready(lcd_ready)
    );

    sram sram_inst (
        .clk(sys_clk),
        .rst(sys_rst),
        .addr(sram_addr),
        .data_in(sram_data_in),
        .we(sram_we),
        .data_out(sram_data_out)
    );

    // Small change for commit
//--------------- END ALL INSTANTIATIONS ---------------//

//First step in the PC is initialization. This occurs every time the restart button is pressed.
    // FSM state encoding
    typedef enum logic [2:0] {
        STATE_RESET      = 3'b000,
        STATE_FETCH      = 3'b001,
        STATE_DECODE     = 3'b010,
        STATE_EXECUTE    = 3'b011,
        STATE_WRITEBACK  = 3'b100,
        STATE_HALT       = 3'b101
    } cpu_state_t;

    cpu_state_t state, next_state;

    // FSM sequential logic
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst) begin
            state <= STATE_RESET;
            leds <= 8'b0;
        end else begin
            state <= next_state;
            // LED output for debugging
            if (dec_led_en)
                leds <= dec_led_data;
            else
                leds <= leds;
        end
    end

    // FSM combinational logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_RESET: begin
                // After reset, go to fetch
                next_state = STATE_FETCH;
            end
            STATE_FETCH: begin
                // Wait for PRAM to output instruction (cmd_start high)
                if (cmd_start)
                    next_state = STATE_DECODE;
            end
            STATE_DECODE: begin
                // Wait for decoder to finish (assume 1 cycle)
                next_state = STATE_EXECUTE;
            end
            STATE_EXECUTE: begin
                // Wait for ALU or other operation to finish (assume 1 cycle)
                next_state = STATE_WRITEBACK;
            end
            STATE_WRITEBACK: begin
                // Writeback to register file or memory (assume 1 cycle)
                if (dec_halt)
                    next_state = STATE_HALT;
                else
                    next_state = STATE_FETCH;
            end
            STATE_HALT: begin
                // Remain in halt until reset
                next_state = STATE_HALT;
            end
            default: next_state = STATE_RESET;
        endcase
    end

    // Control signals for each state (example, expand as needed)
    always @(*) begin
        // Default disables
        // These signals should be connected to the modules as needed
        // Example: assign dec_alu_en = (state == STATE_EXECUTE);
        // You may need to add more control logic here for your datapath
    end

endmodule