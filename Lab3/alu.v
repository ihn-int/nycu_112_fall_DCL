`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/10 00:16:59
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input[7:0] accum,
    input[7:0] data,
    input[2:0] opcode,
    output[7:0] alu_out,
    output zero,
    input clk,
    input reset
    );
    
    reg[7:0] a, b, out, ma, mb;
    reg[15:0] m;
    assign alu_out = out;
    assign zero = (accum == {8{1'b0}});
    always@(posedge clk)begin
        if(reset)begin
            out <= 0;
            a <= 0;
            b <= 0;
            ma <= 0;
            mb <= 0;
            m <= 0;
        end
        
        a <= accum;
        b <= data;
        ma = { {4{a[3]}},  a[3:0]};
        mb = { {4{b[3]}},  b[3:0]};
        
        case(opcode)
            3'b000: out <= a;
            3'b001: out <= a + b;
            3'b010: out <= a - b;
            3'b011: out <= a & b;
            3'b100: out <= a ^ b;
            3'b101: out <= (a[7] == 1'b0)?a: ~a + 1;
            3'b110: out <= ma * mb;
            3'b111: out <= b;
            default: out <= 0;
        endcase
    end
    
    
    
    
    
endmodule
