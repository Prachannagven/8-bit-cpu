module pram (
    input wire clk,
    input wire wr_en,
    input wire [8:0] addr,
    output reg [7:0] data
)