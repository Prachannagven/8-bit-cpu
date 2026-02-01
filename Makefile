# 8-bit CPU Project Makefile
# Usage: 
#   make TB=decoder_tb simulate   - Run a specific testbench (default: decoder_tb)
#   make program.asm              - Assemble and run program.asm on the CPU
#   make view ASM=program         - View waveform for program

TB ?= decoder_tb
ASM ?= program

TB_MODULE       = $(TB).v
EXECUTABLE      = $(TB)
VCD_OUTPUT      = $(TB).vcd

TB_FOLDER       = ./testbenches
SRC_FOLDER      = ./src
ASM_FOLDER      = ./assembler

# All Verilog source files
SRC_FILES       = $(wildcard $(SRC_FOLDER)/*.v)

# Assembler
ASSEMBLER       = $(ASM_FOLDER)/assembler

all: simulate

# Build the assembler
$(ASSEMBLER): $(ASM_FOLDER)/main.c $(ASM_FOLDER)/isa.c $(ASM_FOLDER)/isa.h
	$(MAKE) -C $(ASM_FOLDER)

# Pattern rule: make <name>.asm assembles and runs the program
%.asm: $(ASSEMBLER)
	@echo "=== Assembling $@ ==="
	$(ASSEMBLER) $(ASM_FOLDER)/$@ $(ASM_FOLDER)/$(basename $@).bin
	@echo "=== Generating testbench ==="
	python3 scripts/gen_tb.py $(ASM_FOLDER)/$(basename $@).bin $(TB_FOLDER)/tb_operations.v
	@echo "=== Compiling CPU with program ==="
	iverilog -g2005 -o $(TB_FOLDER)/tb_operations $(TB_FOLDER)/tb_operations.v $(SRC_FILES)
	@echo "=== Running simulation ==="
	cd $(TB_FOLDER) && vvp tb_operations
	@echo "=== Waveform generated: $(TB_FOLDER)/tb_operations.vcd ==="

# Standard testbench compilation and simulation
compile: $(TB_FOLDER)/$(TB_MODULE) $(SRC_FILES)
	iverilog -g2005 -o $(TB_FOLDER)/$(EXECUTABLE) $(TB_FOLDER)/$(TB_MODULE) $(SRC_FILES)

simulate: compile
	cd $(TB_FOLDER) && vvp $(EXECUTABLE)

clean:
	rm -f $(TB_FOLDER)/$(EXECUTABLE) $(TB_FOLDER)/*.vcd $(TB_FOLDER)/tb_operations
	rm -f $(ASM_FOLDER)/*.bin
	$(MAKE) -C $(ASM_FOLDER) clean

view:
	gtkwave $(TB_FOLDER)/$(VCD_OUTPUT) &

view-asm:
	gtkwave $(TB_FOLDER)/tb_operations.vcd &

.PHONY: all compile simulate clean view view-asm
