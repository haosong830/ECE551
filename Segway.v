module Segway(clk,RST_n,LED,INERT_SS_n,INERT_MOSI,
              INERT_SCLK,INERT_MISO,A2D_SS_n,A2D_MOSI,A2D_SCLK,
			  A2D_MISO,PWM_rev_rght,PWM_frwrd_rght,PWM_rev_lft,
			  PWM_frwrd_lft,piezo_n,piezo,INT,RX);
			  
  input clk,RST_n;
  input INERT_MISO;						// Serial in from inertial sensor
  input A2D_MISO;						// Serial in from A2D
  input INT;							// Interrupt from inertial indicating data ready
  input RX;								// UART input from BLE module

  
  output [7:0] LED;						// These are the 8 LEDs on the DE0, your choice what to do
  output A2D_SS_n, INERT_SS_n;			// Slave selects to A2D and inertial sensor
  output A2D_MOSI, INERT_MOSI;			// MOSI signals to A2D and inertial sensor
  output A2D_SCLK, INERT_SCLK;			// SCLK signals to A2D and inertial sensor
  output PWM_rev_rght, PWM_frwrd_rght;  // right motor speed controls
  output PWM_rev_lft, PWM_frwrd_lft;	// left motor speed controls
  output piezo_n,piezo;					// diff drive to piezo for sound
  ////////////////////////////////////////////////////////////////////////
  // fast_sim is asserted to speed up fullchip simulations.  Should be //
  // passed to both balance_cntrl and to steer_en.  Should be set to  //
  // 0 when we map to the DE0-Nano.                                  //
  ////////////////////////////////////////////////////////////////////
  localparam fast_sim = 1;	// asserted to speed up simulations. 

  ///////////////////////////////////////////////////////////
  ////// Internal interconnecting sigals defined here //////
  /////////////////////////////////////////////////////////
  wire rst_n;                           // internal global reset that goes to all units
  wire [11:0] lft_ld;
  wire [11:0] rght_ld;
  wire moving;
  wire ovr_spd;
  wire batt_low;
  wire [10:0] lft_spd;
  wire [10:0] rght_spd;
  wire lft_rev;
  wire rght_rev;
  wire rider_off;
  wire pwr_up;
  wire vld;
  wire [15:0] ptch;
  wire [11:0] ld_cell_diff;
  wire en_steer;
  wire [11:0] batt;
	
  
  // You will need to declare a bunch more interanl signals to hook up everything
  
  ////////////////////////////////////
   
  
  ///////////////////////////////////////////////////////
  // How you arrange the hierarchy of the top level is up to you.
  //sim:/Segway_tb/ld_cell_lft

  // You could make a level of hierarchy called digital core
  // as shown in the block diagram in the spec.
  //
  // Or you could just instantiate all the components of the Segway
  // flat.
  //
  // Just for reference all the needed blocks (in no particular order) would be:
  //   Auth_blk
  //   inert_intf
  //   balance_cntrl
  //   steer_en
  //   mtr_drv
  //   A2D_intf
  //   piezo
  //////////////////////////////////////////////////////
  //assign batt_low = (batt < 12'h800);
  Auth_blk auth (.RX(RX), .rider_off(rider_off), .pwr_up(pwr_up), .clk(clk), .rst_n(rst_n));
  inert_intf inert(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch(ptch), .SS_n(INERT_SS_n), .SCLK(INERT_SCLK), .MOSI(INERT_MOSI), .MISO(INERT_MISO), .INT(INT));
  balance_cntrl #(fast_sim) blctrl (.clk(clk), .rst_n(rst_n), .ptch(ptch), .ld_cell_diff(ld_cell_diff), .lft_spd(lft_spd), .rght_spd(rght_spd), 
 	.lft_rev(lft_rev), .rght_rev(rght_rev), .rider_off(rider_off), .en_steer(en_steer), .pwr_up(pwr_up), .too_fast(ovr_spd), .vld(vld));
  steer_en #(fast_sim) steer (.clk(clk), .rst_n(rst_n), .en_steer(en_steer), .rider_off(rider_off), .lft_ld(lft_ld), .rght_ld(rght_ld), .ld_cell_diff(ld_cell_diff));
  mtr_drv mtr(.clk(clk), .rst_n(rst_n), .lft_spd(lft_spd), .lft_rev(lft_rev), .PWM_rev_rght(PWM_rev_rght), .PWM_rev_lft(PWM_rev_lft), .PWM_frwrd_lft(PWM_frwrd_lft), .PWM_frwrd_rght(PWM_frwrd_rght), .rght_spd(rght_spd), .rght_rev(rght_rev));
  A2D_intf A2D(.clk(clk), .rst_n(rst_n), .nxt(vld), .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt), .SS_n(A2D_SS_n), .SCLK(A2D_SCLK), .MOSI(A2D_MOSI), .MISO(A2D_MISO));
  //piezo Piezo(.clk(clk), .rst_n(rst_n), .batt_low(batt_low), .ovr_spd(ovr_spd), .en_steer(en_steer), .piezo(piezo), .piezo_n(piezo_n), .norm_mode(en_steer));

  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////  
  reset_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
  
endmodule
