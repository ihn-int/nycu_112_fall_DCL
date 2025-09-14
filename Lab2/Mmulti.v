`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/22 19:31:59
// Design Name: 
// Module Name: Mmulti
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


module mmult(
    input clk , // Clock
    input reset_n , // Reset signal (negative
    input enable, // Activation signal for matrix
                 // multiplication (tells the circuit
                 // that A and B are ready for
    input [0:9*8-1] A_mat , // A
    input [0:9*8-1] B_mat , // B
    output valid, // Signals that the output is valid  to read.
    output reg [0:9*17-1] C_mat // The result of A x
    );
    
    reg[0:2] count;
    reg[0:7] A[0:2][0:2];
    reg[0:7] B[0:2][0:2];
    reg[0:16] C[0:2][0:2];
    assign valid = (count == 3'b100);
    always@(posedge clk)begin
        if(!reset_n)begin
            C_mat <= 0;
            count = 2'b00;
            {A[0][0], A[0][1], A[0][2], A[1][0], A[1][1], A[1][2], A[2][0], A[2][1], A[2][2] } = A_mat;
            {B[0][0], B[0][1], B[0][2], B[1][0], B[1][1], B[1][2], B[2][0], B[2][1], B[2][2] } = B_mat;
            {C[0][0], C[0][1], C[0][2], C[1][0], C[1][1], C[1][2], C[2][0], C[2][1], C[2][2] } = 0;
        end
        else if (enable) begin
            case(count)
                3'b000:begin
                    C[0][0] <= A[0][0] * B[0][0] + A[0][1] * B[1][0] + A[0][2] * B[2][0];
                    C[0][1] <= A[0][0] * B[0][1] + A[0][1] * B[1][1] + A[0][2] * B[2][1];
                    C[0][2] <= A[0][0] * B[0][2] + A[0][1] * B[1][2] + A[0][2] * B[2][2];
                end
                3'b001:begin
                    C[1][0] <= A[1][0] * B[0][0] + A[1][1] * B[1][0] + A[1][2] * B[2][0];
                    C[1][1] <= A[1][0] * B[0][1] + A[1][1] * B[1][1] + A[1][2] * B[2][1];
                    C[1][2] <= A[1][0] * B[0][2] + A[1][1] * B[1][2] + A[1][2] * B[2][2];
                end
                3'b010:begin
                    C[2][0] <= A[2][0] * B[0][0] + A[2][1] * B[1][0] + A[2][2] * B[2][0];
                    C[2][1] <= A[2][0] * B[0][1] + A[2][1] * B[1][1] + A[2][2] * B[2][1];
                    C[2][2] <= A[2][0] * B[0][2] + A[2][1] * B[1][2] + A[2][2] * B[2][2];
                end
            endcase
            C_mat <= {C[0][0], C[0][1], C[0][2], C[1][0], C[1][1], C[1][2], C[2][0], C[2][1], C[2][2]};
            if(count != 3'b100) count <= count + 1;
        end
    end
    
endmodule
