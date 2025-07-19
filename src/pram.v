module pram(
    input               clk,
    input               rst,
    input               wre,
    input [8:0]         addr,
    input [7:0]         data_in,
    
    output [7:0]        data_out_0,
    output [7:0]        data_out_1,
    output [7:0]        data_out_2,    
);

    //Generic doesn't use chip enable or reset because it's not exactly required
    reg [7:0] mem[511:0];                   //First creating the memory 8 bits wide with 9 address bits
    reg [8:0] read_addr;                    //The address that has to be read from. We only use this for reading

    always @(posedge clk) begin
        if(wre) begin                       //Writing only if write enable (wre) is enabled
            mem[addr] <= data_in;           //Saying that the memory at that address should be the data we're writing
        end
        else begin
            read_addr <= addr;              //If reading, just making sure the address we're reading from is the one requested
        end
    end

    assign data_out_0 = mem[read_addr];     //Continuous assignment for op
    assign data_out_1 = mem[read_addr + 1]; //Location + 1
    assign data_out_2 = mem[read_addr + 2]; //Location + 2
endmodule