//module PWM11(input clk, rst_n, [10:0] duty, output logic PWM_sig);
//
//logic [10:0] cnt;
//  
//always_ff @(posedge clk, negedge rst_n) begin
//  if (!rst_n)
//    cnt <= 11'h000;			
//  else				
//    cnt <= cnt + 1;
//end
//   
//always_ff @(posedge clk, negedge rst_n) begin
//   if(!rst_n)
//     PWM_sig <= 0;
//   else if(cnt == 11'h000)
//     PWM_sig <= 1;
//   else if(cnt >= duty)
//     PWM_sig <= 0;
//end
//endmodule
     		
/* module PWM11(clk, rst_n, duty, PWM_sig);

input clk, rst_n;
input unsigned [10:0] duty;

output PWM_sig;

wire set, reset;
reg unsigned [10:0] cnt;

sr_flipflop pwm_flop(.q(PWM_sig), .s(set), .r(reset), .rst_n(rst_n), .clk(clk));

assign reset = (cnt >= duty) ? 1 : 0;
assign set = ~|cnt;


always @(posedge clk, negedge rst_n)
  if(!rst_n)
    cnt <= 0;
  else
    cnt <= cnt + 1;

endmodule */
module PWM11(PWM_sig, duty, clk, rst_n);

input clk, rst_n;
input [10:0] duty;
output reg PWM_sig;

reg[10:0] count;
wire set, reset;
reg Q;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		count <= 11'h000;
	else 
		count <= count + 1'b1;
end

always@(posedge clk) begin
	if(reset)
		Q = 1'b0;
	else if(set)
		Q = 1'b1;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		PWM_sig <= 10'h000;
	else
		PWM_sig <= Q;
end

assign set = (count < duty);
assign reset = (count >= duty);

endmodule
