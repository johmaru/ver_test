module regfile32 (
    input wire clk,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2
);

    reg [31:0] regs [0:31];

    assign rdata1 = (raddr1 == 5'd0) ? 32'b0 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'b0 : regs[raddr2];

    always @(posedge clk) begin
        if (we && (waddr != 5'd0)) begin
            regs[waddr] <= wdata;
        end
    end
endmodule

module cpu_top (
    input clk,
    input reset_n,
    
    input wire imem_req_ready,
    input wire imem_resp_valid,
    input wire [31:0] imem_resp_data,
    output wire imem_req_valid,
    output wire [31:0] imem_req_addr,
    output wire imem_resp_ready
);

wire [31:0] pc_current;
wire [31:0] pc_next;
wire pc_en;

pc_reg u_pc (
    .clk(clk),
    .reset_n(reset_n),
    .pc_en(pc_en),
    .pc_next(pc_next),
    .pc_current(pc_current)
);

fetch_stage u_fetch (
    .clk(clk),
    .reset_n(reset_n),
    .imem_req_ready(imem_req_ready),
    .imem_resp_valid(imem_resp_valid),
    .imem_resp_data(imem_resp_data),
    .pc_current(pc_current),
    .imem_req_valid(imem_req_valid),
    .imem_req_addr(imem_req_addr),
    .imem_resp_ready(imem_resp_ready)
);

wire imem_req_fire = imem_req_valid && imem_req_ready;
wire imem_resp_fire = imem_resp_valid && imem_resp_ready;

assign pc_next = pc_current + 32'd4;
assign pc_en = imem_resp_fire;

reg if_id_valid;
reg [31:0] if_id_inst;

wire consume = if_id_valid;

always @(posedge clk) begin
    if (!reset_n) begin
        if_id_valid <= 1'b0;
        if_id_inst <= 32'b0;
    end else begin
        if (imem_resp_fire && (!if_id_valid || consume)) begin
            if_id_inst <= imem_resp_data;
        end
        if_id_valid <= (if_id_valid && !consume) ? 1'b1
                    : (imem_resp_fire ? 1'b1 : 1'b0);
    end
end

wire [6:0] opcode;
wire [4:0] rd;
wire [2:0] funct3;
wire [4:0] rs1;
wire [4:0] rs2;
wire [6:0] funct7;
wire [31:0] imm_i;
wire [4:0] shamt;

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

wire [31:0] rs1_data;
wire [31:0] rs2_data;

wire wb_we;
wire [4:0] wb_rd;
wire [31:0] wb_data;

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

wire is_rtype = (opcode == 7'b0110011);
wire is_itype = (opcode == 7'b0010011);

wire op_add = is_rtype && (funct3 == 3'b000) && (funct7 == 7'b0000000);
wire op_sub = is_rtype && (funct3 == 3'b000) && (funct7 == 7'b0100000);
wire op_and = is_rtype && (funct3 == 3'b111) && (funct7 == 7'b0000000);
wire op_or  = is_rtype && (funct3 == 3'b110) && (funct7 == 7'b0000000);
wire op_addi = is_itype && (funct3 == 3'b000);

wire [31:0] alu_in2 = op_addi ? imm_i : rs2_data;

wire [3:0] alu_opcode =
    op_sub ? 4'b0001 :
    op_and ? 4'b0010 :
    op_or  ? 4'b0011 :
             4'b0000;

wire [31:0] alu_res;
wire alu_zero;

alu u_alu (
    .a(rs1_data),
    .b(alu_in2),
    .opcode(alu_opcode),
    .result(alu_res),
    .zero(alu_zero)
);

wire dec_wb_we = op_add || op_sub || op_and || op_or || op_addi;

assign wb_we = if_id_valid && dec_wb_we;
assign wb_rd = rd;
assign wb_data = alu_res;

endmodule