module program_counter #(
    parameter ADDR_WIDTH = 9
)(
    input wire clk,
    input wire rst,
    input wire adv,                                 // Halts PC advancement
    input wire jump_en,                             // Enables jump
    input wire [ADDR_WIDTH-1:0] jump_addr,          // Jump target
    input wire [1:0] instr_size,                    // Number of bytes in current instruction: 1, 2, or 3

    output reg [ADDR_WIDTH-1:0] pc                  // Current Program Counter value
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 0;
        end
        else if(!adv) begin
            if (jump_en) begin
                pc <= jump_addr;
            end 
            else begin
                case (instr_size)
                    2'd1: pc <= pc + 1;
                    2'd2: pc <= pc + 2;
                    2'd3: pc <= pc + 3;
                    default: pc <= pc + 1; // Fallback
                endcase
            end 
        end
    end

endmodule
