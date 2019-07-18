module inert_intf(clk,rst_n,vld,ptch,SS_n,SCLK,MOSI,MISO,INT);
  //inputs & outputs of the module
  input clk,rst_n;
  input MISO,INT;
  output logic vld;
  output SS_n,SCLK,MOSI;
  output [15:0] ptch;
  //internal holding signals & registers
  logic [7:0] hold_pitchL;
  logic [7:0] hold_pitchH;
  logic [7:0] hold_AZL;
  logic [7:0] hold_AZH;
  logic INT_ff1;
  logic INT_ff2;
  logic [15:0] timer; //the timer used to initialize the sensor\
  logic [15:0] cmd; //command used to communicate with the SPI master
  logic wrt;
  logic done;
  logic [7:0] rd_data;//the data transferred from SPI master
  logic [15:0] AZ;
  logic [15:0] ptch_rt;
  logic clr_tmr; // the signal to clear the timer in SM
  /*signals to indicate a read from Accel used by SM*/
  logic rd_ptchL;
  logic rd_ptchH;
  logic rd_AZL;
  logic rd_AZH;
  
  //define state types to make debug easier:
  typedef enum logic [3:0] {INIT1,INIT2,INIT3,INIT4,WAIT,READ1,READ2,READ3,READ4} state_t;
  state_t state, nextState;
  
  //double flop the INT signal to eliminate metastability:
  always_ff @(posedge clk) begin
    INT_ff1 <= INT;
    INT_ff2 <= INT_ff1;
  end

  //logic for the holding registers to choose which data to store:
  always_ff @(posedge clk,negedge rst_n) begin
    if(!rst_n) begin
      hold_pitchL = 8'h00;
      hold_pitchH = 8'h00;
      hold_AZL = 8'h00;
      hold_AZH = 8'h00;
    end
    else if(rd_ptchL) hold_pitchL <= rd_data;
    else if(rd_ptchH) hold_pitchH <= rd_data;
    else if(rd_AZL) hold_AZL <= rd_data;
    else if(rd_AZH) hold_AZH <= rd_data;
  end
  //logic for the timer:
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      timer <= 16'h0000;
    else if(clr_tmr)
      timer <= 16'h0000;
    else
      timer <= timer + 1;
  end
  
  //logic for the sensor state machine:
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
      state <= INIT1;
    else
      state <= nextState;
  end
  /*We have 9 states in our state machine. In the first 5 states we initialize the sensor by set up the registers in SegwayModel. Then, after initialization,
    we wait until the INT_ff2 signal is high. If INT_ff2 is high, we transfer to reading states, which form a infinite loop until reset is asserted.
   */
  always_comb begin
    wrt = 0;
    cmd = 16'h0000;
    vld = 0;
    rd_ptchL = 0;
    rd_ptchH = 0;
    rd_AZL = 0;
    rd_AZH = 0;
    clr_tmr = 0;
	 nextState = INIT1;
    case (state)
      INIT1: begin
        cmd = 16'h0D02;
	if(&timer) begin
	  nextState = INIT2;
	  clr_tmr = 1;
	  wrt = 1;
	end
      end
      INIT2: begin
	cmd = 16'h1053;
	if(&timer[9:0]) begin 
          nextState = INIT3;
	  clr_tmr = 1;
	  wrt = 1;
	end
	else nextState = INIT2;
      end
      INIT3: begin
	cmd = 16'h1150;
	if(&timer[9:0]) begin
	  nextState = INIT4;
	  clr_tmr = 1;
	  wrt = 1;
	end
	else nextState = INIT3;
      end
      INIT4: begin
	cmd = 16'h1460;
	if(&timer[9:0]) begin
	  nextState = WAIT;
	  clr_tmr = 1;
	  wrt = 1;
	end
	else nextState = INIT4;
      end
      WAIT: begin
	if(INT_ff2) begin
	  nextState = READ1;
	  cmd = 16'hA2xx;
	  wrt = 1;
	end
	else
	  nextState = WAIT;
      end
      READ1: begin
	if(done) begin
	  rd_ptchL = 1;
	  cmd = 16'hA3xx;
	  wrt = 1;
	  nextState = READ2;
	end
	else nextState = READ1;
      end
      READ2: begin
	if(done) begin
	  cmd = 16'hACxx;
	  wrt = 1;
	  rd_ptchH = 1;
	  nextState = READ3;
	end
	else nextState = READ2;
      end
      READ3: begin
	if(done) begin
	  wrt = 1;
 	  cmd = 16'hADxx;
	  rd_AZL = 1;
	  nextState = READ4;
	end
	else nextState = READ3;
      end
      READ4: begin
	if(done) begin
	  rd_AZH = 1;
	  nextState = WAIT;
	  vld = 1;
	end
	else nextState = READ4;
      end
      default: nextState = INIT1;
    endcase
  end
//pass values from holding registers to output ports
  assign ptch_rt = {hold_pitchH,hold_pitchL};
  assign AZ = {hold_AZH,hold_AZL};
//initialize the modules we need to use
  SPI_mstr16 SPI_DUT(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),.wrt(wrt),.cmd(cmd),.done(done),.rd_data(rd_data));
  inertial_integrator integrator_DUT(.clk(clk),.rst_n(rst_n),.vld(vld),.ptch_rt(ptch_rt),.AZ(AZ),.ptch(ptch));  
endmodule

  
