module mtr_drv(input clk,rst_n,lft_rev,rght_rev,[10:0]lft_spd,[10:0]rght_spd, output logic PWM_rev_lft,PWM_frwrd_lft,PWM_rev_rght,PWM_frwrd_rght);
  logic PWM_sig_left; //this signal is used as an internal signal to generate the value of PWM_rev_lft and PWM_frwrd_lft. 
  logic PWM_sig_right;
    PWM11 pwm_left(.clk(clk), .rst_n(rst_n), .duty(lft_spd), .PWM_sig(PWM_sig_left));
    PWM11 pwm_right(.clk(clk), .rst_n(rst_n) ,.duty(rght_spd), .PWM_sig(PWM_sig_right));
  assign PWM_rev_lft = (lft_rev & PWM_sig_left);
  assign PWM_rev_rght = (rght_rev & PWM_sig_right);
  assign PWM_frwrd_lft = (~lft_rev & PWM_sig_left);
  assign PWM_frwrd_rght = (~rght_rev & PWM_sig_right);
endmodule
        
      
