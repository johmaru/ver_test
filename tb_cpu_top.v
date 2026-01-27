`timescale 1ns/1ps
module tb_cpu_top;
  reg clk = 0;
  reg reset_n = 0;

  wire imem_req_valid;
  wire [31:0] imem_req_addr;
  reg  imem_req_ready = 1'b1;

  reg  imem_resp_valid = 1'b0;
  reg  [31:0] imem_resp_data = 32'd0;
  wire imem_resp_ready;

  cpu_top dut (
    .clk(clk),
    .reset_n(reset_n),
    .imem_req_ready(imem_req_ready),
    .imem_resp_valid(imem_resp_valid),
    .imem_resp_data(imem_resp_data),
    .imem_req_valid(imem_req_valid),
    .imem_req_addr(imem_req_addr),
    .imem_resp_ready(imem_resp_ready)
  );

  always #5 clk = ~clk;

  reg [31:0] rom [0:255];
  integer i;

  initial begin
    for (i = 0; i < 256; i = i + 1) rom[i] = 32'h00000013;

    $dumpfile("cpu.vcd");
    $dumpvars(0, tb_cpu_top);

    #1;
    reset_n = 0;
    #30;
    reset_n = 1;

    #500;
    $finish;
  end

  reg pending;
  reg [31:0] pending_addr;

  always @(posedge clk) begin
    if (!reset_n) begin
      imem_resp_valid <= 1'b0;
      imem_resp_data  <= 32'd0;
      pending         <= 1'b0;
      pending_addr    <= 32'd0;
    end else begin
      imem_resp_valid <= 1'b0;

      if (pending) begin
        imem_resp_valid <= 1'b1;
        imem_resp_data  <= rom[pending_addr[9:2]];
        pending         <= 1'b0;
      end

      if (imem_req_valid && imem_req_ready) begin
        pending      <= 1'b1;
        pending_addr <= imem_req_addr;
      end
    end
  end
endmodule