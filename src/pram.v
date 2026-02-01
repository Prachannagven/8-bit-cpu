module pram(
    input               clk,
    input               rst,
    input               wre,
    input [8:0]         addr,
    input [7:0]         data_in,
    
    output reg [7:0]    data_out_0,
    output reg [7:0]    data_out_1,
    output reg [7:0]    data_out_2,    
    output reg          cmd_start
);
    //States for the command start logic
    localparam INIT     = 2'b00;
    localparam DAT_LOAD = 2'b01;
    localparam START    = 2'b10;
    localparam WAIT     = 2'b11;

    reg [1:0] state;
    reg [8:0] last_addr;  // Track address changes

    //Generic doesn't use chip enable or reset because it's not exactly required
    reg [7:0] mem[511:0];                   //First creating the memory 8 bits wide with 9 address bits

    always @(posedge clk) begin
        if (rst) begin
            state <= INIT;
            data_out_0 <= 8'b0;
            data_out_1 <= 8'b0;
            data_out_2 <= 8'b0;
            cmd_start <= 1'b0;
            last_addr <= 9'b0;
        end
        else if(wre) begin                       //Writing only if write enable (wre) is enabled
            mem[addr] <= data_in;           //Saying that the memory at that address should be the data we're writing
        end
        else begin
            case (state)
                INIT: begin
                    cmd_start   <= 1'b0;
                    state       <= DAT_LOAD;
                end 
                DAT_LOAD: begin
                    data_out_0  <= mem[addr];     //Read instruction byte
                    data_out_1  <= mem[addr + 1]; //Operand 1
                    data_out_2  <= mem[addr + 2]; //Operand 2
                    last_addr   <= addr;
                    state       <= START;
                end
                START: begin
                    cmd_start   <= 1'b1;
                    state       <= WAIT;
                end
                WAIT: begin
                    // Stay in WAIT until address changes (instruction completed)
                    cmd_start   <= 1'b0;
                    if (addr != last_addr) begin
                        state <= INIT;
                    end
                end
            endcase
        end
    end

   
endmodule