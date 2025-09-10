`timescale 1ns / 1ps
`define BHT_IDX_W 10                    // ������λ������10λ����1024�
`define BHT_ENTRY (1 << `BHT_IDX_W)     // BHT/BTB �������
`define BHT_TAG_W 8                     // tag�ֶ�λ������BTB����ƥ�䣩

module BPU (
    input  wire         cpu_clk,
    input  wire         cpu_rstn,

    // Ԥ��׶Σ�ID��
    input  wire         if_valid,
    input  wire [31:0]  if_pc,
    output wire [31:0]  pred_target_o,
    output wire         pred_error,

    // ��д�׶Σ�EX��
    input  wire         ex_valid,
    input  wire         ex_is_bj,
    input  wire [31:0]  ex_pc,
    input  wire         real_taken,
    input  wire [31:0]  real_target
);

    // ----------- BHT + BTB ------------
    reg  [`BHT_TAG_W-1:0] tag     [`BHT_ENTRY-1:0];
    reg                  valid    [`BHT_ENTRY-1:0];
    reg  [1:0]           history  [`BHT_ENTRY-1:0]; // 2λ���ͼ�����
    reg  [31:0]          target   [`BHT_ENTRY-1:0];
    
    // ----------- �����������ǩ ------------
    wire [31:0] pc_hash = if_pc ^ (if_pc >> 2);  // �򵥵�ַ�۵� hash
    wire [`BHT_IDX_W-1:0] index_if = pc_hash[`BHT_IDX_W+1:2];
    wire [`BHT_TAG_W-1:0] tag_if   = if_pc[`BHT_TAG_W+1:2];
    
    wire [31:0] ex_hash = ex_pc ^ (ex_pc >> 2);
    wire [`BHT_IDX_W-1:0] index_ex = ex_hash[`BHT_IDX_W+1:2];
    wire [`BHT_TAG_W-1:0] tag_ex   = ex_pc[`BHT_TAG_W+1:2];
    
    // ----------- Ԥ���߼� ------------
    wire is_hit = valid[index_if] && (tag[index_if] == tag_if);
    wire [1:0] counter = history[index_if];
    wire pred_taken = is_hit && counter[1];  // ��λΪ1��ʾ��ƫ����ת��
    wire [31:0] pred_target = is_hit ? target[index_if] : (if_pc + 4);
    
    // �ӳٲ�Ԥ��������
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
    
    // ----------- �����߼� ------------
    wire taken_error  = (!pred_taken_r && real_taken);
    wire not_taken_error = (pred_taken_r && !real_taken);
    wire target_error = (pred_taken_r && real_taken && (pred_target_r != real_target));
    
    assign pred_error = ex_valid && ex_is_bj && (taken_error || not_taken_error || target_error);
    
    integer i;
    // ----------- BHT + BTB ���� ------------
    always @(posedge cpu_clk or negedge cpu_rstn) begin
        if (!cpu_rstn) begin
            for (i = 0; i < `BHT_ENTRY; i = i + 1) begin
                valid[i]   <= 1'b0;
                history[i] <= 2'b10;  // ��ʼ��Ϊ������ת��
            end
        end else if (ex_valid && ex_is_bj) begin
            if (valid[index_ex] && tag[index_ex] == tag_ex) begin
                // ��������¼�������Ŀ���ַ
                if (real_taken) begin
                    if (history[index_ex] != 2'b11)
                        history[index_ex] <= history[index_ex] + 1;
                end else begin
                    if (history[index_ex] != 2'b00)
                        history[index_ex] <= history[index_ex] - 1;
                end
                target[index_ex] <= real_target;
            end else begin
                // ���������滻����
                valid[index_ex]   <= 1'b1;
                tag[index_ex]     <= tag_ex;
                history[index_ex] <= real_taken ? 2'b10 : 2'b01; // ��ʼ��Ϊ����ת/����ת
                target[index_ex]  <= real_target;
            end
        end
    end

endmodule
