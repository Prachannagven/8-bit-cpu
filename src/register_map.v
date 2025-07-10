module register_map(
    //Inputs from the CPU
    input wire clk,
    input wire rst,
	input wire [1:0] rd_addr_1,
	input wire [1:0] rd_addr_2,
	input wire [1:0] wr_addr,
	input wire [7:0] wr_data,
	input wire wr_en,

	//Outputs from the Register Map
	output wire [7:0] rd_data_1,
	output wire [7:0] rd_data_2,
    output wire [7:0] reg_a,
    output wire [7:0] reg_b,
    output wire [7:0] reg_c,
    output wire [7:0] reg_d
);

    //Creating the registers for use
    reg [7:0] cpu_regs [0:3];

    //Setting up synchronus clock 
    always @(posedge clk) begin
        if(rst) begin
            cpu_regs[0] <= 8'b0;
            cpu_regs[1] <= 8'b0;
            cpu_regs[2] <= 8'b0;
            cpu_regs[3] <= 8'b0;
        end
        else if(wr_en) begin
            cpu_regs[wr_addr] <= wr_data;
        end
    end

    //Setting up asynchronus on-request read
    assign rd_data_1 = cpu_regs[rd_addr_1];
    assign rd_data_2 = cpu_regs[rd_addr_2];

    //Setting up asynchronus continuous-read for display to LCD
    assign reg_a = cpu_regs[0];
    assign reg_b = cpu_regs[1];
    assign reg_c = cpu_regs[2];
    assign reg_d = cpu_regs[3];

endmodule