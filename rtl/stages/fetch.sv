module pc_reg (
    input clk,
    input reset_n,
    input pc_en,
    input [31:0] pc_next,
    output logic [31:0] pc_current
  );

  always_ff @(posedge clk)
  begin
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

    imem_if.master imem,

    input  logic [31:0] pc_current
  );

  always_comb
  begin
    assign imem.req_valid  = !stall;
    assign imem.req_addr   = pc_current;
    assign imem.resp_ready = (!stall);
  end
endmodule
