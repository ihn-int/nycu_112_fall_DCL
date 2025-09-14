`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;



//========================================================================
// dividor
reg btn_clk;
reg lcd_clk;
reg[16:0] btn_clk_cnt;
reg[26:0] lcd_clk_cnt;

always@(posedge clk) begin
    btn_clk_cnt <= btn_clk_cnt + 1;
    lcd_clk_cnt <= lcd_clk_cnt + 1;
    if(btn_clk_cnt == 0) btn_clk = ~btn_clk;
    if(lcd_clk_cnt == 0) lcd_clk = 1;
    else lcd_clk = 0;
end
//========================================================================

//========================================================================
// calculating fibo numbers
reg[15:0] fibos[1:25];
reg[4:0] fib_cnt = 1;
reg enable = 0;
always@(posedge clk) begin
    
    if(fib_cnt < 3) fibos[fib_cnt] = fib_cnt - 1;
    else fibos[fib_cnt] = fibos[fib_cnt - 1] + fibos[fib_cnt - 2];
    if(fib_cnt < 25) fib_cnt <= fib_cnt + 1;
    else enable = 1;
    
end
//========================================================================


//========================================================================
// button instance
wire btn_level, btn_pressed;
reg prev_btn_level;

debounce btn_db0(
  .clk(btn_clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
//========================================================================

//========================================================================

//========================================================================
// getting button value
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

//========================================================================

//========================================================================
// state machine
reg[2:0] ps = 1, ns = 1;

always@(negedge clk) begin
    ps <= ns;
end

//========================================================================
// computing message
reg [127:0] row_A = "                "; // Initialize the text of the first row. 
reg [127:0] row_B = "                "; // Initialize the text of the second row.
reg[127:0] to_write = "Fibo #XX is YYYY";
reg[5:0] dis_cnt = 1;
reg pre_dir = 1;
reg direct = 1;

always@(posedge btn_pressed) begin
    direct <= ~direct;
end

always @(posedge clk) begin

        
    if (~reset_n) begin
    // Initialize the text when the user hit the reset button
        row_A = "                ";
        row_B = "                ";
    end else if(enable) begin
        
        case(ps)
            3'b000: begin // handlig btn trigger
                case({pre_dir, direct})
                    2'b00:begin         // scrolling down
                        dis_cnt <= dis_cnt + 24;
                    end
                    2'b01: begin        // trigger scrolling up
                        dis_cnt <= dis_cnt + 2;
                    end
                    2'b10: begin        // triiger scrolling down
                        dis_cnt <= dis_cnt + 23;
                    end
                    2'b11: begin        // scrolling up
                        dis_cnt <= dis_cnt + 1;
                    end
                endcase
                ns <= 1;
            end
            3'b001: begin // calculate number
                if(dis_cnt > 25) dis_cnt <= dis_cnt - 25;
                
                ns <= 2;
            end
            3'b010: begin // writing fibonacci numbers
                to_write[79:72] <= dis_cnt[4] + "0";
                if(dis_cnt[3:0] > 4'h9) to_write[71:64] <= dis_cnt[3:0] - 4'hA + "A";
                else to_write[71:64] = dis_cnt[3:0] + "0";
    
                if(fibos[dis_cnt][15:12] > 4'h9) to_write[31:24] <= fibos[dis_cnt][15:12] - 4'hA + "A";
                else to_write[31:24] <= fibos[dis_cnt][15:12] + "0";

                if(fibos[dis_cnt][11:8] > 4'h9) to_write[23:16] <= fibos[dis_cnt][11:8] - 4'hA + "A";
                else to_write[23:16] <= fibos[dis_cnt][11:8] + "0";
    
                if(fibos[dis_cnt][7:4] > 4'h9) to_write[15:8] = fibos[dis_cnt][7:4] - 4'hA + "A";
                else to_write[15:8] <= fibos[dis_cnt][7:4] + "0";
    
                if(fibos[dis_cnt][3:0] > 4'h9) to_write[7:0] = fibos[dis_cnt][3:0] - 4'hA + "A";
                else to_write[7:0] <= fibos[dis_cnt][3:0] + "0";
                
                ns <= 3;
            end
            3'b011: begin // displaying message
                if (direct) begin
                    row_A <= row_B;
                    row_B <= to_write;
                end else begin
                    row_A <= to_write;
                    row_B <= row_A;
                end
                
                pre_dir <= direct;
                ns <= 4;
            end
            3'b100: begin // idle state
                if(lcd_clk) ns <= 0;
                else ns <= 4;
            end
        endcase
         
    end
end
//========================================================================

//========================================================================
// lcd 1602 instance
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
//========================================================================


endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    assign btn_output = btn_input;
endmodule