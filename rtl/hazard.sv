module hazard_unit (
    input  logic        if_id_valid,
    input  logic        use_rs1,
    input  logic        use_rs2,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,

    input  logic        id_ex_valid,
    input  logic        id_ex_wb_we,
    input  logic [4:0]  id_ex_rd,

    output logic        stall,
    output logic        forward_rs1,
    output logic        forward_rs2
  );

  assign forward_rs1 =
         use_rs1 && id_ex_valid && id_ex_wb_we && (id_ex_rd != 5'd0) && (id_ex_rd == rs1);

  assign forward_rs2 =
         use_rs2 && id_ex_valid && id_ex_wb_we && (id_ex_rd != 5'd0) && (id_ex_rd == rs2);

  assign stall = if_id_valid && (forward_rs1 || forward_rs2);

endmodule
