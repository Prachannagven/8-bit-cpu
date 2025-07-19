#include <stdio.h>
#include "isa.h"

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s input.asm output.bin\n", argv[0]);
        return 1;
    }
    return assemble(argv[1], argv[2]);
}