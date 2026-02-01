module register_map(
    //Inputs from the CPU
    input wire clk,
    input wire rst,
	input wire [1:0] wr_addr,
	input wire [7:0] wr_data,
    input wire overflow_flag,
    input wire zero_flag,
    input wire carry_flag,
	input wire wr_en,

	//Outputs from the Register Map
    output wire [7:0] reg_a,
    output wire [7:0] reg_b,
    output wire [7:0] reg_c,
    output wire [7:0] reg_d,
    output wire [7:0] flags
);

    //Creating the registers for use
    reg [7:0] cpu_regs [0:3];
    reg [7:0] flags_reg;

    //Setting up synchronus clock 
    always @(posedge clk) begin
        if(rst) begin
            cpu_regs[0] <= 8'b0;
            cpu_regs[1] <= 8'b0;
            cpu_regs[2] <= 8'b0;
            cpu_regs[3] <= 8'b0;
            flags_reg <= 8'b0;
        end
        else if(wr_en) begin
            cpu_regs[wr_addr] <= wr_data;
        end
    end
    
    //Flags reg always updating
    always @(posedge clk) begin
        flags_reg[0] <= overflow_flag;
        flags_reg[1] <= zero_flag;
        flags_reg[2] <= carry_flag;
    end

    //Setting up asynchronus continuous-read for display to LCD
    assign reg_a = cpu_regs[0];
    assign reg_b = cpu_regs[1];
    assign reg_c = cpu_regs[2];
    assign reg_d = cpu_regs[3];
    assign flags = flags_reg;
endmodule