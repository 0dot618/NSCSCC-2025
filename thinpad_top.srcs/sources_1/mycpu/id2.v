`include "defines.v"

module id2 (
    input wire              rst,
    input wire[`InstAddrBus] pc,
    input wire[`InstBus]    inst,

    // ��ID1���յ��ź�
    input wire[`AluOpBus]   alu_op_i,
    input wire              re1_i,
    input wire              re2_i,
    input wire[`RegAddrBus] rR1_i,
    input wire[`RegAddrBus] rR2_i,
    input wire[`RegAddrBus] wR_i,
    input wire              we_i,
    input wire[`RegBus]     imm_i,
    input wire[`InstAddrBus] pc_8_i,
    input wire              branch_flag_i,
    input wire[`InstAddrBus] branch_target_addr_i,

    // �Ĵ����ļ��ӿ�
    input wire[`RegBus]     reg1_data_i,
    input wire[`RegBus]     reg2_data_i,

    // ǰ�ݽӿ�
    input wire              ex_wen_i,
    input wire[`RegBus]     ex_wdata_i,
    input wire[`RegAddrBus] ex_wreg_i,
    input wire              mem_wen_i,
    input wire[`RegBus]     mem_wdata_i,
    input wire[`RegAddrBus] mem_wreg_i,
    input wire              pre_inst_is_load,

    // �����EX���ź�
    output reg[`AluOpBus]   alu_op,
    output wire[`RegBus]    data1,
    output wire[`RegBus]    data2,
    output reg[`RegAddrBus] wR,
    output reg              we,
    output reg[`InstAddrBus] pc_8,

    // ��֧���
    output reg              branch_flag,
    output reg[`InstAddrBus] branch_target_addr,

    // �Ĵ����ļ�����
    output reg              re1,
    output reg              re2,
    output reg[`RegAddrBus] rR1,
    output reg[`RegAddrBus] rR2,

    // ð�ռ��
    output wire             stallreq_o
);
    
    // ����ID1���ź�
    always @(*) begin
        alu_op = alu_op_i;
        wR = wR_i;
        we = we_i;
        pc_8 = pc_8_i;
        re1 = re1_i;
        re2 = re2_i;
        rR1 = rR1_i;
        rR2 = rR2_i;
    end
    
    // ǰ���ź�
    wire ex_forwarding1 = (re1_i == 1'b1 && ex_wen_i == 1'b1 && ex_wreg_i == rR1_i);
    wire ex_forwarding2 = (re2_i == 1'b1 && ex_wen_i == 1'b1 && ex_wreg_i == rR2_i);
    wire mem_forwarding1 = (re1_i == 1'b1 && mem_wen_i == 1'b1 && mem_wreg_i == rR1_i);
    wire mem_forwarding2 = (re2_i == 1'b1 && mem_wen_i == 1'b1 && mem_wreg_i == rR2_i);
    
    // �ж��Ƿ����loadð��-ʹ������ð�գ����ǰһ����loadָ���Ҫ��ͣ��ʹ����ͣ�ź���ա����ֵ�ǰpc���䣬����if/id�Ĵ������źŲ���
    assign stallreq_o = (pre_inst_is_load == 1'b1 && ex_wreg_i == rR1_i && re1_i == 1'b1)
                        | (pre_inst_is_load == 1'b1 && ex_wreg_i == rR2_i && re2_i == 1'b1);
                        
    assign data1 = stallreq_o ? `ZeroWord :            // ���load����ð�գ���տ����ź�
                    ex_forwarding1 ? ex_wdata_i :      // ��� EX ����ð�գ�ǰ��ex����
                    mem_forwarding1 ? mem_wdata_i :    // ���MEM ����ð�գ�ǰ��mem����
                    re1_i ? reg1_data_i :                 // ���Ϊĳĳһ�Ĵ�����ȡֵ�ӼĴ�����ȡֵ
                    imm_i;                                // ����Ϊ��չ������
    assign data2 = stallreq_o ? `ZeroWord :
                    ex_forwarding2 ? ex_wdata_i :
                    mem_forwarding2 ? mem_wdata_i :
                    re2_i ? reg2_data_i : 
                    imm_i;
    
    // ��֧�ж��߼�
    wire[5:0] op = inst[31:26];
    wire[5:0] fun = inst[5:0];
    wire fun_is_JR_JALR = (fun == `JR_FUNC) | (fun == `JALR_FUNC);
    
    // ��֧�����ж�
    wire eq = ~(|(data1 ^ data2));
    wire le = (data1[31] || ~(|data1));
    wire lt = data1[31];
    
    // ��֧��־�͵�ַ
    always @(*) begin
        case(op)
            `SPECIAL_OP:      
                branch_flag = fun_is_JR_JALR ? `Branch : branch_flag_i;
            `J_OP,  `JAL_OP:    
                branch_flag = `Branch;
            `BEQ_OP:    
                branch_flag = eq ? `Branch : `NotBranch;
            `BNE_OP:    
                branch_flag = !eq ? `Branch : `NotBranch;
            `REGIMM_OP:     // bgez��bltz
                branch_flag = (inst[20:16] == `BGEZ_RT && !lt) ? `Branch : 
                              (inst[20:16] == `BLTZ_RT && lt) ? `Branch : `NotBranch;
            `BGTZ_OP:    
                branch_flag = !le ? `Branch : `NotBranch;
            `BLEZ_OP:    
                branch_flag = le  ? `Branch : `NotBranch;
            default:    
                branch_flag = branch_flag_i;
        endcase
    end
    
    // ��֧Ŀ���ַ
    always @(*) begin
        branch_target_addr = branch_target_addr_i;
    end
    
endmodule 