`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/03 10:56:28
// Design Name: 
// Module Name: lab9
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


module lab9(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
  );

localparam [2:0] S_MAIN_INIT = 3'b001,
                 S_MAIN_CALC = 3'b010,
			     S_MAIN_CHECK = 3'b101,
			     S_MAIN_DELAY = 3'b011 ,
                 S_MAIN_SHOW = 3'b100;
localparam PARALLEL_NUM = 10;
// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg [2:0] P, P_next;
wire [63:0] number;
reg [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;
reg [127:0] row_A;
reg [127:0] row_B;// = "start the crack!";
reg [63:0] ans;
wire [55:0] timer;
wire number_incr, timer_incr;
reg [31:0] timer_bcd;
reg [19:0] sub_timer;

reg [PARALLEL_NUM-1:0] load_p;
wire [PARALLEL_NUM-1:0] ready_p;
wire [127:0] hash_out[PARALLEL_NUM-1:0];
wire [63:0] data_in[PARALLEL_NUM-1:0];


integer i;
LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
BCD_counter timeBCD_counter(
	.clk(clk),
	.rst(~reset_n),
	.increase(timer_incr),
	.result(timer)
);
BCD_counter numberBCD_counter(
	.clk(clk),
	.rst(~reset_n),
	.increase(number_incr),
	.result(number[63:8])
);
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

md5 md5_0(.clk(clk),.reset_n(reset_n),.load(load_p[0]),.ready(ready_p[0]),.data_in(data_in[0]),.data_out(hash_out[0]));
md5 md5_1(.clk(clk),.reset_n(reset_n),.load(load_p[1]),.ready(ready_p[1]),.data_in(data_in[1]),.data_out(hash_out[1]));
md5 md5_2(.clk(clk),.reset_n(reset_n),.load(load_p[2]),.ready(ready_p[2]),.data_in(data_in[2]),.data_out(hash_out[2]));
md5 md5_3(.clk(clk),.reset_n(reset_n),.load(load_p[3]),.ready(ready_p[3]),.data_in(data_in[3]),.data_out(hash_out[3]));
md5 md5_4(.clk(clk),.reset_n(reset_n),.load(load_p[4]),.ready(ready_p[4]),.data_in(data_in[4]),.data_out(hash_out[4]));
md5 md5_5(.clk(clk),.reset_n(reset_n),.load(load_p[5]),.ready(ready_p[5]),.data_in(data_in[5]),.data_out(hash_out[5]));
md5 md5_6(.clk(clk),.reset_n(reset_n),.load(load_p[6]),.ready(ready_p[6]),.data_in(data_in[6]),.data_out(hash_out[6]));
md5 md5_7(.clk(clk),.reset_n(reset_n),.load(load_p[7]),.ready(ready_p[7]),.data_in(data_in[7]),.data_out(hash_out[7]));
md5 md5_8(.clk(clk),.reset_n(reset_n),.load(load_p[8]),.ready(ready_p[8]),.data_in(data_in[8]),.data_out(hash_out[8]));
md5 md5_9(.clk(clk),.reset_n(reset_n),.load(load_p[9]),.ready(ready_p[9]),.data_in(data_in[9]),.data_out(hash_out[9]));

assign data_in[0] =  {number[63: 8], "0"};
assign data_in[1] =  {number[63: 8], "1"};
assign data_in[2] =  {number[63: 8], "2"};
assign data_in[3] =  {number[63: 8], "3"};
assign data_in[4] =  {number[63: 8], "4"};
assign data_in[5] =  {number[63: 8], "5"};
assign data_in[6] =  {number[63: 8], "6"};
assign data_in[7] =  {number[63: 8], "7"};
assign data_in[8] =  {number[63: 8], "8"};
assign data_in[9] =  {number[63: 8], "9"};

assign number_incr = (P == S_MAIN_CHECK);
assign timer_incr = (sub_timer == 100 && P ==S_MAIN_CALC);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;
assign usr_led = P;

//=======================================================
// FSM 
always @(posedge clk) begin
  if (~reset_n)
    P <= S_MAIN_INIT;
  else
    P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT:
      if (btn_pressed == 1) P_next = S_MAIN_CHECK;
      else P_next = S_MAIN_INIT;
    S_MAIN_CALC:
		 if(ready_p)
		 	P_next = S_MAIN_CHECK;
		 else
		 	P_next = S_MAIN_CALC;
	S_MAIN_CHECK:
		if(ans != 0)
			P_next = S_MAIN_DELAY;
		else
			P_next = S_MAIN_CALC;
	S_MAIN_DELAY:
		 P_next = S_MAIN_SHOW;
    S_MAIN_SHOW:
    	 P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_INIT;
  endcase
end
// End of FSM
//=======================================================

//=======================================================
// timer logic
// thr timer of arty is 100MHz, that's 10ns, 100 -> us, 100000-> ms 
always @(posedge clk) begin
	sub_timer <= (sub_timer >= 100000) ? 0 : sub_timer + 1;
end

// end of Timer logic
//=======================================================

//=======================================================
// part of parallel computing
always @(posedge clk) begin
	if (~reset_n)
		ans <= 0;
	else begin
		if(P == S_MAIN_INIT)
			ans <= 0;
		else if(P == S_MAIN_CALC && ready_p)begin
			for(i=0;i<PARALLEL_NUM;i=i+1)
				if(hash_out[i] == passwd_hash)
					ans = data_in[i];
		end
	end
end


always @(posedge clk) begin
  if (~reset_n)
    load_p <= 0;
  else begin
  	if(P == S_MAIN_CHECK)
  		load_p <= 10'b11111_11111;
  	else
  		load_p <= 0;
  end  
end

// end of parallel part
//=======================================================

//=======================================================
// part of lcd function

always @(posedge clk) begin
  	if (~reset_n || P == S_MAIN_INIT) begin
  		row_A <= "Press button3 to";
		row_B <= "start calculate.";
	end
  	else begin
  		if(P == S_MAIN_CALC) begin
  			row_A <= "Calculating...  ";
			row_B <= "Hope it works   ";
  		end
  		else if(P == S_MAIN_SHOW) begin
  			row_A <= {"Passwd: ", ans};
			row_B <= {"Time: ", timer, " ms"};
		end
  	end
end
// end of the LCD function
//=======================================================

endmodule

//=======================================================
// declaration of debounce module
module debounce(input clk, input btn_input, output btn_output);

parameter DEBOUNCE_PERIOD = 2_000_000; /* 20 msec = (100,000,000*0.2) ticks @100MHz */

reg [$clog2(DEBOUNCE_PERIOD):0] counter;

assign btn_output = (counter == DEBOUNCE_PERIOD);

always@(posedge clk) begin
  if (btn_input == 0)
    counter <= 0;
  else
    counter <= counter + (counter != DEBOUNCE_PERIOD);
end

endmodule
//=======================================================