module pc_reg (
    input clk,
    input reset_n,
    input pc_en,
    input [31:0] pc_next,
    output reg [31:0] pc_current
);

    always @(posedge clk) begin
        if (!reset_n)
            pc_current <= 32'b0; // Reset PC to 0
        else if (pc_en)
            pc_current <= pc_next; // Update PC
    end
endmodule

module fetch_stage(
  input  wire       clk,
  input  wire       reset_n,
  input  wire       imem_req_ready,
  input  wire       imem_resp_valid,
  input  wire [31:0] imem_resp_data,
  input  wire [31:0] pc_current,
  output wire       imem_req_valid,
  output wire [31:0] imem_req_addr,
  output wire       imem_resp_ready
);
  reg  imem_outstanding;

  assign imem_req_valid  = ~imem_outstanding;
  assign imem_req_addr   = pc_current;
  assign imem_resp_ready = 1'b1;

  wire imem_req_fire  = imem_req_valid  & imem_req_ready;
  wire imem_resp_fire = imem_resp_valid & imem_resp_ready;

  always @(posedge clk) begin
  if (!reset_n) begin
    imem_outstanding <= 1'b0;
  end else begin
    if (imem_req_fire)  imem_outstanding <= 1'b1;
    if (imem_resp_fire) imem_outstanding <= 1'b0;
  end
end
endmodule