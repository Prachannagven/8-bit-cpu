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
    wire sys_halt;
    wire sys_jmp_en;
    wire sys_jmp_addr;
//---------------------- END INIT OF WIRES _-------------------//



//-------------- INITIALIZING ALL MODULES --------------//
    program_counter pc (
        .clk(sys_clk),
        .rst(btn1),
        .halt(sys_halt),
        .jump_en(sys_jmp_en),
        .jump_addr(sys_jmp_addr),
        
    )

//--------------- END ALL INSTANTIATIONS ---------------//

//First step in the PC is initialization. This occurs every time the restart button is pressed.
    always @(posedge sys_clk) begin
        
    end

endmodule