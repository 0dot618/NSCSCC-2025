`include "defines.v"

module id2 (
    input wire              rst,
    input wire[`InstAddrBus] pc,
    input wire[`InstBus]    inst,

    // 从ID1接收的信号
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

    // 寄存器文件接口
    input wire[`RegBus]     reg1_data_i,
    input wire[`RegBus]     reg2_data_i,

    // 前递接口
    input wire              ex_wen_i,
    input wire[`RegBus]     ex_wdata_i,
    input wire[`RegAddrBus] ex_wreg_i,
    input wire              mem_wen_i,
    input wire[`RegBus]     mem_wdata_i,
    input wire[`RegAddrBus] mem_wreg_i,
    input wire              pre_inst_is_load,

    // 输出到EX的信号
    output reg[`AluOpBus]   alu_op,
    output wire[`RegBus]    data1,
    output wire[`RegBus]    data2,
    output reg[`RegAddrBus] wR,
    output reg              we,
    output reg[`InstAddrBus] pc_8,

    // 分支输出
    output reg              branch_flag,
    output reg[`InstAddrBus] branch_target_addr,

    // 寄存器文件控制
    output reg              re1,
    output reg              re2,
    output reg[`RegAddrBus] rR1,
    output reg[`RegAddrBus] rR2,

    // 冒险检测
    output wire             stallreq_o
);
    
    // 传递ID1的信号
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
    
    // 前递信号
    wire ex_forwarding1 = (re1_i == 1'b1 && ex_wen_i == 1'b1 && ex_wreg_i == rR1_i);
    wire ex_forwarding2 = (re2_i == 1'b1 && ex_wen_i == 1'b1 && ex_wreg_i == rR2_i);
    wire mem_forwarding1 = (re1_i == 1'b1 && mem_wen_i == 1'b1 && mem_wreg_i == rR1_i);
    wire mem_forwarding2 = (re2_i == 1'b1 && mem_wen_i == 1'b1 && mem_wreg_i == rR2_i);
    
    // 判断是否产生load冒险-使用数据冒险，如果前一条是load指令，需要暂停，使用暂停信号清空。保持当前pc不变，保持if/id寄存器的信号不变
    assign stallreq_o = (pre_inst_is_load == 1'b1 && ex_wreg_i == rR1_i && re1_i == 1'b1)
                        | (pre_inst_is_load == 1'b1 && ex_wreg_i == rR2_i && re2_i == 1'b1);
                        
    assign data1 = stallreq_o ? `ZeroWord :            // 如果load数据冒险，清空控制信号
                    ex_forwarding1 ? ex_wdata_i :      // 如果 EX 数据冒险，前递ex数据
                    mem_forwarding1 ? mem_wdata_i :    // 如果MEM 数据冒险，前递mem数据
                    re1_i ? reg1_data_i :                 // 如果为某某一寄存器，取值从寄存器堆取值
                    imm_i;                                // 否则为扩展立即数
    assign data2 = stallreq_o ? `ZeroWord :
                    ex_forwarding2 ? ex_wdata_i :
                    mem_forwarding2 ? mem_wdata_i :
                    re2_i ? reg2_data_i : 
                    imm_i;
    
    // 分支判断逻辑
    wire[5:0] op = inst[31:26];
    wire[5:0] fun = inst[5:0];
    wire fun_is_JR_JALR = (fun == `JR_FUNC) | (fun == `JALR_FUNC);
    
    // 分支条件判断
    wire eq = ~(|(data1 ^ data2));
    wire le = (data1[31] || ~(|data1));
    wire lt = data1[31];
    
    // 分支标志和地址
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
            `REGIMM_OP:     // bgez和bltz
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
    
    // 分支目标地址
    always @(*) begin
        branch_target_addr = branch_target_addr_i;
    end
    
endmodule 