#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "isa.h"

//-----  DEFINING OPCODES HERE  -----//
const uint8_t MOV_REG_REG = 0x00;
const uint8_t MOV_REG_IMM = 0x10;
const uint8_t MOV_REG_ADR = 0x20;
const uint8_t MOV_ADR_REG = 0x30;

//----- ENDING DEFINING OPCODES -----//

uint8_t register_code(char reg){
    switch(reg){
        case 'A': return 0b00;
        case 'B': return 0b01;
        case 'C': return 0b10;
        case 'D': return 0b11;
        default: return 0xFF;
    }
}

int assemble(const char *filename, const char *output){
    //Opening the file I want to assemble and the output file so I can put my characters
    FILE *fin = fopen(filename, "r");
    FILE *fout = fopen(output, "wb");
    
    //Checking for error
    if(!fin || !fout){
        perror("Error opening the file");
        return 1;
    }

    //This is my buffer when reading a line
    char line[MAX_LINE_LEN];

    //Since I want to read the whole file, this loop will allow me to go through until the EOF
    while(fgets(line, sizeof(line), fin)){
        //Temporary buffers for each of the components in the assembly. Not all of them will always be used
        char op[16] = {0};
        char arg1[16] = {0};
        char arg2[16] = {0}; 
        if(sscanf(line, "%s %[^,], %s", op, arg1, arg2) < 1) continue;  //skipping if blank line

        //Now prepping the byte buffer to load into the machine code file
        uint8_t bytes[3] = {0};
        int len = 0;

        //Now actually figing out which command is being called
        //parsing the move variants
        if(strcmp(op, "MOV") == 0){
            //MOV [ADDR], REG
            if(arg1[0] == '['){
                uint8_t reg = register_code(arg2[0]);                       //Converting the reg into reg code
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = MOV_ADR_REG | (reg << 2);
                bytes[1] = addr;
                len = 2;
            }
            //MOV REG, [ADDR]
            else if(arg2[0] == '['){
                uint8_t reg = register_code(arg1[0]);                       //Converting the reg into reg code
                uint8_t addr = (uint8_t) strtol(arg2+1, NULL, 0);
                bytes[0] = MOV_REG_ADR | (reg << 2);
                bytes[1] = addr;
                len = 2;
            }
            //MOV REG, IMM (0x00 format only)
            else if(arg2[0] == '0' && arg2[1] == 'x'){
                uint8_t reg = register_code(arg1[0]);
                uint8_t imm = (uint8_t) strtol(arg2, NULL, 0);
                bytes[0] = MOV_REG_IMM | (reg << 2);
                bytes[1] = imm;
                len = 2;
            }
            //MOV REG, REG
            else if((arg1[0] == 'A' || arg1[0] == 'B' || arg1[0] == 'C' || arg1[0] == 'D') && (arg2[0] == 'A' || arg2[0] == 'B' || arg2[0] == 'C' || arg2[0] == 'D')){
                uint8_t reg1 = register_code(arg1[0]);
                uint8_t reg2 = register_code(arg2[0]);
                if(reg1 == reg2){
                    perror("Moving to and from the same register. Invalid command");
                    break;
                }
                bytes[0] = MOV_REG_REG | (reg1 << 2) | (reg2);
                len = 1;
            }
            else{
                perror("Invalid MOV command. Please check your syntax");
                break;
            }
        }
        fwrite(bytes, 1, len, fout);
    }
    fclose(fin);
    fclose(fout);
    return 0;
}