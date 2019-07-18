module balance_cntrl(clk,rst_n,vld,ptch,ld_cell_diff,lft_spd,lft_rev,
                     rght_spd,rght_rev,rider_off, en_steer,pwr_up,too_fast);
								
  input clk,rst_n;
  input vld;						// tells when a new valid inertial reading ready
  input signed [15:0] ptch;			// actual pitch measured
  input signed [11:0] ld_cell_diff;	// lft_ld - rght_ld from steer_en block
  input rider_off;					// High when weight on load cells indicates no rider
  input en_steer;
  input pwr_up;
  output too_fast;
  output [10:0] lft_spd;			// 11-bit unsigned speed at which to run left motor
  output lft_rev;					// direction to run left motor (1==>reverse)
  output [10:0] rght_spd;			// 11-bit unsigned speed at which to run right motor
  output rght_rev;					// direction to run right motor (1==>reverse)
  parameter fast_sim = 0;
  
  ////////////////////////////////////
  // Define needed registers below //
  //////////////////////////////////
  logic signed [14:0] ptch_P_term;
  logic signed [17:0] integrator;
  logic signed [12:0] ptch_D_term;
  logic signed [15:0] lft_torque;
  logic signed [15:0] rght_torque;
  ///////////////////////////////////////////
  // Define needed internal signals below //
  /////////////////////////////////////////
  logic signed [9:0] ptch_err_sat;
  logic signed [17:0] ptch_err_sat_SE;
  logic signed [17:0] sum_intgtr_ptcherr;
  logic signed [9:0] prev_ptch_err;
  logic signed [9:0] tempI;
  logic signed [9:0] ptch_D_diff;
  logic signed [6:0] ptch_D_diff_SE;
  logic signed [15:0] PID_cntrl;
  logic unsigned [15:0] lft_torque_abs;
  logic unsigned [15:0] rght_torque_abs;
  logic signed [15:0] leftSum;
  logic signed [15:0] rightSum; 
  logic compareLeft;
  logic compareRight;
  logic signed [15:0] lft_shaped;
  logic unsigned [15:0] lft_shaped_abs;
  logic signed [15:0] rght_shaped;
  logic unsigned [15:0] rght_shaped_abs;
  logic ov;
  /////////////////////////////////////////////
  // local params for increased flexibility //
  ///////////////////////////////////////////
  localparam P_COEFF = 5'h0E;
  localparam D_COEFF = 6'h14;				// D coefficient in PID control = +20 
  localparam LOW_TORQUE_BAND = 8'h46;	// LOW_TORQUE_BAND = 5*P_COEFF
  localparam GAIN_MULTIPLIER = 6'h0F;	// GAIN_MULTIPLIER = 1 + (MIN_DUTY/LOW_TORQUE_BAND)
  localparam MIN_DUTY = 15'h03D4;		// minimum duty cycle (stiffen motor and get it ready)
  
  //// You fill in the rest ////

//logic for I of PID:

  always_comb begin
    ptch_err_sat = ptch[15] ? (&ptch[15:9] ? ptch[9:0] : 10'b1000000000) : (|ptch[15:9] ? 10'b0111111111 : ptch[9:0]);
    ptch_P_term = ptch_err_sat * ($signed(P_COEFF));
    ptch_err_sat_SE = {{8{ptch_err_sat[9]}},ptch_err_sat};
    sum_intgtr_ptcherr = ptch_err_sat_SE + integrator;
    ov = ((ptch_err_sat_SE[17] == integrator[17]) && (ptch_err_sat_SE[17] !== sum_intgtr_ptcherr[17]));
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      integrator <= 18'h00000;
    else begin
      if(rider_off)
        integrator <= 18'h00000;
			else if(!pwr_up)
				integrator <= 18'h00000;
      else begin
        if(vld && !ov)
   	  integrator <= sum_intgtr_ptcherr;
	else
	  integrator <= integrator;
      end
    end
  end
  //logic for D of PID:
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
      tempI <= 10'h000; 
      prev_ptch_err <= 10'h000;
    end
    else begin
      if(vld) begin
        tempI <= ptch_err_sat;
	prev_ptch_err <= tempI;
      end
    end
  end
  
  assign ptch_D_diff = ptch_err_sat - prev_ptch_err;
  assign ptch_D_diff_SE = (ptch_D_diff[9] && ~&ptch_D_diff[8:6]) ? 7'h40 : (~ptch_D_diff[9] && |ptch_D_diff[8:6]) ? 7'h3F : ptch_D_diff[6:0];
  assign ptch_D_term = ($signed(D_COEFF)) * ptch_D_diff_SE;
  //logic for PID math:
  assign PID_cntrl = (fast_sim) ? {ptch_P_term[14],ptch_P_term} + integrator[17:2] + {{3{ptch_D_term[12]}},ptch_D_term} : {{1{ptch_P_term[14]}},ptch_P_term[14:0]} + {{3{ptch_D_term[12]}},ptch_D_term[12:0]} + {{4{integrator[17]}},integrator[17:6]};
  assign lft_torque = en_steer ? (PID_cntrl - {{7{ld_cell_diff[11]}}, ld_cell_diff[11:3]}) : PID_cntrl;
  assign rght_torque = en_steer ? (PID_cntrl + {{7{ld_cell_diff[11]}}, ld_cell_diff[11:3]}) : PID_cntrl;
  //logic for shaping Torque to form duty:
  assign leftSum = lft_torque[15] ? lft_torque -($signed(MIN_DUTY)) : lft_torque + ($signed(MIN_DUTY));
  assign rightSum = rght_torque[15] ? rght_torque - ($signed(MIN_DUTY)) : rght_torque + ($signed(MIN_DUTY));
  assign lft_torque_abs = lft_torque[15] ? ~lft_torque + 1 : lft_torque;
  assign rght_torque_abs = rght_torque[15] ? -rght_torque : rght_torque;
  assign compareLeft = (lft_torque_abs >= LOW_TORQUE_BAND);
  assign compareRight = (rght_torque_abs >= LOW_TORQUE_BAND);
  assign lft_shaped = compareLeft ? leftSum : lft_torque * ($signed(GAIN_MULTIPLIER));
  assign lft_shaped_abs = lft_shaped[15] ? -lft_shaped : lft_shaped;
  assign lft_spd = (pwr_up) ? ((|lft_shaped_abs[15:11]) ? 11'h7FF : lft_shaped_abs[10:0]) : 11'h000;
  assign lft_rev = lft_shaped[15];
  assign rght_shaped = compareRight ? rightSum : rght_torque * ($signed(GAIN_MULTIPLIER));
  assign rght_shaped_abs = rght_shaped[15] ? -rght_shaped : rght_shaped;
  assign rght_spd = (pwr_up) ? ((|rght_shaped_abs[15:11]) ? 11'h7FF : rght_shaped_abs[10:0]) : 11'h000;
  assign rght_rev = rght_shaped[15];
  assign too_fast = (lft_spd > 1536 || rght_spd > 1536);
endmodule 
