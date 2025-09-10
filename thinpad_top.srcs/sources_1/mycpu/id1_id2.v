`include "defines.v"

module id1_id2 (
    input wire clk,
    input wire rst,
    input wire[0:5] stallreq,

    // ID1ÊäÈë
    input wire[`AluOpBus]   id1_alu_op,
    input wire              id1_re1,
    input wire              id1_re2,
    input wire[`RegAddrBus] id1_rR1,
    input wire[`RegAddrBus] id1_rR2,
    input wire[`RegAddrBus] id1_wR,
    input wire              id1_we,
    input wire[`RegBus]     id1_imm,
    input wire[`InstAddrBus] id1_pc_8,
    input wire              id1_branch_flag,
    input wire[`InstAddrBus] id1_branch_target_addr,
    input wire[`InstAddrBus] id1_pc,
    input wire[`InstBus]    id1_inst,

    // ID2Êä³ö
    output reg[`AluOpBus]   id2_alu_op,
    output reg              id2_re1,
    output reg              id2_re2,
    output reg[`RegAddrBus] id2_rR1,
    output reg[`RegAddrBus] id2_rR2,
    output reg[`RegAddrBus] id2_wR,
    output reg              id2_we,
    output reg[`RegBus]     id2_imm,
    output reg[`InstAddrBus] id2_pc_8,
    output reg              id2_branch_flag,
    output reg[`InstAddrBus] id2_branch_target_addr,
    output reg[`InstAddrBus] id2_pc,
    output reg[`InstBus]    id2_inst
);

    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            id2_alu_op <= `EXE_NOP_OP;
            id2_re1 <= 1'b0;
            id2_re2 <= 1'b0;
            id2_rR1 <= `NOPRegAddr;
            id2_rR2 <= `NOPRegAddr;
            id2_wR <= `NOPRegAddr;
            id2_we <= `WriteDisable;
            id2_imm <= `ZeroWord;
            id2_pc_8 <= `ZeroWord;
            id2_branch_flag <= `NotBranch;
            id2_branch_target_addr <= `ZeroWord;
            id2_pc <= `ZeroWord;
            id2_inst <= `ZeroWord;
        end else if(stallreq[1] == `Stop) begin
            id2_alu_op <= id2_alu_op;
            id2_re1 <= id2_re1;
            id2_re2 <= id2_re2;
            id2_rR1 <= id2_rR1;
            id2_rR2 <= id2_rR2;
            id2_wR <= id2_wR;
            id2_we <= id2_we;
            id2_imm <= id2_imm;
            id2_pc_8 <= id2_pc_8;
            id2_branch_flag <= id2_branch_flag;
            id2_branch_target_addr <= id2_branch_target_addr;
            id2_pc <= id2_pc;
            id2_inst <= id2_inst;
        end else begin
            id2_alu_op <= id1_alu_op;
            id2_re1 <= id1_re1;
            id2_re2 <= id1_re2;
            id2_rR1 <= id1_rR1;
            id2_rR2 <= id1_rR2;
            id2_wR <= id1_wR;
            id2_we <= id1_we;
            id2_imm <= id1_imm;
            id2_pc_8 <= id1_pc_8;
            id2_branch_flag <= id1_branch_flag;
            id2_branch_target_addr <= id1_branch_target_addr;
            id2_pc <= id1_pc;
            id2_inst <= id1_inst;
        end
    end

endmodule 