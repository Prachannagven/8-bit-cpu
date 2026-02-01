#!/usr/bin/env python3
"""
Generate a Verilog testbench that loads a binary program into the CPU's PRAM.
Usage: python3 gen_tb.py <input.bin> <output.v>
"""

import sys
import os

def generate_testbench(bin_path, output_path):
    # Read binary file
    with open(bin_path, 'rb') as f:
        program_bytes = f.read()
    
    if len(program_bytes) > 512:
        print(f"Warning: Program size ({len(program_bytes)} bytes) exceeds PRAM size (512 bytes)")
        program_bytes = program_bytes[:512]
    
    # Generate memory initialization lines
    mem_init_lines = []
    for i, byte in enumerate(program_bytes):
        mem_init_lines.append(f"        uut.sys_pram.mem[{i}] = 8'h{byte:02X};")
    
    # Add padding with NOP/HLT if program is short
    if len(program_bytes) < 16:
        for i in range(len(program_bytes), 16):
            mem_init_lines.append(f"        uut.sys_pram.mem[{i}] = 8'h00;  // NOP")
    
    mem_init = '\n'.join(mem_init_lines)
    
    # Generate the testbench
    testbench = f'''`timescale 1ns/1ns

// Auto-generated testbench for: {os.path.basename(bin_path)}
// Program size: {len(program_bytes)} bytes

module tb_operations;
    // Inputs
    reg sys_clk;
    reg btn1;  // Reset
    reg btn2;  // Start
    reg flash_MISO;

    // Outputs
    wire [7:0] lcd_ctrl;
    wire lcd_en;
    wire lcd_rw;
    wire lcd_rs;
    wire flash_MOSI;
    wire flash_clk;
    wire flash_cs;
    wire [7:0] leds;

    // Instantiate the CPU
    cpu_top uut (
        .sys_clk(sys_clk),
        .flash_MISO(flash_MISO),
        .btn1(btn1),
        .btn2(btn2),
        .lcd_ctrl(lcd_ctrl),
        .lcd_en(lcd_en),
        .lcd_rw(lcd_rw),
        .lcd_rs(lcd_rs),
        .flash_MOSI(flash_MOSI),
        .flash_clk(flash_clk),
        .flash_cs(flash_cs),
        .leds(leds)
    );

    // Clock generation - 27MHz = ~37ns period
    always #18 sys_clk = ~sys_clk;

    // Pre-load PRAM with program
    initial begin
        #1;  // Wait for module instantiation
{mem_init}
    end

    initial begin
        $dumpfile("tb_operations.vcd");
        $dumpvars(0, tb_operations);

        // Initialize
        sys_clk = 0;
        btn1 = 1;  // Reset active
        btn2 = 0;
        flash_MISO = 0;

        // Hold reset
        #100;
        btn1 = 0;  // Release reset

        // Monitor execution
        $display("=== Starting CPU Execution ===");
        $display("Program: {os.path.basename(bin_path)}");
        $display("");
        
        repeat(200) begin
            @(posedge sys_clk);
            #1;
            // Print state on decode cycles
            if (uut.dec_inst.state == 3) begin  // DECODE state
                $display("PC=%03d | Instr=%02h %02h %02h | A=%02h B=%02h C=%02h D=%02h", 
                    uut.pc_inst.pc, 
                    uut.data_out_0,
                    uut.data_out_1,
                    uut.data_out_2,
                    uut.reg_map.cpu_regs[0],
                    uut.reg_map.cpu_regs[1],
                    uut.reg_map.cpu_regs[2],
                    uut.reg_map.cpu_regs[3]);
            end
        end

        // Print final state
        $display("");
        $display("=== Final CPU State ===");
        $display("Register A: 0x%02h", uut.reg_map.cpu_regs[0]);
        $display("Register B: 0x%02h", uut.reg_map.cpu_regs[1]);
        $display("Register C: 0x%02h", uut.reg_map.cpu_regs[2]);
        $display("Register D: 0x%02h", uut.reg_map.cpu_regs[3]);
        $display("PC:         %d", uut.pc_inst.pc);

        $finish;
    end

endmodule
'''
    
    with open(output_path, 'w') as f:
        f.write(testbench)
    
    print(f"Generated testbench: {output_path}")
    print(f"Program size: {len(program_bytes)} bytes")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 gen_tb.py <input.bin> <output.v>")
        sys.exit(1)
    
    bin_path = sys.argv[1]
    output_path = sys.argv[2]
    
    if not os.path.exists(bin_path):
        print(f"Error: Binary file '{bin_path}' not found")
        sys.exit(1)
    
    generate_testbench(bin_path, output_path)
