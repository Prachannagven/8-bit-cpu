# 8-Bit Custom CPU on Tang Nano 9K

This project implements a complete 8-bit CPU from scratch on the Tang Nano 9K FPGA board. All modules — including the ALU, register file, instruction decoder, control unit, and I/O interface — were built in Verilog using finite state machines (FSMs), with a fully custom-designed instruction set architecture (ISA).

## Features

- **Custom Instruction Set Architecture (ISA)**
  - Supports MOV, arithmetic/logical operations, jumps, and memory-mapped I/O instructions.
  - Simple 8-bit instruction format for clarity and compactness.

- **Modular Verilog Design**
  - ALU with support for ADD, SUB, INC, DEC, AND, OR, XOR
  - Register file with 4 general-purpose registers (A, B, C, D)
  - Instruction decoder and control unit implemented using FSMs
  - Program counter, RAM access, and memory-mapped LCD output

- **Memory-Mapped LCD Output**
  - Sends character data to an HD44780-compatible LCD screen
  - Supports direct printing from memory or registers

- **Custom Compiler**
  - Translates human-readable assembly to machine code matching the ISA
  - Automates binary generation for program ROM initialization

## 🧠 Instruction Set Summary

| Instruction       | Description                                      |
|-------------------|--------------------------------------------------|
| `MOV R1, R2`       | Move value from register R2 to R1                |
| `MOV R, IMM`       | Move immediate value to register R               |
| `MOV [ADDR], R`    | Store register value into memory                 |
| `MOV R, [ADDR]`    | Load memory value into register                  |
| `ADD R1, R2`       | Add R2 to R1                                     |
| `SUB R1, R2`       | Subtract R2 from R1                              |
| `AND/OR/XOR R1, R2`| Logical operations between registers             |
| `JMP / JZ / JNZ / JOV` | Control flow with conditional jumps         |
| `PRNT [ADDR]`      | Print character to LCD at cursor address in A   |
| `NOP`              | No operation                                     |
| `HLT`              | Halt CPU execution                               |

## 📦 Project Structure

```bash
cpu_project/
├── src/
│   ├── alu.v
│   ├── regfile.v
│   ├── control_unit.v
│   ├── program_counter.v
│   ├── instruction_decoder.v
│   ├── memory.v
│   ├── lcd_driver.v
│   └── top.v                # Top-level CPU integration
├── compiler/
│   └── assembler.py         # Converts .asm to machine code binary
├── testbench/
│   └── lcd_driver_tb.v
├── programs/
│   └── hello.asm            # Example program to print "Hello"
├── rom.hex                 # Output machine code for simulation/load
├── Makefile                # For compilation and synthesis
└── README.md
```
