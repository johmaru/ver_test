// Top-level CPU module
module cpu_top (
    input clk,
    input reset_n,

    imem_if.master imem,

    output logic [31:0] dbg_x1, // Debug outputs for registers x1, x2, x3
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3
  );


  logic [31:0] pc_current;
  logic [31:0] pc_next;
  logic pc_en;

  logic stall;

  logic if_id_valid;
  logic [31:0] if_id_inst;
  logic [31:0] if_id_pc;

  // Program Counter Register
  pc_reg u_pc (
           .clk(clk),
           .reset_n(reset_n),
           .pc_en(pc_en),
           .pc_next(pc_next),
           .pc_current(pc_current)
         );

  // Fetch Stage

  fetch_stage u_fetch (
                .clk(clk),
                .reset_n(reset_n),
                .stall(stall),
                .imem(imem),
                .pc_current(pc_current)
              );

  logic imem_resp_fire;
  assign imem_resp_fire = imem.resp_valid && imem.resp_ready;

  assign pc_next = pc_current + 32'd4;
  assign pc_en = imem_resp_fire;

  // IF/ID Pipeline Register

  if_id_reg u_if_id (
              .clk(clk),
              .reset_n(reset_n),
              .stall(stall),
              .imem_resp_fire(imem_resp_fire),
              .imem_resp_data(imem.resp_data),
              .pc_current(pc_current),
              .if_id_valid(if_id_valid),
              .if_id_inst(if_id_inst),
              .if_id_pc(if_id_pc)
            );


  // Compatible with RISC-V RV32I Instruction Set
  logic [6:0] opcode;
  logic [4:0] rd;
  logic [2:0] funct3;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [6:0] funct7;
  logic [31:0] imm_i;
  logic [4:0] shamt;

  // Decoder and Instruction Field Extractor
  field_extractor u_dec (
                    .instruction(if_id_inst),
                    .opcode(opcode),
                    .rd(rd),
                    .funct3(funct3),
                    .rs1(rs1),
                    .rs2(rs2),
                    .funct7(funct7),
                    .imm_i(imm_i),
                    .shamt(shamt)
                  );

  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  logic wb_we;
  logic [4:0] wb_rd;
  logic [31:0] wb_data;

  // Register File
  regfile32 u_rf (
              .clk(clk),
              .we(wb_we),
              .waddr(wb_rd),
              .wdata(wb_data),
              .raddr1(rs1),
              .rdata1(rs1_data),
              .raddr2(rs2),
              .rdata2(rs2_data)
            );

  // For the debug outputs
  assign dbg_x1 = u_rf.regs[1];
  assign dbg_x2 = u_rf.regs[2];
  assign dbg_x3 = u_rf.regs[3];


  // Hazard Detection Unit
  logic forward_rs1, forward_rs2;

  logic        id_ex_valid;
  logic        id_ex_wb_we;

  logic [3:0] alu_opcode;
  logic       dec_wb_we;
  logic       use_imm;
  logic       use_rs1, use_rs2;

  decode_ctrl u_decode_ctrl (
                .opcode(opcode),
                .funct3(funct3),
                .funct7(funct7),
                .alu_opcode(alu_opcode),
                .wb_we(dec_wb_we),
                .use_imm(use_imm),
                .use_rs1(use_rs1),
                .use_rs2(use_rs2)
              );

  hazard_unit u_hazard (
                .if_id_valid(if_id_valid),
                .use_rs1(use_rs1),
                .use_rs2(use_rs2),
                .rs1(rs1),
                .rs2(rs2),
                .id_ex_valid(id_ex_valid),
                .id_ex_wb_we(id_ex_wb_we),
                .id_ex_rd(id_ex_rd),
                .stall(stall),
                .forward_rs1(forward_rs1),
                .forward_rs2(forward_rs2)
              );
  // logic [31:0] dec_rs1_val, dec_rs2_val;
  // assign dec_rs1_val = forward_rs1 ? wb_data : rs1_data;
  // assign dec_rs2_val = forward_rs2 ? wb_data : rs2_data;

  logic [31:0] id_ex_rs1_data;
  logic [31:0] id_ex_rs2_data;
  logic [31:0] id_ex_imm_i;
  logic [4:0]  id_ex_rd;
  logic [3:0]  id_ex_alu_opcode;
  logic        id_ex_use_imm;

  // ID/EX Pipeline Register
  id_ex_reg u_id_ex (
              .clk(clk),
              .reset_n(reset_n),
              .stall(stall),
              .if_id_valid(if_id_valid),
              .if_id_inst(if_id_inst),
              .if_id_pc(if_id_pc),
              .rs1_data(rs1_data),
              .rs2_data(rs2_data),
              .imm_i(imm_i),
              .rd(rd),
              .wb_we(dec_wb_we),
              .alu_opcode(alu_opcode),
              .use_imm(use_imm),
              .pc_current(pc_current),
              .id_ex_valid(id_ex_valid),
              .id_ex_rs1_data(id_ex_rs1_data),
              .id_ex_rs2_data(id_ex_rs2_data),
              .id_ex_imm_i(id_ex_imm_i),
              .id_ex_rd(id_ex_rd),
              .id_ex_wb_we(id_ex_wb_we),
              .id_ex_alu_opcode(id_ex_alu_opcode),
              .id_ex_use_imm(id_ex_use_imm)
            );

  // EX/WB Stage

  ex_wb_stage u_ex_wb (
                .clk(clk),
                .reset_n(reset_n),
                .id_ex_valid(id_ex_valid),
                .id_ex_rs1_data(id_ex_rs1_data),
                .id_ex_rs2_data(id_ex_rs2_data),
                .id_ex_imm_i(id_ex_imm_i),
                .id_ex_rd(id_ex_rd),
                .id_ex_wb_we(id_ex_wb_we),
                .id_ex_alu_opcode(id_ex_alu_opcode),
                .id_ex_use_imm(id_ex_use_imm),
                .wb_we(wb_we),
                .wb_rd(wb_rd),
                .wb_data(wb_data)
              );

endmodule
