// definition of a simple 32-register file
module regfile32 (
    input logic clk,
    input logic we,
    input logic [4:0] waddr,
    input logic [31:0] wdata,
    input logic [4:0] raddr1,
    output logic [31:0] rdata1,
    input logic [4:0] raddr2,
    output logic [31:0] rdata2
);

    logic [31:0] regs [0:31];

    always_comb begin
        rdata1 = (raddr1 != 5'd0) ? regs[raddr1] : 32'd0;
        rdata2 = (raddr2 != 5'd0) ? regs[raddr2] : 32'd0;
    end

    always_ff @(posedge clk) begin
        if (we && (waddr != 5'd0)) begin
            regs[waddr] <= wdata;
        end
    end
endmodule

// Top-level CPU module
module cpu_top (
    input clk,
    input reset_n,
    
    input logic imem_req_ready,
    input logic imem_resp_valid,
    input logic [31:0] imem_resp_data,
    output wire imem_req_valid,
    output wire [31:0] imem_req_addr,
    output wire imem_resp_ready,
    output logic [31:0] dbg_x1, // Debug outputs for registers x1, x2, x3
    output logic [31:0] dbg_x2,
    output logic [31:0] dbg_x3
);
    

logic [31:0] pc_current;
logic [31:0] pc_next;
logic pc_en;

// Program Counter Register
pc_reg u_pc (
    .clk(clk),
    .reset_n(reset_n),
    .pc_en(pc_en),
    .pc_next(pc_next),
    .pc_current(pc_current)
);

logic need_stall;

// Fetch Stage
logic fetch_imem_req_valid;
logic [31:0] fetch_imem_req_addr;
logic fetch_imem_resp_ready;

fetch_stage u_fetch (
    .clk(clk),
    .reset_n(reset_n),
    .stall(need_stall),
    .imem_req_ready(imem_req_ready),
    .imem_resp_valid(imem_resp_valid),
    .imem_resp_data(imem_resp_data),
    .pc_current(pc_current),
    .imem_req_valid(fetch_imem_req_valid),
    .imem_req_addr(fetch_imem_req_addr),
    .imem_resp_ready(fetch_imem_resp_ready)
);

assign imem_req_valid = fetch_imem_req_valid;
assign imem_req_addr = fetch_imem_req_addr;
assign imem_resp_ready = fetch_imem_resp_ready;

logic imem_req_fire;
logic imem_resp_fire;   
assign imem_req_fire = imem_req_valid && imem_req_ready;
assign imem_resp_fire = imem_resp_valid && imem_resp_ready;

assign pc_next = pc_current + 32'd4;
assign pc_en = imem_resp_fire;

// IF/ID Pipeline Register

logic if_id_valid;
logic [31:0] if_id_inst;
logic [31:0] if_id_pc;

logic consume;
assign consume = if_id_valid && !need_stall;

always_ff @(posedge clk) begin
    if (!reset_n) begin
        if_id_valid <= 1'b0;
        if_id_inst <= 32'b0;
        if_id_pc <= 32'b0;
    end else begin
        if (imem_resp_fire && (!if_id_valid || consume)) begin
            if_id_inst <= imem_resp_data;
            if_id_pc <= pc_current;
        end
        if_id_valid <= (if_id_valid && !consume) ? 1'b1
                    : (imem_resp_fire ? 1'b1 : 1'b0);
    end
end

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

assign dbg_x1 = u_rf.regs[1];
assign dbg_x2 = u_rf.regs[2];
assign dbg_x3 = u_rf.regs[3];

logic is_rtype, is_itype;
assign is_rtype = (opcode == 7'b0110011);
assign is_itype = (opcode == 7'b0010011);

logic op_add, op_sub, op_and, op_or, op_addi, op_xor, op_sll, op_srl, op_sra, op_slt, op_sltu;
assign op_add = is_rtype && (funct3 == 3'b000) && (funct7 == 7'b0000000);
assign op_sub = is_rtype && (funct3 == 3'b000) && (funct7 == 7'b0100000);
assign op_and = is_rtype && (funct3 == 3'b111) && (funct7 == 7'b0000000);
assign op_or  = is_rtype && (funct3 == 3'b110) && (funct7 == 7'b0000000);
assign op_xor  = is_rtype && (funct3 == 3'b100) && (funct7 == 7'b0000000);
assign op_sll  = is_rtype && (funct3 == 3'b001) && (funct7 == 7'b0000000);
assign op_srl  = is_rtype && (funct3 == 3'b101) && (funct7 == 7'b0000000);
assign op_sra  = is_rtype && (funct3 == 3'b101) && (funct7 == 7'b0100000);
assign op_slt  = is_rtype && (funct3 == 3'b010) && (funct7 == 7'b0000000);
assign op_sltu = is_rtype && (funct3 == 3'b011) && (funct7 == 7'b0000000);

assign op_addi = is_itype && (funct3 == 3'b000);

logic use_rs1, use_rs2;
assign use_rs1 = is_rtype || is_itype;
assign use_rs2 = is_rtype;

logic dep_rs1, dep_rs2;
assign dep_rs1 = use_rs1 
                 && id_ex_valid && id_ex_wb_we
                 && (id_ex_rd != 5'b0)
                 && (id_ex_rd == rs1);

assign dep_rs2 = use_rs2
                    && id_ex_valid && id_ex_wb_we
                    && (id_ex_rd != 5'b0)
                    && (id_ex_rd == rs2);

assign need_stall = if_id_valid && (dep_rs1 || dep_rs2);

logic [3:0] alu_opcode;
assign alu_opcode =
    op_sub ? 4'b0001 :
    op_and ? 4'b0010 :
    op_or  ? 4'b0011 :
    op_xor ? 4'b0100 :
    op_sll ? 4'b0101 :
    op_srl ? 4'b0110 :
    op_sra ? 4'b0111 :
    op_slt ? 4'b1000 :
    op_sltu ? 4'b1001 :
             4'b0000;

logic dec_wb_we;
assign dec_wb_we = op_add || op_sub || op_and || op_or || op_addi
                          || op_xor || op_sll || op_srl || op_sra
                          || op_slt || op_sltu;

// ID/EX Pipeline Register

logic id_ex_valid;
logic [31:0] id_ex_rs1_data;
logic [31:0] id_ex_rs2_data;
logic [31:0] id_ex_imm_i;
logic [4:0]  id_ex_rd;
logic        id_ex_wb_we;
logic [3:0]  id_ex_alu_opcode;
logic        id_ex_use_imm;
logic [31:0] id_ex_pc;

logic forward_rs1, forward_rs2;
assign forward_rs1 =
       id_ex_valid && id_ex_wb_we && (id_ex_rd != 5'b0) && (id_ex_rd == rs1);

assign forward_rs2 =
       id_ex_valid && id_ex_wb_we && (id_ex_rd != 5'b0) && (id_ex_rd == rs2);

logic [31:0] dec_rs1_val, dec_rs2_val;

assign dec_rs1_val = forward_rs1 ? wb_data : rs1_data;
assign dec_rs2_val = forward_rs2 ? wb_data : rs2_data;

always_ff @(posedge clk) begin
    if (!reset_n) begin
        id_ex_valid <= 1'b0;
        id_ex_rs1_data <= 32'b0;
        id_ex_rs2_data <= 32'b0;
        id_ex_imm_i <= 32'b0;
        id_ex_rd <= 5'b0;
        id_ex_wb_we <= 1'b0;
        id_ex_alu_opcode <= 4'b0;
        id_ex_use_imm <= 1'b0;
        id_ex_pc <= 32'b0;
    end else if (need_stall) begin
        id_ex_valid <= 1'b0;
        id_ex_wb_we <= 1'b0;
        id_ex_rd <= 5'b0;
    end else begin
        id_ex_valid <= if_id_valid;
        id_ex_rs1_data <= dec_rs1_val;
        id_ex_rs2_data <= dec_rs2_val;
        id_ex_imm_i <= imm_i;
        id_ex_rd <= rd;
        id_ex_wb_we <= dec_wb_we;
        id_ex_alu_opcode <= alu_opcode;
        id_ex_use_imm <= op_addi;
        id_ex_pc <= if_id_pc;
    end
end

// EX/WB Stage

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