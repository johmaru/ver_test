`timescale 1ns/1ps
module tb_cpu_top;
  logic clk = 0;
  logic reset_n = 0;

  logic imem_req_valid;
  logic [31:0] imem_req_addr;
  logic imem_req_ready = 1'b1;

  logic imem_resp_valid = 1'b0;
  logic [31:0] imem_resp_data = 32'd0;
  logic imem_resp_ready;

  logic [31:0] dbg_x1;
  logic [31:0] dbg_x2;
  logic [31:0] dbg_x3;

  cpu_top dut (
    .clk(clk),
    .reset_n(reset_n),
    .imem_req_ready(imem_req_ready),
    .imem_resp_valid(imem_resp_valid),
    .imem_resp_data(imem_resp_data),
    .imem_req_valid(imem_req_valid),
    .imem_req_addr(imem_req_addr),
    .imem_resp_ready(imem_resp_ready),
    .dbg_x1(dbg_x1),
    .dbg_x2(dbg_x2),
    .dbg_x3(dbg_x3)
  );

  initial begin
    forever #5 clk = ~clk;
  end

  logic [31:0] rom [0:255];
  integer i;

  initial begin
    for (i = 0; i < 256; i = i + 1) rom[i] = 32'h00000013;

    rom[0] = 32'h00500093; // addi x1, x0, 5
    rom[1] = 32'h00700113; // addi x2, x0, 7
    rom[2] = 32'h002081b3; // add  x3, x1, x2
    rom[3] = 32'h00000013; // nop

    $dumpfile("cpu.vcd");
    $dumpvars(0, tb_cpu_top);

    #1;
    reset_n = 0;
    #30;
    for (i = 0; i < 32; i = i + 1)
      dut.u_rf.regs[i] = 32'd0;
    reset_n = 1;

    #200;
    $display("x1=%h x2=%h x3=%h", dbg_x1, dbg_x2, dbg_x3);

    #500;
    $finish;
  end

  logic pending;
  logic [31:0] pending_addr;

  always_ff @(posedge clk) begin
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