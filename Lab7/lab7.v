`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  //uart 
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 3'b100, S_MAIN_READ = 3'b001,
                 S_MAIN_CALC = 3'b010, S_MAIN_REPLY = 3'b011;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam REPLY_LEN  = 169;
// declare system variables
wire print_done, print_enable;
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [2:0]  P, P_next;
reg  [10:0] user_addr;
reg  [7:0]  user_data;
reg add, addr;
reg [1:0] Q, Q_next;

reg [7:0] matA[0:3][0:3], matB[0:3][0:3];
reg [17:0] matC[0:3][0:3];
reg [17:0] subresult[0:3];
reg delay;
reg [3:0] rx;
reg [2:0] cx;
reg [1:0] ry, cy;
reg [8:0] send_counter;
reg [7:0] data[0:REPLY_LEN-1];
reg [0:REPLY_LEN*8-1] msg = {"\015\012The matrix multiplication result is:\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012", 8'h0 };

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;
integer i, j;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;


assign usr_led = P;
 

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);


//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_READ) || (P == S_MAIN_INIT); // Enable the SRAM block.
assign sram_addr = user_addr;
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // send an address to the SRAM 
      if (btn_pressed[1] == 1) P_next = S_MAIN_READ;
      else P_next = S_MAIN_INIT;
    S_MAIN_READ: // fetch the sample from the SRAM
      if (rx[3]) P_next = S_MAIN_CALC;
      else P_next = S_MAIN_READ;
    S_MAIN_CALC:
      if (cx[2]) P_next = S_MAIN_REPLY;
      else P_next = S_MAIN_CALC;
    S_MAIN_REPLY: // wait for a button click
      if (print_done == 1) P_next = S_MAIN_INIT;///test
      else P_next = S_MAIN_REPLY;
  endcase
end

// End of the main controller
// ------------------------------------------------------------------------


///User address logic

always@(posedge clk) begin
    if(~reset_n) begin
       rx <= 0;
       ry <= 0;
       delay <= 0;
       user_addr <= 0; 
    end
    if(P == S_MAIN_READ) begin
        if(~delay) begin
            //user_addr <= user_addr + 1;
            delay <= 1;
        end else if(~rx[3]) begin
            if(~rx[2]) begin
                matA[ry][rx[1:0]] <= data_out;
            end
            else begin
                matB[ry][rx[1:0]] <= data_out;
            end
            if(ry == 2'b11) rx <= rx + 1;
            ry <= ry + 1;
        end
        user_addr <= user_addr + 1;
    end
end


//CALCULATE LOGIC
always @(posedge clk) begin
     if (~reset_n) begin
        cx <= 0;
        cy <= 0;
        add <= 0;
    end
    else if(P ==  S_MAIN_CALC) begin
        if(~cx[2]) begin
            if(add == 0) begin
                subresult[0] <= matA[cx][0] * matB[0][cy];
                subresult[1] <= matA[cx][1] * matB[1][cy];
                subresult[2] <= matA[cx][2] * matB[2][cy];
                subresult[3] <= matA[cx][3] * matB[3][cy];
                add <= 1;
            end
            else if(add == 1) begin
                matC[cx][cy] <= subresult[0]+subresult[1]+subresult[2]+subresult[3];
                add <= 0;
                cy <= cy + 1;
                if(cy == 2'b11) cx <= cx + 1;
            end
        end
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        for (i = 0; i < REPLY_LEN; i = i + 1)   data[i] = msg[i*8 +: 8];
    end
    else if (P == S_MAIN_REPLY) begin
        
        for(i = 0; i < 4; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                data[42 + i*32 + j*7]   <= matC[i][j][16] + "0";
                data[42 + i*32 + j*7+1] <= ((matC[i][j][15:12] > 9) ? "7" : "0") + matC[i][j][15:12];
                data[42 + i*32 + j*7+2] <= ((matC[i][j][11: 8] > 9) ? "7" : "0") + matC[i][j][11: 8];
                data[42 + i*32 + j*7+3] <= ((matC[i][j][7 : 4] > 9) ? "7" : "0") + matC[i][j][7 : 4];
                data[42 + i*32 + j*7+4] <= ((matC[i][j][3 : 0] > 9) ? "7" : "0") + matC[i][j][3 : 0];
            end
        end
    end
end

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT ||
                  (print_enable));
// UART send_counter control circuit
always @(posedge clk) begin
    if(P_next == S_MAIN_INIT)
        send_counter <= 0;
    else
        send_counter <= send_counter + (Q_next == S_UART_INCR);
end

assign print_enable = (P == S_MAIN_CALC && P_next == S_MAIN_REPLY);
assign print_done = (tx_byte == 8'h0);
assign tx_byte  = data[send_counter];
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

endmodule


