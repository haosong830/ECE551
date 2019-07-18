module reset_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;
reg int_rst;

always @(negedge clk or negedge RST_n) begin
	if(!RST_n)
		int_rst <= 1'b0;
	else
		int_rst <= 1'b1;
end

always @(negedge clk or negedge RST_n) begin
	if(!RST_n)
		rst_n <= 1'b0;
	else
		rst_n <= int_rst;
end

endmodule