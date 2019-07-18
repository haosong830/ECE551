module A2D_intf(clk, rst_n, nxt, lft_ld, rght_ld, batt, SS_n, SCLK, MOSI, MISO);
input clk, rst_n, nxt;
input MISO;

output logic [11:0] lft_ld, rght_ld, batt;
output logic SS_n, SCLK, MOSI;
logic wrt, done;
logic [15:0] cmd, rd_data;
logic [1:0] counter;
logic update;

typedef enum logic [1:0]{IDLE, TELL, READ}state_t;
state_t state, nxt_state;

SPI_mstr16 spi(.rst_n(rst_n),.clk(clk),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),.cmd(cmd),.done(done),.rd_data(rd_data),.wrt(wrt));

//state update
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state; 
//state transition and output logic
always_comb begin
	wrt = 0;
	update = 0;
	nxt_state = IDLE;
	case(state)
	IDLE: begin
		if(nxt)begin
			wrt = 1;
			nxt_state = TELL;
		end
	end
	TELL: begin
		if(done)begin
			wrt = 1;
			nxt_state = READ;
		end
		else
			nxt_state = TELL;
	end
	READ: begin
		if(done)begin
			update = 1;
			nxt_state = IDLE;
		end
		else
			nxt_state = READ;
	end
	default:
		nxt_state = IDLE;
	endcase
end

always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)begin
		lft_ld <= 0;
		rght_ld <= 0;
		batt <= 0;
	end
	else if((counter == 2'b00) && update)
		lft_ld <= rd_data[11:0];
	else if((counter == 2'b01) && update)
		rght_ld <= rd_data[11:0];
	else if((counter == 2'b10) && update)
		batt <= rd_data[11:0];

assign cmd = (counter == 2'b00)? 0 : (counter == 2'b01)? 16'h2000 : 16'h2800;
//Round Robin Counter 
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		counter <= 1'b0;
	else if(update)begin
		counter <= counter + 1;
		if(counter == 2)
			counter <= 1'b0;
        end

endmodule