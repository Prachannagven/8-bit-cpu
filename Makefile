# 8-bit CPU Project Makefile
# Usage: make TB=alu_tb simulate (default: decoder_tb)

TB ?= decoder_tb

TB_MODULE       = $(TB).v
EXECUTABLE      = $(TB)
VCD_OUTPUT      = $(TB).vcd

TB_FOLDER       = ./testbenches
SRC_FOLDER      = ./src

# All Verilog source files
SRC_FILES       = $(wildcard $(SRC_FOLDER)/*.v)

all: simulate

compile: $(TB_FOLDER)/$(TB_MODULE) $(SRC_FILES)
	iverilog -g2005 -o $(TB_FOLDER)/$(EXECUTABLE) $(TB_FOLDER)/$(TB_MODULE) $(SRC_FILES)

simulate: compile
	cd $(TB_FOLDER) && vvp $(EXECUTABLE)

clean:
	rm -f $(TB_FOLDER)/$(EXECUTABLE) $(TB_FOLDER)/*.vcd

view:
	gtkwave $(TB_FOLDER)/$(VCD_OUTPUT) &

.PHONY: all compile simulate clean view
