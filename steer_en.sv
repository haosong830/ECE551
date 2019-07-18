module steer_en(clk,rst_n,en_steer,rider_off,lft_ld,rght_ld,ld_cell_diff);

  input clk;				// 50MHz clock
	input rst_n;				// Active low asynch reset
	input [11:0] lft_ld;
	input [11:0] rght_ld;
	

  /////////////////////////////////////////////////////////////////////////////
  // HEY BUDDY...you are a moron.  sum_gt_min would simply be ~sum_lt_min. Why
  // have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's wieght is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

	output logic en_steer;	// enables steering (goes to balance_cntrl)
	output logic rider_off;	// pulses high for one clock on transition back to initial state
	output [11:0] ld_cell_diff; // the difference between speed of right and left cell.
	//local parameters
	localparam MIN_RIDER_WEIGHT	 = 12'h200;

	//internal signals and parameters:
	logic sum_gt_min;// asserted when left and right load cells together exceed min rider weight
	logic diff_gt_15_16; // indicator of whether left and right difference is larger than 15/16.
	logic diff_gt_1_4; // indicator of whetehr left and right difference is larger than 15/16.
  logic clr_tmr;		// clears the 1.3sec timer
	logic tmr_full;// asserted when timer reaches 1.3 sec
	logic [26:0] timer;
	parameter fast_sim = 0; // the indicator to indicate whether timer can be reduced to 14 bits.
  // You fill out the rest...use good SM coding practices ///
	typedef enum logic [1:0] {IDLE, WAIT, STEER} state_t;
		state_t state, nextState;
  
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			timer <= 26'h0000000;
		else if(clr_tmr)
			timer <= 26'h0000000;
		else
			timer <= timer + 1;
	end
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nextState;
	end

	assign sum_gt_min = ((lft_ld + rght_ld) >= MIN_RIDER_WEIGHT);
	assign diff_gt_15_16 = (lft_ld - rght_ld < 0) ? -(lft_ld-rght_ld) > 15*(lft_ld+ rght_ld)/16 : (lft_ld-rght_ld) > 15*(lft_ld+ rght_ld)/16;
	assign diff_gt_1_4 = (lft_ld - rght_ld < 0) ? -(lft_ld - rght_ld) < (lft_ld + rght_ld)/4 : (lft_ld - rght_ld) < (lft_ld + rght_ld)/4;
	assign tmr_full = (fast_sim)? &timer[14:0]: &timer;
	assign ld_cell_diff = lft_ld - rght_ld;
	//the logic for state machine:
	always_comb begin
		clr_tmr = 0;
		en_steer = 0;
		rider_off = 0;
		nextState = IDLE;
		unique case(state)
			IDLE: 
				if(sum_gt_min) begin
					nextState = WAIT;
					clr_tmr = 1;
					end
			WAIT: begin 
				if(!sum_gt_min) begin
					nextState = IDLE;
					rider_off = 1;
				end
				else if(diff_gt_1_4) begin
					nextState = WAIT;
					clr_tmr = 1;
				end
				else if(tmr_full)
						nextState = STEER;
				else
						nextState = WAIT;
			end
			STEER: begin
				en_steer = 1;
				if(!sum_gt_min) begin
					nextState = IDLE;
					rider_off = 1;
				end
				else if(diff_gt_15_16) begin
					clr_tmr = 1;
					nextState = WAIT;
				end
				else
					nextState = STEER;
			end
			default:
				nextState = IDLE;
		endcase
	end
endmodule
