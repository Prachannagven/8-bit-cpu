module lcd_driver (
    //TODO: Add input lines for the various registers and make a state called "reg update" that updates the LCD.
    input wire clk,
    input wire rst,
    input wire start,
    input [7:0] data_in,                                //Technically DB7 and DB6 are 0 and 1 respectively
    input [7:0] char_loc,                               //Technically speaking, only 6 char are required
    input data_loc_req,                                 //Allows us to use the auto-increment feature

    output reg done_tick,
    output reg [7:0] lcd_data,
    output reg lcd_rs,
    output wire lcd_rw,
    output reg lcd_en
);

    assign lcd_rw = 1'b0;                               //Since we're always writing
    
    //FSM States of the LCD Module. In Gray Code because extra-ness
    reg [2:0] state;
    parameter START_BYTE_1  = 3'b000;
    parameter START_BYTE_2  = 3'b001;
    parameter START_BYTE_3  = 3'b011;
    parameter IDLE          = 3'b010;
    parameter LOC_SET       = 3'b110;
    parameter DAT_SET       = 3'b111;
    parameter DONE          = 3'b101;

    reg [15:0] delay_counter;

    parameter HOLD_TIME = 16'd500;
    initial lcd_rs = 0;
    assign lcd_rw = 0;
    initial lcd_en = 0;

    always @(posedge clk) begin
        if(rst) begin
            state <= START_BYTE_1;
            done_tick <= 0;
            lcd_en <= 0;
            delay_counter <= 0;
        end
        else begin
            case (state)
                START_BYTE_1: begin
                    lcd_data <= 8'h38;
                    delay_counter <= delay_counter+16'b1;
                    if(delay_counter < HOLD_TIME) begin
                        lcd_en <= 0;
                    end
                    else if(delay_counter < 2*HOLD_TIME) begin
                        lcd_en <= 1;
                    end
                    else if(delay_counter < 3*HOLD_TIME) begin
                        lcd_en <= 0;
                        delay_counter <= 0;
                        state <= START_BYTE_2;
                    end
                end
                START_BYTE_2: begin
                    lcd_data <= 8'h0F;
                    delay_counter <= delay_counter+16'b1;
                    if(delay_counter < HOLD_TIME) begin
                        lcd_en <= 0;
                    end
                    else if(delay_counter < 2*HOLD_TIME) begin
                        lcd_en <= 1;
                    end
                    else if(delay_counter < 3*HOLD_TIME) begin
                        lcd_en <= 0;
                        delay_counter <= 0;
                        state <= START_BYTE_3;
                    end
                end
                START_BYTE_3: begin
                    lcd_data <= 8'h06;
                    delay_counter <= delay_counter+16'b1;
                    if(delay_counter < HOLD_TIME) begin
                        lcd_en <= 0;
                    end
                    else if(delay_counter < 2*HOLD_TIME) begin
                        lcd_en <= 1;
                    end
                    else if(delay_counter < 3*HOLD_TIME) begin
                        lcd_en <= 0;
                        delay_counter <= 0;
                        state <= IDLE;
                    end
                end
                IDLE: begin
                    lcd_data <= data_in;
                    lcd_en <= 0;
                    done_tick <= 0;
                    delay_counter <= 0;
                    if(start) begin
                        if (data_loc_req) begin
                            state <= LOC_SET;
                        end
                        else begin
                            state <= DAT_SET;
                        end
                    end
                end
                LOC_SET: begin
                    lcd_data <= {1'b1, data_in[6:0]};
                    delay_counter <= delay_counter+16'b1;
                    if(delay_counter < HOLD_TIME) begin
                        lcd_en <= 0;
                    end
                    else if(delay_counter < 2*HOLD_TIME) begin
                        lcd_en <= 1;
                    end
                    else if(delay_counter < 3*HOLD_TIME) begin
                        lcd_en <= 0;
                        delay_counter <= 0;
                        state <= DAT_SET;
                    end
                end
                DAT_SET: begin
                    lcd_data <= data_in;
                    lcd_rs <= 1;
                    delay_counter <= delay_counter+16'b1;
                    if(delay_counter < HOLD_TIME) begin
                        lcd_en <= 0;
                    end
                    else if(delay_counter < 2*HOLD_TIME) begin
                        lcd_en <= 1;
                    end
                    else if(delay_counter < 3*HOLD_TIME) begin
                        lcd_en <= 0;
                        delay_counter <= 0;
                        state <= DONE;
                    end
                end
                DONE: begin
                    lcd_data <= 0;
                    lcd_rs <=0;
                    done_tick <= 1;
                    if(delay_counter == HOLD_TIME) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule