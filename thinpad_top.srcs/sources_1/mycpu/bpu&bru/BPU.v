`timescale 1ns / 1ps
`define BHT_IDX_W 10                    // 表索引位宽（例如10位，共1024项）
`define BHT_ENTRY (1 << `BHT_IDX_W)     // BHT/BTB 表项个数
`define BHT_TAG_W 8                     // tag字段位宽（用于BTB索引匹配）

module BPU (
    input  wire         cpu_clk,
    input  wire         cpu_rstn,

    // 预测阶段（ID）
    input  wire         if_valid,
    input  wire [31:0]  if_pc,
    output wire [31:0]  pred_target_o,
    output wire         pred_error,

    // 回写阶段（EX）
    input  wire         ex_valid,
    input  wire         ex_is_bj,
    input  wire [31:0]  ex_pc,
    input  wire         real_taken,
    input  wire [31:0]  real_target
);

    // ----------- BHT + BTB ------------
    reg  [`BHT_TAG_W-1:0] tag     [`BHT_ENTRY-1:0];
    reg                  valid    [`BHT_ENTRY-1:0];
    reg  [1:0]           history  [`BHT_ENTRY-1:0]; // 2位饱和计数器
    reg  [31:0]          target   [`BHT_ENTRY-1:0];
    
    // ----------- 计算索引与标签 ------------
    wire [31:0] pc_hash = if_pc ^ (if_pc >> 2);  // 简单地址折叠 hash
    wire [`BHT_IDX_W-1:0] index_if = pc_hash[`BHT_IDX_W+1:2];
    wire [`BHT_TAG_W-1:0] tag_if   = if_pc[`BHT_TAG_W+1:2];
    
    wire [31:0] ex_hash = ex_pc ^ (ex_pc >> 2);
    wire [`BHT_IDX_W-1:0] index_ex = ex_hash[`BHT_IDX_W+1:2];
    wire [`BHT_TAG_W-1:0] tag_ex   = ex_pc[`BHT_TAG_W+1:2];
    
    // ----------- 预测逻辑 ------------
    wire is_hit = valid[index_if] && (tag[index_if] == tag_if);
    wire [1:0] counter = history[index_if];
    wire pred_taken = is_hit && counter[1];  // 高位为1表示“偏向跳转”
    wire [31:0] pred_target = is_hit ? target[index_if] : (if_pc + 4);
    
    // 延迟槽预测结果缓存
    reg  pred_taken_r;
    reg  [31:0] pred_target_r;
    reg  [`BHT_IDX_W-1:0] pred_index_r;
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            pred_taken_r   <= 1'b0;
            pred_target_r  <= 32'b0;
            pred_index_r   <= {`BHT_IDX_W{1'b0}};
        end else if (if_valid) begin
            pred_taken_r   <= pred_taken;
            pred_target_r  <= pred_target;
            pred_index_r   <= index_if;
        end
    end
    
    assign pred_target_o = pred_taken_r ? pred_target_r : if_pc + 4;
    
    // ----------- 纠错逻辑 ------------
    wire taken_error  = (!pred_taken_r && real_taken);
    wire not_taken_error = (pred_taken_r && !real_taken);
    wire target_error = (pred_taken_r && real_taken && (pred_target_r != real_target));
    
    assign pred_error = ex_valid && ex_is_bj && (taken_error || not_taken_error || target_error);
    
    integer i;
    // ----------- BHT + BTB 更新 ------------
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            for (i = 0; i < `BHT_ENTRY; i = i + 1) begin
                valid[i]   <= 1'b0;
                history[i] <= 2'b10;  // 初始化为“弱跳转”
            end
        end else if (ex_valid && ex_is_bj) begin
            if (valid[index_ex] && tag[index_ex] == tag_ex) begin
                // 命中则更新计数器和目标地址
                if (real_taken) begin
                    if (history[index_ex] != 2'b11)
                        history[index_ex] <= history[index_ex] + 1;
                end else begin
                    if (history[index_ex] != 2'b00)
                        history[index_ex] <= history[index_ex] - 1;
                end
                target[index_ex] <= real_target;
            end else begin
                // 不命中则替换表项
                valid[index_ex]   <= 1'b1;
                tag[index_ex]     <= tag_ex;
                history[index_ex] <= real_taken ? 2'b10 : 2'b01; // 初始化为弱跳转/不跳转
                target[index_ex]  <= real_target;
            end
        end
    end

endmodule
