module flashNav #(
    parameter STARTUP_WAIT = 32'd10000000
)
(
    //Inputs from system or CPU
    input clk,                              //Input 27MHz Clock
    input wire flash_MISO,                  //SPI Data in from the flash chip to the tang nano
    input rst,                             //To allow for reset and start
    input strt,

    //Outputs to the flash chip on the tang nano 9k
    output reg flash_MOSI = 0,              //SPI data out from the tang nano to the flash chip
    output reg flash_clk = 0,               //The SPI clock
    output reg flash_cs = 0,                //Chip select for the chip
    input wire [5:0] char_addr,             //Apparently used to interface with the text engine
    output reg [7:0] char_output = 0        //The character in ASCII fromat to displayed at char_adr
);
    
    //Two regs for the data byte reading since datasheet says that the byte comes as little endian, but we need to store as big endian
    reg [23:0] readAddress = 0;                     //Address we want to read from the flash
    reg [7:0] command = 8'h03;                      //Command we want to send to the flash ic
    reg [7:0] currentByteOut = 0;                   //We want to know the current byte that's coming from flash as a buffer kind of
    reg [8:0] currentByteNum = 0;                   //Gives us which byte is currently being used
    reg [4095:0] dataIn = 0;                         //Buffer to hold a read operation of 32 bytes
    reg [255:0] dataInBuffer = 0;                   //Buffer to hold another read operation of 32 bytes

    //defining the various states for our FSM
    localparam STATE_INIT_POWER = 8'd0;
    localparam STATE_LOAD_CMD_TO_SEND = 8'd1;
    localparam STATE_SEND = 8'd2;
    localparam STATE_LOAD_ADDRESS_TO_SEND = 8'd3;
    localparam STATE_READ_DATA = 8'd4;
    localparam STATE_DONE = 8'd5;

    reg [23:0] dataToSend = 0;
    reg [8:0] bitsToSend = 0;

    reg [32:0] counter = 0;
    reg [2:0] state = 0;
    reg [2:0] returnState = 0;

    always @(posedge clk) begin
        case (state)
            STATE_INIT_POWER: begin
                if(counter > STARTUP_WAIT) begin
                    state <= STATE_LOAD_CMD_TO_SEND;
                    counter <= 32'b0;
                    currentByteNum <= 0;
                    currentByteOut <=0;
                end
                else
                    counter <= counter + 32'b1;
            end 
            STATE_LOAD_CMD_TO_SEND: begin
                flash_cs <= 0;
                dataToSend[23:16] <= command;
                bitsToSend <= 8;
                state <= STATE_SEND;
                returnState <= STATE_LOAD_ADDRESS_TO_SEND;
            end
            STATE_SEND: begin
                if (counter == 32'd0) begin
                    flash_clk <= 0;
                    flash_MOSI <= dataToSend[23];
                    dataToSend <= {dataToSend[22:0], 1'b0};
                    bitsToSend <= bitsToSend - 1;
                    counter <= 1;
                end
                else begin
                    counter <= 32'd0;
                    flash_clk <= 1;
                    if(bitsToSend == 0) begin
                        state <= returnState;
                    end
                end
            end
            STATE_LOAD_ADDRESS_TO_SEND: begin
                dataToSend <= readAddress;
                bitsToSend <= 24;
                state <= STATE_SEND;
                returnState <= STATE_READ_DATA;
                currentByteNum <= 0;
            end
            STATE_READ_DATA: begin
                if (counter[0] == 1'd0) begin
                    flashClk <= 0;
                    counter <= counter + 1;
                    if (counter[3:0] == 0 && counter > 0) begin
                        dataIn[(currentByteNum << 3)+:8] <= currentByteOut;
                        currentByteNum <= currentByteNum + 1;
                        if (currentByteNum == 31)
                            state <= STATE_DONE;
                    end
                end
                else begin
                    flashClk <= 1;
                    currentByteOut <= {currentByteOut[6:0], flashMiso};
                    counter <= counter + 1;
                end
            end
            STATE_DONE: begin
                dataReady <= 1;
                flashCs <= 1;
                dataInBuffer <= dataIn;
                counter <= STARTUP_WAIT;
                state <= STATE_INIT_POWER;
            end
            default: 
        endcase
    end
endmodule