module Piezo(clk, rst_n, norm_mode, ovr_spd, batt_low, piezo, piezo_n);

input clk, rst_n;
input logic norm_mode, ovr_spd, batt_low;
output logic piezo, piezo_n;
logic [26:0]time_cnt;//counter used to wait 0.01 seconds
logic piezo_norm, piezo_batt, piezo_ovr;// 


//50MHZ counter, bit13 change at 3051Hz, bit14 change at 1525H. bit15 change at 762Hz, bit26 change every 2.68 sec, bit24 change every 0.67 sec
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		time_cnt <= 0;
	else
		time_cnt <= time_cnt + 1;

//n_mode duty cycle
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		piezo_norm <= 0;
	else if(norm_mode && time_cnt[16] && time_cnt[25] && time_cnt[24] && time_cnt[23] && time_cnt[22])
		piezo_norm <= 1;
	else 
		piezo_norm <= 0;

//o_mode duty cycle
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		piezo_ovr <= 0;
	else if(ovr_spd && time_cnt[13] && !time_cnt[24])
		piezo_ovr <= 1;
	else 
		piezo_ovr <= 0;
		
//l_mode duty cycle
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		piezo_batt <= 0;
	else if(batt_low && time_cnt[15] && time_cnt[24])
		piezo_batt <= 1;
	else 
		piezo_batt <= 0;

assign piezo = piezo_norm | piezo_ovr | piezo_batt;
assign piezo_n = ~piezo; 


endmodule 