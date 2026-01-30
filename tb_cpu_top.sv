`timescale 1ns/1ps
module tb_cpu_top;

  // RV32I encoding helpers

  function automatic [31:0] rv_addi(input [4:0] rd, input [4:0] rs1, input int imm);
  logic [11:0] i;
    begin
      i = imm[11:0];
      rv_addi = { i, rs1, 3'b000, rd, 7'b0010011 };
    end
  endfunction

  function automatic [31:0] rv_rtype(
    input [6:0] funct7,
    input [4:0] rs2,
    input [4:0] rs1,
    input [2:0] funct3,
    input [4:0] rd
  );
    begin
      rv_rtype = { funct7, rs2, rs1, funct3, rd, 7'b0110011 };
    end
  endfunction

  function automatic [31:0] rv_add(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_add = rv_rtype(7'b0000000, rs2, rs1, 3'b000, rd);
    end
  endfunction

  function automatic [31:0] rv_sub(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_sub = rv_rtype(7'b0100000, rs2, rs1, 3'b000, rd);
    end
  endfunction

  function automatic [31:0] rv_and(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_and = rv_rtype(7'b0000000, rs2, rs1, 3'b111, rd);
    end
  endfunction

  function automatic [31:0] rv_or(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_or = rv_rtype(7'b0000000, rs2, rs1, 3'b110, rd);
    end
  endfunction

  function automatic [31:0] rv_xor(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_xor = rv_rtype(7'b0000000, rs2, rs1, 3'b100, rd);
    end
  endfunction

  function automatic [31:0] rv_sll(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_sll = rv_rtype(7'b0000000, rs2, rs1, 3'b001, rd);
    end
  endfunction

  function automatic [31:0] rv_srl(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_srl = rv_rtype(7'b0000000, rs2, rs1, 3'b101, rd);
    end
  endfunction

  function automatic [31:0] rv_sra(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_sra = rv_rtype(7'b0100000, rs2, rs1, 3'b101, rd);
    end
  endfunction

  function automatic [31:0] rv_slt(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_slt = rv_rtype(7'b0000000, rs2, rs1, 3'b010, rd);
    end
  endfunction

  function automatic [31:0] rv_sltu(input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
    begin
      rv_sltu = rv_rtype(7'b0000000, rs2, rs1, 3'b011, rd);
    end
  endfunction

  localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0


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

  logic [31:0] rom [0:255];
  integer i;

  task automatic reset_cpu_and_clear_regs();
    begin
      reset_n = 1'b0;
      repeat (3) @(posedge clk);
      for (i = 0; i < 32; i = i + 1)
        dut.u_rf.regs[i] = 32'd0;
      reset_n = 1'b1;
      repeat (1) @(posedge clk);
    end
  endtask

  initial begin
    forever #5 clk = ~clk;
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
      if (!pending) begin
       imem_resp_valid <= 1'b0;
      end

      if (pending) begin
        imem_resp_valid <= 1'b1;
        imem_resp_data <= rom[pending_addr[9:2]];
        if (imem_resp_ready) begin
          pending <= 1'b0;
        end
      end
      if (!pending && imem_req_valid && imem_req_ready) begin
        pending      <= 1'b1;
        pending_addr <= imem_req_addr;
      end
    end
  end

  task automatic run_and_check(input string name, input [31:0] exp_x3);
    begin
      reset_cpu_and_clear_regs();
      repeat (30) @(posedge clk);
      if (dbg_x3 !== exp_x3) begin
        $display("%s FAILED: x3=%h expected=%h", name, dbg_x3, exp_x3);
        $fatal(1);
      end else begin
        $display("%s PASSED: x3=%h", name, dbg_x3);
      end
    end
  endtask

  initial begin
    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;

    $dumpfile("cpu.vcd");
    $dumpvars(0, tb_cpu_top);

    rom[0] = rv_addi(5'd1, 5'd0, 5); // addi x1, x0, 5
    rom[1] = rv_addi(5'd2, 5'd0, 7); // addi x2, x0, 7
    rom[2] = rv_add(5'd3, 5'd1, 5'd2); // add  x3, x1, x2
    rom[3] = NOP; // nop
    run_and_check("ADD", 32'd12);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, 30); // addi x1, x0, 30
    rom[1] = rv_addi(5'd2, 5'd0, 20); // addi x2, x0, 20
    rom[2] = rv_sub(5'd3, 5'd1, 5'd2); // sub  x3, x1, x2
    rom[3] = NOP; // nop
    run_and_check("SUB", 32'd10);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, 32'h55);
    rom[1] = rv_addi(5'd2, 5'd0, 32'h0F);
    rom[2] = rv_xor(5'd3, 5'd1, 5'd2);
    rom[3] = NOP;
    run_and_check("XOR", 32'h0000005A);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, 1);
    rom[1] = rv_addi(5'd2, 5'd0, 4);
    rom[2] = rv_sll(5'd3, 5'd1, 5'd2);
    rom[3] = NOP;
    run_and_check("SLL", 32'd16);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, 32'h80);
    rom[1] = rv_addi(5'd2, 5'd0, 4);
    rom[2] = rv_srl(5'd3, 5'd1, 5'd2);
    rom[3] = NOP;
    run_and_check("SRL", 32'h00000008);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, -128);
    rom[1] = rv_addi(5'd2, 5'd0, 4);
    rom[2] = rv_sra(5'd3, 5'd1, 5'd2);
    rom[3] = NOP;
    run_and_check("SRA", 32'hFFFFFFF8);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, -1);
    rom[1] = rv_addi(5'd2, 5'd0, 1);
    rom[2] = rv_slt(5'd3, 5'd1, 5'd2);
    rom[3] = NOP;
    run_and_check("SLT", 32'd1);

    for (i = 0; i < 256; i = i + 1) rom[i] = NOP;
    rom[0] = rv_addi(5'd1, 5'd0, -1);
    rom[1] = rv_addi(5'd2, 5'd0, 1);
    rom[2] = rv_sltu(5'd3, 5'd1, 5'd2);
    rom[3] = NOP;
    run_and_check("SLTU", 32'd0);

    $finish;
  end
endmodule