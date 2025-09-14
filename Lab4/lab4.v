`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

//assign usr_led = usr_btn;

reg[16:0] clk_delay;
reg o_clk;

always@(posedge clk)begin
    clk_delay <= clk_delay + 1;
    if(clk_delay == 0) o_clk = ~o_clk;
end

// regs for divider and button control
reg[3:0] btn_input;         // reg for usr_btn
reg[3:0] led_output;        // reg for usr_led
reg[3:0] counter;           // reg for counter
reg d1, d2;                 // shift register for posedge trigger button
reg[2:0] pwm;               // reg for pwm

assign usr_led = led_output;


always@(posedge o_clk)begin
    if(~reset_n)begin
        counter <= 4'h0;
        pwm <= 3'o4;
        d1 <= 0;
        d2 <= 0;
    end
    else begin
    btn_input = usr_btn;        // get button input
    d1 <= |(btn_input);         // write into d1
    d2 <= d1;                   // d2
    if(d1 && ~d2)begin          // d1, d2 = 1, 0 represents to posedge trigger
        case(btn_input)         // parsing button input
            4'b0001: begin      // negative number compare
                if(~counter[3])begin                    // + 
                    counter <= counter - 1;
                end
                else if(counter[2:0] > 3'b000) begin    // -
                    counter <= counter - 1;
                end
            end
            4'b0010: if(counter < 7 || counter[3])  counter <= counter + 1;
            4'b0100: if(pwm > 0) pwm <= pwm - 1;
            4'b1000: if(pwm < 4) pwm <= pwm + 1;
            default:;
        endcase
    end
    // led_output <= counter;
    end
end

reg[7:0] pwm_counter;           // counter for pwm
reg[7:0] pwm_const;             // const for pwm, changing with pwm register

always@(posedge clk)begin
   case(pwm) 
        3'b000: pwm_const = 13;     // ~~ 0.05 * 255
        3'b001: pwm_const = 64;     // ~~ 0.25 * 255
        3'b010: pwm_const = 128;    // ~~ 0.50 * 255
        3'b011: pwm_const = 191;    // ~~ 0.75 * 255
        3'b100: pwm_const = 255;    // ~~ 1.00 * 255
        default: pwm_const = 0;     // for the case shouldn't exist, turn off the led
    endcase
    pwm_counter <= pwm_counter + 1;
    led_output <= (pwm_counter < pwm_const) ? counter : 4'b0000;
end

endmodule