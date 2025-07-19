`timescale 1ns/1ps

module alu_tb;

    //INPUTS
    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] op;
    reg rst;
    wire [7:0] res;
    wire c_out;
    wire z_flag;
    wire ovf;

    alu utt(
        .a(a),
        .b(b),
        .op(op),
        .rst(rst),
        .res(res),
        .c_out(c_out),
        .zero(z_flag),
        .ovf(ovf)
    );

    task check_result;
        input [7:0] expected;
        input [255:0] msg;
        begin
            #5;
            if(res == expected)
                $display("[PASS] %s => res: %d", msg, res);
            else
                $display("[FAIL] %s => res: %d (expected %d)", msg, res, expected); 
        end
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        //Resetting setup
        rst = 1;
        a = 8'd0;
        b = 8'd0;
        op = 3'b000;
        #10;
        rst = 0;

        //Testin AND
        a = 8'b11001100; b = 8'b10101010; op = 3'b000;
        check_result(8'b10001000, "AND test");

        // OR
        a = 8'b11001100; b = 8'b10101010; op = 3'b001;
        check_result(8'b11101110, "OR test");

        // XOR
        a = 8'b11001100; b = 8'b10101010; op = 3'b010;
        check_result(8'b01100110, "XOR test");

        // NOT
        a = 8'b00001111; b = 8'b00000000; op = 3'b011;
        check_result(~8'b00001111, "NOT test");

        // ADD with no carry
        a = 8'd50; b = 8'd20; op = 3'b100;
        check_result(8'd70, "ADD no carry");

        // ADD with overflow
        a = 8'd200; b = 8'd100; op = 3'b100;
        check_result(8'd44, "ADD overflow");

        // SUB
        a = 8'd100; b = 8'd40; op = 3'b101;
        check_result(8'd60, "SUB test");

        // INC
        a = 8'd99; b = 8'd0; op = 3'b110;
        check_result(8'd100, "INC test");

        // DEC
        a = 8'd5; b = 8'd0; op = 3'b111;
        check_result(8'd4, "DEC test");

        $display("All Tests Completed");
        $finish;
    end
endmodule