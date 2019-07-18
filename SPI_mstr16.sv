module SPI_mstr16(rst_n,clk,SS_n,SCLK,MOSI,MISO,cmd,done,rd_data,wrt);
input clk, rst_n, wrt, MISO;
input [15:0] cmd;
output logic done, SS_n, MOSI;
output SCLK;
output [15:0] rd_data;

logic [4:0] sclk_div;// Set SCLK
logic smpl, MISO_smpl, shft;// assert when we need to sample; used to keep the sampled MISO ; assert when we need to shift
logic [15:0] shft_reg;
logic rst_cnt;//reset the counter that controls the SCLK
logic set_done, clr_done;// used to change the value of SS_n and done
logic [4:0]count;// used to count the number of shifting
logic add; // assert when we need to increase count;
logic init; // initialize the counter

typedef enum logic[1:0]{IDLE, FRONT, SHIFT, BACK} state_t;// four states of the SPI_State machine
state_t state, nxt_state;


//Set sclk
always_ff@(posedge clk)
if(rst_cnt)
  sclk_div <= 5'b10111;//start as 10111
else
  sclk_div <= sclk_div + 1'b1;//increase
assign SCLK = sclk_div[4];//SCLK is determined by the msb of sclk_div

//shift and sample
always_ff@(posedge clk)
  if(smpl)// keep the sampled value from MISO
    MISO_smpl <= MISO;

always_ff@(posedge clk)
  if(wrt)
    shft_reg <= cmd;// load the cmd
  else if(shft)
    shft_reg <= {shft_reg[14:0], MISO_smpl};//shift it

assign MOSI = shft_reg[15];// MOSI is the bit shifted out
assign rd_data = shft_reg;

//infer flop
always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
//output logic
always_comb begin
  nxt_state = IDLE;
  rst_cnt = 0;
  smpl = 0;
  shft = 0;
  add = 0;
  init = 0;
  set_done = 0;
  clr_done = 0;
  case(state)
    IDLE:// the initial state
      begin
	rst_cnt = 1;
	if(wrt) begin// start to transact
	  nxt_state = FRONT;
	  clr_done = 1;  
	end
      end
    FRONT: // front porch state
      begin
	if(sclk_div == 5'b11111)begin
	  nxt_state = SHIFT;
	  init = 1;// initialize the 16 counter
        end
        else
          nxt_state = FRONT;
      end
    SHIFT://state where we shift and sample
      begin
        if(count == 16)
          nxt_state = BACK;
        else if(sclk_div == 5'b11111)begin//falling edge
	  nxt_state = SHIFT;
	  shft = 1;//shift
   	end
	else if(sclk_div == 5'b01111)begin//rising edge
	  nxt_state = SHIFT;
	  add = 1;
	  smpl = 1; //sample
 	end
        else
          nxt_state = SHIFT;
      end
    BACK://back porch state
      begin
	if(sclk_div == 5'b11111)begin
	  nxt_state = IDLE;
	  shft = 1;// shift one last time
	  set_done = 1;
	end
	else
	  nxt_state = BACK;
      end
    default:
	nxt_state = IDLE;
  endcase
end

//16 COUNTER, used to count the shifted times
always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)
    count <= 1'b0;
  else if(init)
    count <= 1'b0;//start transaction
  else if(add)
    count <= count + 1;//when we finish one sample, add one to the counter
//set done, SS_n
always_ff@(posedge clk, negedge rst_n)
  if(!rst_n)begin
    SS_n <= 1'b1;//preset
    done <= 1'b0;//reset
  end
  else if(set_done)
    begin
    SS_n <= 1'b1;
    done <= 1'b1;
  end
  else if(clr_done)
    begin
    SS_n <= 1'b0;
    done <= 1'b0;
  end
endmodule
