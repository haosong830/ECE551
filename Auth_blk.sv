module Auth_blk (clk,rst_n,RX,rider_off,pwr_up);
  //input and output signals for auth_block
  input rider_off;
  input RX;
  input clk;
  input rst_n;
  output logic pwr_up;
  //internal signals used for UART_rcv and state machine
  logic [7:0] rx_data;
  logic rx_rdy;
  logic clr_rx_rdy;
  
	UART_rcv receiver(.clk(clk), .rst_n(rst_n), .RX(RX), .rdy(rx_rdy), .rx_data(rx_data), .clr_rdy(clr_rx_rdy));


/////////// infer state flops ///////////////

typedef enum reg [1:0] {OFF, PWR1, PWR2} state_t;
  state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) 
  if (!rst_n)    
    state <= OFF;
  else    
    state <= nxt_state;

always_comb  begin 
///// default outputs //////
  pwr_up = 0;
  clr_rx_rdy = 0;
  nxt_state = OFF; 

  case(state)
    OFF: if (rx_data == 8'h67 && rx_rdy) begin//"g" is asserted
	   clr_rx_rdy = 1; 
           nxt_state = PWR1;
         end 
    PWR1: begin 
 	pwr_up = 1;
	if (rider_off) begin
            clr_rx_rdy = 1; 
            nxt_state = OFF;
        end
        else if (!rider_off && rx_data == 8'h73 && rx_rdy) begin //"s" is asserted
          clr_rx_rdy = 1; 
          nxt_state = PWR2;
        end
	else nxt_state = PWR1;
        end         
  PWR2: begin 
 	pwr_up = 1;
	if (!rider_off && rx_data == 8'h67 && rx_rdy) begin
            clr_rx_rdy = 1; 
            nxt_state = PWR1;
        end 
        else if (rider_off) begin 
                clr_rx_rdy = 1; 
                nxt_state = OFF;
        end
	else nxt_state = PWR2;         
        end 
///// default case = OFF /////
 default : begin        
  nxt_state = OFF;
 end 

 endcase
end
endmodule 

  
