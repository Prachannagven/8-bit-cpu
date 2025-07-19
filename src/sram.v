module pram(
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [7:0] addr,
    inout [7:0] data,
);

//Generic doesn't use chip enable or reset because it's not exactly required
    reg [7:0] mem[255:0];     //First creating the memory 8 bits wide with 8 address bits
    reg [7:0] read_addr;       //The address that has to be read from. We only use this for reading

    always @(posedge clk) begin
        if(wr_en) begin             //Writing only if write enable (wre) is enabled
            mem[addr] <= data;   //Saying that the memory at that address should be the data we're writing
        end
        else if(rd_en) begin        //Reading only if read enable is high
            read_addr <= addr;      //If reading, just making sure the address we're reading from is the one requested
        end
    end

    assign data = mem[read_addr];   //Continuous assignment for op
endmodule