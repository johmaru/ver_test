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