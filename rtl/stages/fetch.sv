module pc_reg (
    input clk,
    input reset_n,
    input pc_en,
    input [31:0] pc_next,
    output logic [31:0] pc_current
);

    always_ff @(posedge clk) begin
        if (!reset_n)
            pc_current <= 32'b0; // Reset PC to 0
        else if (pc_en)
            pc_current <= pc_next; // Update PC
    end
endmodule

module fetch_stage(
  input  logic       clk,
  input  logic       reset_n,

  input  logic       stall,

  input  logic       imem_req_ready,
  input  logic       imem_resp_valid,
  input  logic [31:0] imem_resp_data,
  input  logic [31:0] pc_current,
  
  output logic       imem_req_valid,
  output logic [31:0] imem_req_addr,
  output logic       imem_resp_ready
);

  logic  imem_outstanding;

  assign imem_req_valid  = (~imem_outstanding) && (!stall);
  assign imem_req_addr   = pc_current;
  assign imem_resp_ready = (!stall);

  logic imem_req_fire;
  assign imem_req_fire = imem_req_valid  & imem_req_ready;

  logic imem_resp_fire;
  assign imem_resp_fire = imem_resp_valid & imem_resp_ready;

  always_ff @(posedge clk) begin
  if (!reset_n) begin
    imem_outstanding <= 1'b0;
  end else begin
    if (imem_req_fire)  imem_outstanding <= 1'b1;
    if (imem_resp_fire) imem_outstanding <= 1'b0;
  end
end
endmodule