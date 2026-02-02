module field_extractor (
    input [31:0] instruction,
    output [6:0] opcode,
    output [4:0] rd,
    output [2:0] funct3,
    output [4:0] rs1,
    output [4:0] rs2,
    output [6:0] funct7,

    output [31:0] imm_i,
    output [4:0] shamt
  );
  assign opcode = instruction[6:0];
  assign rd     = instruction[11:7];
  assign funct3 = instruction[14:12];
  assign rs1    = instruction[19:15];
  assign rs2    = instruction[24:20];
  assign funct7 = instruction[31:25];

  // I-type immediate extraction
  assign imm_i  = {{20{instruction[31]}}, instruction[31:20]}; // Sign-extend 12-bit immediate
  assign shamt  = instruction[24:20]; // Shift amount for shift instructions

endmodule

module decode_ctrl (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    output logic [3:0] alu_opcode,
    output logic wb_we,
    output logic use_imm,
    output logic use_rs1,
    output logic use_rs2
  );


  always_comb
  begin
    alu_opcode = 4'b0000; // Default to ADD
    wb_we = 1'b0;
    use_imm = 1'b0;
    use_rs1 = 1'b0;
    use_rs2 = 1'b0;

    case (opcode)
      7'b0110011:
      begin // R-type
        use_rs1 = 1'b1;
        use_rs2 = 1'b1;
        wb_we = 1'b1;
        case ({funct7, funct3})
          10'b0000000_000:
            alu_opcode = 4'b0000; // ADD
          10'b0100000_000:
            alu_opcode = 4'b0001; // SUB
          10'b0000000_111:
            alu_opcode = 4'b0010; // AND
          10'b0000000_110:
            alu_opcode = 4'b0011; // OR
          10'b0000000_100:
            alu_opcode = 4'b0100; // XOR
          10'b0000000_001:
            alu_opcode = 4'b0101; // SLL
          10'b0000000_101:
            alu_opcode = 4'b0110; // SRL
          10'b0100000_101:
            alu_opcode = 4'b0111; // SRA
          10'b0000000_010:
            alu_opcode = 4'b1000; // SLT
          10'b0000000_011:
            alu_opcode = 4'b1001; // SLTU
          default:
          begin
            alu_opcode = 4'b0000; // Default to ADD
            wb_we = 1'b0;
          end
        endcase
      end

      7'b0010011:
      begin
        use_rs1 = 1'b1;
        use_rs2 = 1'b0;
        use_imm = 1'b1;

        case (funct3)
          3'b000:
          begin
            alu_opcode = 4'b0000; // ADDI
            wb_we = 1'b1;
          end
        endcase
      end

      default:
      begin
        wb_we = 1'b0;
      end
    endcase
  end


endmodule
