# 8-Bit Custom CPU on Tang Nano 9K

This project implements a complete 8-bit CPU from scratch on the Tang Nano 9K FPGA board. All modules — including the ALU, register file, instruction decoder, control unit, and I/O interface — were built in Verilog using finite state machines (FSMs), with a fully custom-designed instruction set architecture (ISA).

## Features

- **Custom Instruction Set Architecture (ISA)**
  - Supports MOV, arithmetic/logical operations, jumps, and I/O instructions.
  - Simple 8-bit instruction format for clarity and compactness.

- **Modular Verilog Design**
  - ALU with support for ADD, SUB, INC, DEC, AND, OR, XOR
  - Register file with 4 general-purpose registers (A, B, C, D)
  - Instruction decoder and control unit implemented using FSMs
  - Program counter, RAM access, and memory-mapped LCD output
  - Flash reader module to use a TF-card as ROM

- **Memory-Mapped LCD Output**
  - Sends character data to an HD44780-compatible LCD screen
  - Supports direct printing from memory or registers

- **Custom Compiler**
  - Translates human-readable assembly to machine code matching the ISA
  - Automates binary generation for program ROM initialization

## Instruction Set Summary

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

## Project Structure

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
├── assembler/
│   ├── assembler.exe         #The actual assembler executable
│   ├── isa.c                 #Instruction set handler. Can be modified
│   ├── isa.h                 #Header file for instruction set
│   ├── main.c                #Main file for the compiler
│   ├── output.bin            #Binary code output that should be flashed to the sd card
│   ├── sample.asm            #Sample assembly code file containing all commands
│   └── viewbin.py            #On windows pcs, hexdump is not a valid command. This file emulates that
├── testbench/
│   └── lcd_driver_tb.v
├── programs/
│   └── hello.asm            # Example program to print "Hello"
├── rom.hex                 # Output machine code for simulation/load
├── Makefile                # For compilation and synthesis
└── README.md
```

The assembler can be used with the following syntax. After navigating to the assembler folder do the following:
```bash
.\assembler.exe .\assemblyfile.asm .\output.bin
```

To view the machine code, do the following:
```bash
python viewbin.py output.bin
```

## Hardware Requirements

The entire setup requires:
- Tang Nano 9k FPGA board
- HD44780-compatible LCD
- A 1MB flash storage microsd card


## Learning Outcomes
- Understood the fetch-decode-retrieve-execute pipeline to run a CPU.
- Designed how to build an ISA, Assembler and a decoder

# Technical Documentation
## The Instruction Set and Assembler
In order to create a CPU, the first step is to identify what you want it to do. So, I sat down and thought of all the commands I wanted to implement. My main goal was to emulate an 8086, but due to the sheer complexity, I held off on that. Instead, I used a bunch of simple commands like those present in [Lushay Lab's Tutorial](https://learn.lushaylabs.com/tang-nano-9k-first-processor/), but I've also decided to add a lot of functionality within the ALU, since I had already built one. The ALU runs all possible commands present in the [NANDGame ALU Level](https://nandgame.com/).

The assembler exists to convert from my custom assembly into valid machine code that the CPU can read. The following are the valid commands and their machine code representations for this CPU.

| Mnemonic       | Opcode (Binary)     | Additional Byte 1 | Additional Byte 2 | Description                                      |
| -------------- | ------------------- | ----------------- | ----------------- | ------------------------------------------------ |
| MOV R1, R2     | 0000 $R_1R_1R_2R_2$ | -                 | -                 | Register Register Moving                         |
| MOV R, IMM     | 0001 RR00           | IMM               | -                 | Direct to register                               |
| MOV R, \[ADDR] | 0010 RR00           | ADDR              | -                 | Direct from memory                               |
| MOV \[ADDR], R | 0011 RR00           | ADDR              | -                 | Reg to Memory                                    |
| PRNT REG       | 0100 RR 00          | -                 | -                 | Print value in register to location defined by A |
| PRNT \[ADDR]   | 0100 XX 11          | ADDR              | -                 | Print value at addr to location given by A       |
| JMP \[ADDR]    | 0101 0000           | ADDR              | -                 | Unconditional Jump                               |
| JZ \[ADDR]     | 0101 0001           | ADDR              | -                 | Jump if ZF                                       |
| JNZ \[ADDR]    | 0101 0010           | ADDR              | -                 | Jump if not ZF                                   |
| JOV \[ADDR]    | 0101 0011           | ADDR              | -                 | Jump if OVF                                      |
| NOP            | 0110 1111           | -                 | -                 | No operation                                     |
| HLT            | 0111 0000           | -                 | -                 | Stop the program                                 |
| WAIT TIME_MS   | 0111 1111           | TIME_MS\[15:8]    | TIME_MS\[7:0]     | Delay by some milliseconds                       |
| AND R1, R2 | 1000 $R_1R_1R_2R_2$ | | |Bitwise and for the two registers |
| OR R1, R2  | 1001 $R_1R_1R_2R_2$ | | |Bitwise OR for the two registers  |
| XOR R1, R2 | 1010 $R_1R_1R_2R_2$ | | |Bitwise XOR for the two registers |
| NOT R1,R2  | 1011 $R_1R_1$ 00    | | |Inverts the register              |
| ADD R1,R2  | 1100 $R_1R_1R_2R_2$ | | |Adds the two registers            |
| SUB R1,R2  | 1101 $R_1R_1R_2R_2$ | | |Subtracts the two registers       |
| INC R1     | 1110 $R_1R_1$ 00    | | |Incremenets the register          |
| DEC R1     | 1111 $R_1R_1$ 00    | | |decrements the register           |

The assembler is built in C, and is basically just a collection of if-else statements that converts from the assembly into the machine code. There are a slew of error handling statements to ensure that invalid statements are present. Often times, an invalid statement will be skipped over, and the line number where the error is printed will be shown along with the error message. It's important to always come back and check out and correct these errors, lest it gets transferred to your CPU.

Note that none of the ALU commands have any additional bytes after them, as my ISA does not allow for any direct to mem or direct from address operations for the ALU.  Additionally, when you add two registers together, it saves the output to register A, **overwriting whatever was there**. This should be taken into account.

I'll be interested in adding labels as well, but for now the code can only jump to locations within itself. Additionally, memory handling is yet to be added. Functionality is coming soon.

## Register Setup
The first step in the CPU is to decide how many registers I should have. I'd like to copy the 8086 register model here somewhat, and use the following four 8-bit registers:
- **Register A - Accumulator:** Will store the results of all operations
- **Register B - Base:** Can be used as a base register for memory operations
- **Register C - Counter:** Would be used for any kind of increment/decrement loop instructions
- **Register D - General Purpose:** Will just be a general purpose register 

In all my operations, there's no case where two registers have to be *written* to, but there are many cases where two registers have to be read from. (I.e., `ADD B`). As such, the following inputs and outputs are going to be set up:

```Verilog
module reg_map (
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
	output wire [7:0] rd_data_2
)
```
## RAM
I'd like to have 256 bytes of RAM. Which means 8 address lines and 8 data lines. I'll implement this using the SRAM function on the Tang Nano 9k, but likely with my own implementation rather than the one provided by GoWin. I'm still looking for the memory documentation so that I can figure out how that works.

The inputs and outputs are as follows:
```Verilog
module sram(
	//Inputs from the CPU
	input wire [7:0] addr,
	input wire wr_en,
	input wire sram_en,
	input wire rst,
	
	//Outputs to the CPU
	inout reg [7:0] data     //Bidirectional input and output to faciliatate                                      reading and writing
)

endmodule
```

%TODO: Finish the remainder of the SRAM documentation, import from the other page.

## LCD 
### Communication
The LCD contains 8 data pins that receives information, one byte at a time, parallelly. It also containst he following additional pins:
- RS: Selects the register. if 0, then you're providing an instruction. If 1 then you're providing data to write.
- RW: If 0, then writing to the board, if 1 then reading from the board.
- E: starts/ends the data read and write. After putting the data on the lines, you need to cycle this pin high, then low in order to move the data into the LCD.

### Inputs and Outputs
The module should be able to recieve data from wherever I deem fit, and write data to the LCD. This means two things are required from outside:
1. The position of the character to be written
2.  The data that has to be written.

In this case, since the goal of the LCD is to display the status of my CPU, i want to split up the 16 slots into two parts. The left 9x2 cells are to be used by the CPU however it likes. The right 7 are reserved to display the contents of the registers. Something like this:

```
_ _ _ _ _ _ _ _ _ A _ _ _ B _ _
_ _ _ _ _ _ _ _ _ C _ _ _ D _ _
```
Where the characters after A, B, C and D are the hex representations of the registers. 

### Basic Steps
#### Initialization
To initialize, we need to send the following command to the 8 pins 

#### Connections
The LCD has to be connected to the 3.3V bank off of the FPGA. I'm using pins 25 to 42, skipping 35 as it's a clock pin. 

#### Inputs and Outputs of the Module
There are some pretty basic inputs and outputs for this driver module. They are below:
```Verilog
module lcd_driver (
    input wire clk,
    input wire rst,
    input wire start,
    input [7:0] data_in,         //Technically DB7 and DB6 are 0 and 1 respectively
    input [7:0] char_loc,        //Technically speaking, only 6 char are required
    input data_loc_req,          //Allows us to use the auto-increment feature

	output reg done_tick,
    output reg [7:0] lcd_data,
    output reg lcd_rs,
    output wire lcd_rw,
    output reg lcd_en
);

endmodule
```

All the inputs come straight from the cpu or system clock, and the output goes directly to the LCD screen. You'll note that inputs are all wires (to allow for constantly changing inputs) and outputs are registers to ensure that they don't change during the cycle of the enable pin.

The only output to the system is the "rdy" wire, which ensures that more data is not fed to the LCD driver before the current data is finished writing. 

#### FSM of the Module
There are multiple steps to write to the LCD. The datasheet provides an excellent example for our use case, using 8 data lines, and writing to the entire screen. Page 43 contains the following instruction:
![[Pasted image 20250708143552.png]]

In order to replicate the first 3 commands, we use three start bytes. Followed by which, we want to allow for writing to anywhere on the screen. To achieve that, we use a location byte and a data byte, which are written to the LCD. 

From all this, the states are as follows:
```Verilog
    parameter START_BYTE_1  = 3'b000;
    parameter START_BYTE_2  = 3'b001;
    parameter START_BYTE_3  = 3'b011;
    parameter IDLE          = 3'b010;
    parameter LOC_SET       = 3'b110;
    parameter DAT_SET       = 3'b111;
    parameter DONE          = 3'b101;
```
The main reason for three start bytes and not a scalable parametrized start sequence is for ease of writing. Since the LCD only requires 3 bytes to initialize, I've just set up three different states for each byte to be sent.

The IDLE state waits for the `start` and then checks whether or not the `data_loc_req` is high. If it's high, then we first write the location of the character to be added to the LCD, followed by the data itself. If the bit is low, then we jump directly to writing the data, and utilize the auto-increment feature present on the chip.

#### Cycling the Enable Pin
This was an interesting challenge to tackle, as I didn't want to add another state for "enable high "  and "enable low", so instead I've declared `HOLD_TIME` as a constant. From then on, we set up a counter that increments every cycle, and when it achieves the same value of `HOLD_TIME`, the state of the enable pin is toggled high, and then low after another set amount of time. 
```Verilog
if(delay_counter < HOLD_TIME) begin
	lcd_en <= 0;
end
else if(delay_counter < 2*HOLD_TIME) begin
	lcd_en <= 1;
end
else if(delay_counter < 3*HOLD_TIME) begin
	lcd_en <= 0;
	delay_counter <= 0;
	state <= NEXT_STATE;
end
```
This setup allows me to easily change the speed at which the LCD is working and figure out the fastest possible timing.