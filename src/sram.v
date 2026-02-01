module sram(
    input clk,
    input rst,
    input we,
    input [7:0] addr,
    input [7:0] data_in,
    output reg [7:0] data_out
);

//Generic doesn't use chip enable or reset because it's not exactly required
    reg [7:0] mem[255:0];     //First creating the memory 8 bits wide with 8 address bits

    always @(posedge clk) begin
        if(rst) begin
            data_out <= 8'b0;
        end
        else if(we) begin             //Writing only if write enable is enabled
            mem[addr] <= data_in;   //Saying that the memory at that address should be the data we're writing
        end
        else begin        //Reading
            data_out <= mem[addr];
        end
    end

endmodule