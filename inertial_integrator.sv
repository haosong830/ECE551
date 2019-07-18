
module inertial_integrator(clk,rst_n,vld,ptch_rt,AZ,ptch);
  //inputs and outputs for inertial integrator:
  input clk,rst_n,vld;
  input logic signed [15:0] ptch_rt, AZ;
  output logic signed [15:0] ptch;
  //internal register and constants:
  logic signed [26:0] ptch_int;
  logic signed [15:0] ptch_rt_comp;
  logic signed [15:0] AZ_comp;
  logic signed [25:0] ptch_acc_product;
  logic signed [15:0] ptch_acc;
  logic signed [26:0] fusion_ptch_offset;
  //local parameters:
  localparam signed PTCH_RT_OFFSET = 16'h03C2;
  localparam signed AZ_OFFSET = 16'hFE80; 

  assign AZ_comp = AZ - AZ_OFFSET;
  assign ptch = ptch_int[26:11];
  assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
  assign ptch_acc_product = AZ_comp*$signed(327);
  assign ptch_acc = {{3{ptch_acc_product[25]}},ptch_acc_product[25:13]};
  assign fusion_ptch_offset = (ptch_acc > ptch) ? 512: -512;  
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) 
      ptch_int <= 27'h0000000;
    else if(vld)
      ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}},ptch_rt_comp} + fusion_ptch_offset;
  end
endmodule 

