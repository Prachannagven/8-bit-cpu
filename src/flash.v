module flashNav #(
    parameter STARTUP_WAIT = 32'd10000000
)
(
    //Inputs from system or CPU
    input clk,
    input wire flash_MISO,
    input wire [5:0] char_addr,
    input btn1,
    input btn2,

    //Outputs to the 
    output reg flash_MOSI = 0,
    output reg flash_clk = 0,
    output reg flash_cs = 0,
    output reg [7:0] char_output = 0
);


endmodule