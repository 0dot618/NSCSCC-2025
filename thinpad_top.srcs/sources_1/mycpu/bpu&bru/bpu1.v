`include "defines.v"

// 4·BTB��֧Ԥ�ⵥԪ��֧������MIPS32��֧��תָ��
module bpu1 (
    input  wire         clk,
    input  wire         rst,
    // ID�׶�����
    input  wire         id_ce,
    input  wire[31:0]   id_pc,
    // EX�׶�����
    input  wire         ex_br_commit,   // EX�׶η�ָ֧��ʵ����ת
    input  wire[31:0]   ex_pc,
    input  wire[31:0]   ex_br_target,
    // Ԥ�����
    output wire         bp_taken,
    output wire[31:0]   bp_target
);
    // 4·BTB
    reg [31:0] btb_pc     [3:0];
    reg [31:0] btb_target [3:0];
    reg [3:0]  btb_valid;
    // �����ж�
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
    // BTB���£����ֻ��滻���ԣ�
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