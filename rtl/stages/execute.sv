// EX/WB Stage

module ex_wb_stage(
    input logic clk,
    input logic reset_n,

    input  logic        id_ex_valid,
    input  logic [31:0] id_ex_rs1_data,
    input  logic [31:0] id_ex_rs2_data,
    input  logic [31:0] id_ex_imm_i,
    input  logic [4:0]  id_ex_rd,
    input  logic        id_ex_wb_we,
    input  logic [3:0]  id_ex_alu_opcode,
    input  logic        id_ex_use_imm,

    output logic        wb_we,
    output logic [4:0]  wb_rd,
    output logic [31:0] wb_data

  );

  logic [31:0] ex_alu_in2;
  assign ex_alu_in2 = id_ex_use_imm ? id_ex_imm_i : id_ex_rs2_data;

  logic [31:0] alu_res;
  logic alu_zero;

  alu u_alu (
        .a(id_ex_rs1_data),
        .b(ex_alu_in2),
        .opcode(id_ex_alu_opcode),
        .result(alu_res),
        .zero(alu_zero)
      );

  assign wb_we = id_ex_valid && id_ex_wb_we;
  assign wb_rd = id_ex_rd;
  assign wb_data = alu_res;
endmodule
