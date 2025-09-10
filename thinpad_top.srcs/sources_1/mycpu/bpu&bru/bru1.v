`include "defines.v"

// 分支判断与修正单元，支持所有MIPS32分支跳转指令
module bru1 (
    input  wire[31:0]   ex_pc,         // 分支指令PC
    input  wire[5:0]    op,            // 指令操作码
    input  wire[4:0]    rt,            // rt字段
    input  wire[5:0]    fun,           // 指令功能码
    input  wire[31:0]   rdata1,        // rs
    input  wire[31:0]   rdata2,        // rt
    input  wire[31:0]   imm,           // 立即数
    // 预测信息
    input  wire         bp_taken,      // 预测是否跳转
    input  wire[31:0]   bp_target,     // 预测目标
    // 输出
    output wire         br_commit,     // 实际是否跳转（用于BTB更新）
    output wire         br_mispredict, // 是否需要修正
    output wire[31:0]   br_target      // 实际目标
);
    // 指令类型判断
    wire is_beq   = (op == `BEQ_OP);
    wire is_bne   = (op == `BNE_OP);
    wire is_bgez  = (op == `REGIMM_OP && rt == `BGEZ_RT);
    wire is_bltz  = (op == `REGIMM_OP && rt == `BLTZ_RT);
    wire is_bgtz  = (op == `BGTZ_OP);
    wire is_blez  = (op == `BLEZ_OP);
    wire is_j     = (op == `J_OP);
    wire is_jal   = (op == `JAL_OP);
    wire is_jr    = (op == `SPECIAL_OP && fun == `JR_FUNC);
    wire is_jalr  = (op == `SPECIAL_OP && fun == `JALR_FUNC);
    // 跳转条件
    wire eq = (rdata1 == rdata2);
    wire ne = (rdata1 != rdata2);
    wire lt = rdata1[31];
    wire le = (rdata1[31] || ~(|rdata1));
    // 实际跳转判断
    wire taken = (is_beq   && eq)
               || (is_bne   && ne)
               || (is_bgez  && !lt)
               || (is_bltz  && lt)
               || (is_bgtz  && !le)
               || (is_blez  && le)
               || is_j || is_jal || is_jr || is_jalr;
    // 目标地址
    wire[31:0] pc_plus_4 = ex_pc + 4;
    wire[31:0] ext_ss2 = pc_plus_4 + {{14{imm[15]}}, imm[15:0], 2'b00};
    wire[31:0] ext_za  = {pc_plus_4[31:28], imm[25:0], 2'b00};
    assign br_target = is_jr   ? rdata1 :
                      is_jalr ? rdata1 :
                      is_j    ? ext_za :
                      is_jal  ? ext_za :
                      (is_beq || is_bne || is_bgez || is_bltz || is_bgtz || is_blez) ? ext_ss2 :
                      32'b0;
    // 预测修正
    assign br_commit = taken;
    assign br_mispredict = (bp_taken != taken) || (taken && (br_target != bp_target));
endmodule 