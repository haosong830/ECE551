module Segway_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
wire RX_TX;
wire PWM_rev_rght, PWM_frwrd_rght, PWM_rev_lft, PWM_frwrd_lft;
wire piezo,piezo_n;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd;					// command host is sending to DUT
reg send_cmd;					// asserted to initiate sending of command
reg signed [13:0] rider_lean;	// forward/backward lean (goes to SegwayModel)
// Perhaps more needed?
logic [11:0] ld_cell_lft;
logic [11:0] ld_cell_rght;
logic [11:0] batt;
logic rst_n;

/////// declare any internal signals needed at this level //////
wire cmd_sent;
// Perhaps more needed?

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM_rev_rght(PWM_rev_rght),
				  .PWM_frwrd_rght(PWM_frwrd_rght),.PWM_rev_lft(PWM_rev_lft),
				  .PWM_frwrd_lft(PWM_frwrd_lft),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
  /*What is this?  You need to build some kind of wrapper around ADC128S.sv or perhaps
  around SPI_ADC128S.sv that mimics the behavior of the A2D converter on the DE0 used
  to read ld_cell_lft, ld_cell_rght and battery*/
A2D_converter A2D_conv(.clk(clk), .rst_n(rst_n), .SS_n(A2D_SS_n), .SCLK(A2D_SCLK), .MISO(A2D_MISO), .MOSI(A2D_MOSI), .ld_cell_lft(ld_cell_lft), .ld_cell_rght(ld_cell_rght), .batt(batt));
  
////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.LED(),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.INT(INT),.PWM_rev_rght(PWM_rev_rght),.PWM_frwrd_rght(PWM_frwrd_rght),
			.PWM_rev_lft(PWM_rev_lft),.PWM_frwrd_lft(PWM_frwrd_lft),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));

	
//// Instantiate UART_tx (mimics command from BLE module) //////
//// You need something to send the 'g' for go ////////////////
UART_tx iTX(.clk(clk),.rst_n(rst_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));


initial begin
  //Initialize;		// perhaps you make a task that initializes everything?  
  ////// Start issuing commands to DUT //////
  clk = 0;
  RST_n = 0;
  rst_n = 0;
  repeat(5) @(negedge clk) RST_n = 1;rst_n = 1;
  repeat(5) @(negedge clk);

  @(negedge clk) begin
  ld_cell_lft = 12'hC00;
  ld_cell_rght = 12'hC00;
  batt = 12'hFFF;
  rider_lean = 14'h0000;
  cmd = 8'h67;
  send_cmd = 1;
  end

  repeat(150000) @(negedge clk);
  rider_lean = 14'h1fff;
  repeat(4000000) @(negedge clk);
  rider_lean = 14'h0000;
  repeat(1000000) @(negedge clk);
  ld_cell_lft = 12'h000;
  repeat(50000) @(negedge clk);
  ld_cell_lft = 12'hC00;
  repeat(50000) @(negedge clk);
  batt = 12'h600;
  repeat(10000) @(negedge clk);
  batt = 12'hfff;
  repeat(10000) @(negedge clk);
  cmd = 8'h73;
  send_cmd = 1;
  repeat(10000) @(negedge clk);
  ld_cell_lft = 0;
  repeat(10000) @(negedge clk);
  ld_cell_rght = 0;
  repeat(10000) @(negedge clk):
  ld_cell_lft = 12'hC00;
  ld_cell_rght = 12'hC01;
  cmd = 8'h67;
  send_cmd = 1;
  rider_lean = 14'h000;
  repeat(150000) @(negedge clk);
  rider_lean = -14'h0fff;
  repeat(400000) @(negedge clk);
  ld_cell_lft = 0;
  ld_cell_rght = 0;
  repeat(50000) @(negedge clk);
  
	
  //SendCmd(8'h67);	// perhaps you have a task that sends 'g'

    //.
	//.	// this is the "guts" of your test
	//.
  	$display("YAHOO! test passed!");
  
  $stop();
end

always
  #5 clk = ~clk;

//`include "tb_tasks.v"	// perhaps you have a separate included file that has handy tasks.

endmodule	
