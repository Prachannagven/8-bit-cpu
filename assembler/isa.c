#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "isa.h"

//----- SOME SIMPLE COMMANDS -----//
#define ARG1_IS_A_REG (arg1[0] == 'A' || arg1[0] == 'B' || arg1[0] == 'C' || arg1[0] == 'D')
#define ARG2_IS_A_REG (arg2[0] == 'A' || arg2[0] == 'B' || arg2[0] == 'C' || arg2[0] == 'D')
#define ARG1_IS_ADDRS (arg1[0] == '[' && arg1[1] == '0' && arg1[2] == 'x' && arg1[5] == ']')
#define ARG2_IS_ADDRS (arg2[0] == '[' && arg2[1] == '0' && arg2[2] == 'x' && arg2[5] == ']')
//----- STOP SIMPLE COMMANDS -----//

//-----  DEFINING OPCODES HERE  -----//
const uint8_t MOV_REG_REG = 0x00;       //MOV A, B
const uint8_t MOV_REG_IMM = 0x10;       //MOV A, 0x10
const uint8_t MOV_REG_ADR = 0x20;       //MOV A, [0x40]
const uint8_t MOV_ADR_REG = 0x30;       //MOV [0x40], A
const uint8_t PRNT_HEADER = 0x40;       //PRNT A or PRNT [0x40]
const uint8_t JMP_UNIBBLE = 0x50;       //JMP, JNZ, JZ, JOV
const uint8_t ALU_CMD_AND = 0x80;       //AND A, B
const uint8_t ALU_CMD_OR  = 0x90;       //OR A, B
const uint8_t ALU_CMD_XOR = 0xA0;       //XOR A, B
const uint8_t ALU_CMD_NOT = 0xB0;       //NOT A, B
const uint8_t ALU_CMD_ADD = 0xC0;       //ADD A, B
const uint8_t ALU_CMD_SUB = 0xD0;       //SUB A, B
const uint8_t ALU_CMD_INC = 0xE0;       //INC A, B
const uint8_t ALU_CMD_DEC = 0xF0;       //DEC A, B
const uint8_t HLT         = 0x70;       //HLT
const uint8_t NOP         = 0x6F;       //NOP
const uint8_t WAIT        = 0x7F;       //WAIT
//----- ENDING DEFINING OPCODES -----//

uint16_t LINE_NUM = 1;                  //To allow me to print which line has the error in it

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

        //Skipping if blank line
        if(sscanf(line, "%s %[^,], %s", op, arg1, arg2) < 1){
            LINE_NUM++; 
            continue;
        }

        //Now prepping the byte buffer to load into the machine code file
        uint8_t bytes[3] = {0};
        int len = 0;

        //Now actually figing out which command is being called
        //parsing the move variants
        if(strcmp(op, "MOV") == 0){
            //MOV [ADDR], REG
            if(ARG1_IS_ADDRS){
                uint8_t reg = register_code(arg2[0]);                       //Converting the reg into reg code
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = MOV_ADR_REG | (reg << 2);
                bytes[1] = addr;
                len = 2;
            }
            //MOV REG, [ADDR]
            else if(ARG2_IS_ADDRS){
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
            else if(ARG1_IS_A_REG && ARG2_IS_A_REG){
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
                printf("Invalid MOV command at line %d. Valid Usages: \n \t MOV A, B \n \t MOV A, 0x20 \n \t MOV A, [0x43] \n \t MOV [0x42], A", LINE_NUM);
                break;
            }
        }
        else if (strcmp(op, "PRNT") == 0){
            //PRNT [0x40]
            if(arg1[0] == '[' && arg1[1] == '0' && arg1[2] == 'x' && arg1[5] == ']'){
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = PRNT_HEADER | 0b11 ; 
                bytes[1] = addr;
                len = 2;
            }
            //PRNT A
            else if(ARG1_IS_A_REG){
                uint8_t reg = register_code(arg1[0]);
                bytes[0] = PRNT_HEADER | (reg << 2);
                len = 1;
            }
            else{
                printf("Invalid PRNT command syntax at line %d. Valid usages: \n \t PRNT A \n \t PRNT [0x40] \n", LINE_NUM);
                break;
            }
        }    
        else if ((op[0] == 'J' ) && ARG1_IS_ADDRS){
            //JMP [0x40] (unconditional jump)
            if(strcmp(op, "JMP") == 0){
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = JMP_UNIBBLE | 0x00;
                bytes[1] = addr;
                len = 2;
            }
            //JZ [0x40] (jump if zero flag is set)
            else if(strcmp(op, "JZ") == 0){
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = JMP_UNIBBLE | 0x01;
                bytes[1] = addr;    
                len = 2;       
            }
            //JNZ [0x40] (jump if zero flag is reset)
            else if (strcmp(op,  "JNZ") == 0){
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = JMP_UNIBBLE | 0x02;
                bytes[1] = addr;    
                len = 2;  
            }
            //JOV [0x40] (jump if overflow flag)
            else if (strcmp(op, "JOV") == 0){
                uint8_t addr = (uint8_t) strtol(arg1+1, NULL, 0);
                bytes[0] = JMP_UNIBBLE | 0x03;
                bytes[1] = addr;    
                len = 2;  
            }
            else
            {
                printf("Invalid jump command syntax at line %d. Valid usages: \n \t JMP [0x40] \n \t JZ [0x40]\n \t JNZ [0x40] \n \t JOV [0x40] \n", LINE_NUM);
                break;
            }             
        }
        //---------------ALU Operations----------------------//
        //AND A, B
        else if (strcmp(op, "AND") == 0){
            if(ARG1_IS_A_REG && ARG2_IS_A_REG){
                uint8_t reg1 = register_code(arg1[0]);
                uint8_t reg2 = register_code(arg2[0]);
                bytes[0] = ALU_CMD_AND | (reg1 << 2) | reg2;
                len = 1;
            }
            else{
                printf("Invalid AND syntax at line %d. Valid usage: \n \t AND A, B \n", LINE_NUM);
            }
            
        }
        //OR A, B
        else if (strcmp(op, "OR") == 0){
            if(ARG1_IS_A_REG && ARG2_IS_A_REG){
                uint8_t reg1 = register_code(arg1[0]);
                uint8_t reg2 = register_code(arg2[0]);
                bytes[0] = ALU_CMD_OR | (reg1 << 2) | reg2;
                len = 1;
            }
            else{
                printf("Invalid OR syntax at line %d. Valid usage: \n \t OR A, B \n", LINE_NUM);
            }
            
        }
        //XOR A, B
        else if (strcmp(op, "XOR") == 0){
            if(ARG1_IS_A_REG && ARG2_IS_A_REG){
                uint8_t reg1 = register_code(arg1[0]);
                uint8_t reg2 = register_code(arg2[0]);
                bytes[0] = ALU_CMD_XOR | (reg1 << 2) | reg2;
                len = 1;
            }
            else{
                printf("Invalid XOR syntax at line %d. Valid usage: \n \t XOR A, B \n", LINE_NUM);
            }
            
        }
        //NOT A
        else if (strcmp(op, "NOT") == 0){
            if(ARG1_IS_A_REG && !arg2[0]){
                uint8_t reg1 = register_code(arg1[0]);
                bytes[0] = ALU_CMD_NOT | (reg1 << 2);
                len = 1;
            }
            else{
                printf("Invalid NOT syntax at line %d. Valid usage: \n \t NOT A \n", LINE_NUM);
            }            
        }
        //ADD A, B
        else if (strcmp(op, "ADD") == 0){
            if(ARG1_IS_A_REG && ARG2_IS_A_REG){
                uint8_t reg1 = register_code(arg1[0]);
                uint8_t reg2 = register_code(arg2[0]);
                bytes[0] = ALU_CMD_ADD | (reg1 << 2) | reg2;
                len = 1;
            }
            else{
                printf("Invalid ADD syntax at line %d. Valid usage: \n \t ADD A, B \n", LINE_NUM);
            }
            
        }
        //SUB A, B
        else if (strcmp(op, "SUB") == 0){
            if(ARG1_IS_A_REG && ARG2_IS_A_REG){
                uint8_t reg1 = register_code(arg1[0]);
                uint8_t reg2 = register_code(arg2[0]);
                bytes[0] = ALU_CMD_SUB | (reg1 << 2) | reg2;
                len = 1;
            }
            else{
                printf("Invalid SUB syntax at line %d. Valid usage: \n \t SUB A, B \n", LINE_NUM);
            }
            
        }
        //INC A
        else if (strcmp(op, "INC") == 0){
            if(ARG1_IS_A_REG && !arg2[0]){
                uint8_t reg1 = register_code(arg1[0]);
                bytes[0] = ALU_CMD_INC | (reg1 << 2);
                len = 1;
            }
            else{
                printf("Invalid INC syntax at line %d. Valid usage: \n \t INC A \n", LINE_NUM);
            }            
        }
        //DEC A
        else if (strcmp(op, "DEC") == 0){
            if(ARG1_IS_A_REG && !arg2[0]){
                uint8_t reg1 = register_code(arg1[0]);
                bytes[0] = ALU_CMD_DEC | (reg1 << 2);
                len = 1;
            }
            else{
                printf("Invalid DEC syntax at line %d. Valid usage: \n \t DEC A \n", LINE_NUM);
            }            
        }
        //--------------------------END ALU COMMANDS---------------------------------//
        //HLT
        else if(strcmp(op, "HLT") == 0){
            bytes[0] = HLT;
            len = 1;
            fwrite(bytes, 1, len, fout);
            LINE_NUM ++;
            printf("HLT command detected at line %d. Further lines not being read\n", LINE_NUM);
            break;
        }
        //NOP
        else if(strcmp(op, "NOP") == 0){
            bytes[0] = NOP;
            len = 1;
        }
        //WAIT
        else if(strcmp(op, "WAIT") == 0){
            if((arg1[0] == '0') && (arg1[1] == 'x') && (!arg2)){
                uint16_t delay_amount = (uint16_t) strtol(arg1, NULL, 0);
                bytes[0] = WAIT;
                bytes[1] = (uint8_t) (delay_amount >> 8) & (0x00FF);
                bytes[2] = (uint8_t) (delay_amount) & (0x00FF);
                len = 3;
            }
            else{
                printf("Invalid use of WAIT command at line %d. Valid usage: \n \t WAIT 0x1234", LINE_NUM);
            }

        }
        else{
            printf("Invalid Command Detected. Skipping line %d", LINE_NUM);
        } 
        fwrite(bytes, 1, len, fout);
        LINE_NUM ++;
    }
    printf("Went through the whole file, covered %d lines \n", LINE_NUM);
    fclose(fin);
    fclose(fout);
    return 0;
}