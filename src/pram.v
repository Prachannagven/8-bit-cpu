module pram(
    input               clk,
    input               rst,
    input               wre,
    input [8:0]         addr,
    input [7:0]         data_in,
    
    output [7:0]        data_out_0,
    output [7:0]        data_out_1,
    output [7:0]        data_out_2,    
    output              cmd_start
);
    //States for the command start logic
    localparam INIT     = 2'b00;
    localparam DAT_LOAD = 2'b01;
    localparam START    = 2'b10;
    localparam STOP     = 2'b11;

    reg [1:0] state = INIT;

    //Generic doesn't use chip enable or reset because it's not exactly required
    reg [7:0] mem[511:0];                   //First creating the memory 8 bits wide with 9 address bits
    reg [8:0] read_addr;                    //The address that has to be read from. We only use this for reading

    always @(posedge clk) begin
        if(wre) begin                       //Writing only if write enable (wre) is enabled
            mem[addr] <= data_in;           //Saying that the memory at that address should be the data we're writing
        end
        else begin
            case (state)
                INIT: begin
                    data_out_0  <= 8'b0;
                    data_out_1  <= 8'b0;
                    data_out_2  <= 8'b0;
                    cmd_start   <= 1'b0;
                    state       <= DAT_LOAD;
                end 
                DAT_LOAD: begin
                    data_out_0  <= mem[addr];     //Continuous assignment for op
                    data_out_1  <= mem[addr + 1]; //Location + 1
                    data_out_2  <= mem[addr + 2]; //Location + 2
                    state       <= START;
                end
                START: begin
                    cmd_start   <= 1'b1;
                    state       <= STOP;
                end
                STOP: begin
                    cmd_start   <= 1'b0';
                    state       <= INIT;
                end
            endcase
        end
    end

   
endmodule