// ���ɵ�ǰex�׶ε�׼ȷ��֧��ת������Ƿ�����PC������Ŀ�ĵ�ַ��
`include "defines.v"

module BRU(
    input wire [31:0]   pc,
    input wire [3:0]    BJ_op,
    input wire [31:0]   rdata1,
    input wire [31:0]   rdata2,
    input wire [31:0]   imm,        // ��ת��ַ����jr��jalr��
    input wire          bp_jump,
    input wire [31:0]   bp_target,
    output wire         br_taken,
    output wire [31:0]  br_target
);
    wire eq = ~(|(rdata1 ^ rdata2));
    wire le = (rdata1[31] || ~(|rdata1));
    wire lt = rdata1[31];
    
    reg jump;
    wire [31:0] target;
    // jump
    always @(*) begin
        case(BJ_op)
            `J, `JR, `JAL, `JALR:   
                    jump = `Branch;
            `BEQ:   jump = eq ? `Branch : `NotBranch;
            `BNE:   jump = !eq ? `Branch : `NotBranch;
            `BGEZ:  jump = !lt ? `Branch : `NotBranch;
            `BGTZ:  jump = !le ? `Branch : `NotBranch;
            `BLEZ:  jump = le  ? `Branch : `NotBranch;
            `BLTZ:  jump = lt ? `Branch : `NotBranch;
            default:    
                jump = `NotBranch;
        endcase
    end
    // target
    assign target = (BJ_op==`JR || BJ_op==`JALR) ? rdata1 : imm;
    
    wire jump_error = (!bp_jump && jump)    // ����ȴû��
                        || (bp_jump && jump && (|(bp_target ^ target)));    // �����ַ��
    wire not_jump_error = bp_jump && !jump; // ������ȴ����
    assign br_taken  = jump_error || not_jump_error;
    assign br_target = jump_error ? target : pc + 8;
    
endmodule
