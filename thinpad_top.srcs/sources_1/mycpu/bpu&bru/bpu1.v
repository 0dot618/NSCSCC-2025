`include "defines.v"

// 4路BTB分支预测单元，支持所有MIPS32分支跳转指令
module bpu1 (
    input  wire         clk,
    input  wire         rst,
    // ID阶段输入
    input  wire         id_ce,
    input  wire[31:0]   id_pc,
    // EX阶段输入
    input  wire         ex_br_commit,   // EX阶段分支指令实际跳转
    input  wire[31:0]   ex_pc,
    input  wire[31:0]   ex_br_target,
    // 预测输出
    output wire         bp_taken,
    output wire[31:0]   bp_target
);
    // 4路BTB
    reg [31:0] btb_pc     [3:0];
    reg [31:0] btb_target [3:0];
    reg [3:0]  btb_valid;
    // 命中判断
    wire [3:0] way_hit;
    assign way_hit[0] = btb_valid[0] && (btb_pc[0] == id_pc);
    assign way_hit[1] = btb_valid[1] && (btb_pc[1] == id_pc);
    assign way_hit[2] = btb_valid[2] && (btb_pc[2] == id_pc);
    assign way_hit[3] = btb_valid[3] && (btb_pc[3] == id_pc);
    assign bp_taken  = |way_hit && id_ce;
    assign bp_target = way_hit[3] ? btb_target[3] :
                       way_hit[2] ? btb_target[2] :
                       way_hit[1] ? btb_target[1] :
                       way_hit[0] ? btb_target[0] : 32'b0;
    // BTB更新（简单轮换替换策略）
    reg [1:0] replace_ptr;
    always @(posedge clk) begin
        if (rst) begin
            btb_valid <= 4'b0;
            btb_pc[0] <= 32'b0; btb_pc[1] <= 32'b0; btb_pc[2] <= 32'b0; btb_pc[3] <= 32'b0;
            btb_target[0] <= 32'b0; btb_target[1] <= 32'b0; btb_target[2] <= 32'b0; btb_target[3] <= 32'b0;
            replace_ptr <= 2'b0;
        end else if (ex_br_commit) begin
            btb_pc[replace_ptr]     <= ex_pc;
            btb_target[replace_ptr] <= ex_br_target;
            btb_valid[replace_ptr]  <= 1'b1;
            replace_ptr <= replace_ptr + 1'b1;
        end
    end
endmodule 