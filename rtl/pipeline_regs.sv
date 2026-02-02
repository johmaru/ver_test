// IF/ID Pipeline Register

module if_id_reg (
    input logic        clk,
    input logic        reset_n,
    input logic        stall,
    input logic        imem_resp_fire,
    input logic [31:0] imem_resp_data,
    input logic [31:0] pc_current,

    output logic       if_id_valid,
    output logic [31:0] if_id_inst,
    output logic [31:0] if_id_pc
  );

  logic consume;
  assign consume = if_id_valid && !stall;

  always_ff @(posedge clk)
  begin
    if (!reset_n)
    begin
      if_id_valid <= 1'b0;
      if_id_inst <= 32'b0;
      if_id_pc <= 32'b0;
    end
    else
    begin
      if (imem_resp_fire && (!if_id_valid || consume))
      begin
        if_id_valid <= 1'b1;
        if_id_inst <= imem_resp_data;
        if_id_pc <= pc_current;
      end
      else if (consume)
      begin
        if_id_valid <= 1'b0;
      end
    end
  end
endmodule

// ID/EX Pipeline Register

module id_ex_reg (
    input logic        clk,
    input logic        reset_n,
    input logic        stall,
    input logic        if_id_valid,
    input logic [31:0] if_id_inst,
    input logic [31:0] if_id_pc,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm_i,
    input logic [4:0]  rd,
    input logic        wb_we,
    input logic [3:0]  alu_opcode,
    input logic        use_imm,
    input logic [31:0] pc_current,

    output logic       id_ex_valid,
    output logic [31:0] id_ex_rs1_data,
    output logic [31:0] id_ex_rs2_data,
    output logic [31:0] id_ex_imm_i,
    output logic [4:0]  id_ex_rd,
    output logic        id_ex_wb_we,
    output logic [3:0]  id_ex_alu_opcode,
    output logic        id_ex_use_imm
  );

  always_ff @(posedge clk)
  begin
    if (!reset_n)
    begin
      id_ex_valid <= 1'b0;
      id_ex_rs1_data <= 32'b0;
      id_ex_rs2_data <= 32'b0;
      id_ex_imm_i <= 32'b0;
      id_ex_rd <= 5'b0;
      id_ex_wb_we <= 1'b0;
      id_ex_alu_opcode <= 4'b0;
      id_ex_use_imm <= 1'b0;
      // id_ex_pc <= 32'b0;
    end
    else if (stall)
    begin
      id_ex_valid <= 1'b0;
      id_ex_rs1_data <= 32'b0;
      id_ex_rs2_data <= 32'b0;
      id_ex_imm_i <= 32'b0;
      id_ex_rd <= 5'b0;
      id_ex_wb_we <= 1'b0;
      id_ex_alu_opcode <= 4'b0;
      id_ex_use_imm <= 1'b0;
    end
    else
    begin
      id_ex_valid <= if_id_valid;
      id_ex_rs1_data <= rs1_data;
      id_ex_rs2_data <= rs2_data;
      id_ex_imm_i <= imm_i;
      id_ex_rd <= rd;
      id_ex_wb_we <= wb_we;
      id_ex_alu_opcode <= alu_opcode;
      id_ex_use_imm <= use_imm;
      // id_ex_pc <= if_id_pc;
    end
  end
endmodule
