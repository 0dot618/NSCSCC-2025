`include "defines.v"

module id1 (
    input wire              rst,
    input wire[`InstAddrBus] pc,
    input wire[`InstBus]    inst,

    // 输出到ID2的信号
    output reg[`AluOpBus]   alu_op,
    output reg              re1,
    output reg              re2,
    output wire[`RegAddrBus] rR1,
    output wire[`RegAddrBus] rR2,
    output reg[`RegAddrBus] wR,
    output reg              we,
    output reg[`RegBus]     imm,
    output wire[`InstAddrBus] pc_8,
    
    // 分支相关信号
    output reg              branch_flag_o,
    output wire[`InstAddrBus] branch_target_addr_o
);
    
    /*----------------------解码，初始化生成控制信号--------------------------------------------------------------------*/
    wire[5:0] op = inst[31:26];
    wire[4:0] rs = inst[25:21];
    wire[4:0] rt = inst[20:16];
    wire[4:0] rd = inst[15:11];
    wire[4:0] sha = inst[10:6];
    wire[5:0] fun = inst[5:0];
    
    wire[15:0] i16 = inst[15:0];
    wire[25:0] addr = inst[25:0];
    
    wire[`InstAddrBus] pc_plus_4 = pc + 4;
    
    // 立即数扩展，符号扩展等
    wire[31:0] ext_sha = {{27'b0},sha};
    wire[31:0] ext_ss  = {{16{i16[15]}},i16};
    wire[31:0] ext_zu  = {{16'b0},i16};
    wire[31:0] ext_s16 = {i16,{16'b0}};
    wire[31:0] ext_ss2 = pc_plus_4 + {{14{i16[15]}},i16,{2'b0}};
    wire[31:0] ext_za  = {{pc_plus_4[31:28]},addr,{2'b0}};
    
    // 辅助信号
    wire fun_is_SLL_SRL_SRA = (fun == `SLL_FUNC) | (fun == `SRL_FUNC) | (fun == `SRA_FUNC);
    wire fun_is_JR_JALR = (fun == `JR_FUNC) | (fun == `JALR_FUNC);
    wire is_JR = (op == `SPECIAL_OP && fun_is_JR_JALR);
    wire is_J  = (op == `J_OP || op == `JAL_OP);
    
    // rR1和rR2：源寄存器1、2地址
    assign rR1 = inst[25:21];
    assign rR2 = inst[20:16];
    
    // pc_8：返回地址寄存器pc+8
    assign pc_8 = pc + 8;
    
    // alu_op：ALU操作码的生成
    always @(*) begin
        case(op)
            `SPECIAL_OP: begin
                case(fun)
                    `ADDU_FUNC, `ADD_FUNC:  alu_op = `EXE_ADD_OP;
                    `SUB_FUNC:              alu_op = `EXE_SUB_OP;
                    `AND_FUNC:              alu_op = `EXE_AND_OP;
                    `OR_FUNC:               alu_op = `EXE_OR_OP;
                    `XOR_FUNC:              alu_op = `EXE_XOR_OP;
                    `SLT_FUNC:              alu_op = `EXE_SLT_OP;
                    `SLL_FUNC, `SLLV_FUNC:  alu_op = `EXE_SLL_OP;
                    `SRL_FUNC, `SRLV_FUNC:  alu_op = `EXE_SRL_OP;
                    `SRA_FUNC, `SRAV_FUNC:  alu_op = `EXE_SRA_OP;
                    `JALR_FUNC:             alu_op = `EXE_JAL_OP;
                    default:                alu_op = `EXE_NOP_OP;   // 分支跳转不写回、jr等
                endcase
            end
            `MUL_OP:            alu_op = `EXE_MUL_OP;
            `ADDIU_OP,`ADDI_OP: alu_op = `EXE_ADD_OP;
            `ANDI_OP:           alu_op = `EXE_AND_OP;
            `ORI_OP:            alu_op = `EXE_OR_OP;
            `XORI_OP:           alu_op = `EXE_XOR_OP;
            `LUI_OP:            alu_op = `EXE_OR_OP;    // 立即数 | 全0 = 立即数
            `LB_OP:             alu_op = `EXE_LB_OP;
            `SB_OP:             alu_op = `EXE_SB_OP;
            `LW_OP:             alu_op = `EXE_LW_OP;
            `SW_OP:             alu_op = `EXE_SW_OP;
            `JAL_OP:            alu_op = `EXE_JAL_OP;
            default:            alu_op = `EXE_NOP_OP;   // 其他分支跳转不写回、j、B类指令*6、S类指令*2
        endcase
    end
    
    // re1：源寄存器1的使用
    always @(*) begin
        case(op)
            `SPECIAL_OP:
                re1 = (fun_is_SLL_SRL_SRA) ? 1'b0 : 1'b1;
            `LUI_OP, `J_OP, `JAL_OP:
                re1 = 1'b0;
            default: 
                re1 = 1'b1;
        endcase
    end
    
    // re2：源寄存器2的使用
    always @(*) begin
        case(op)
            `SPECIAL_OP:      
                re2 = (fun_is_JR_JALR) ? 1'b0 : 1'b1;
            `MUL_OP, `BEQ_OP, `BNE_OP, `SW_OP, `SB_OP: 
                re2 = 1'b1;
            default:    
                re2 = 1'b0;
        endcase
    end
    
    // imm：立即数扩展
    always @(*) begin
        case(op)
            `SPECIAL_OP:      
                imm = fun_is_SLL_SRL_SRA ? ext_sha : `ZeroWord;
            `ADDIU_OP, `ADDI_OP,  `LW_OP,  `LB_OP, `SW_OP, `SB_OP:   
                imm = ext_ss;
            `ANDI_OP,  `ORI_OP,  `XORI_OP:   
                imm = ext_zu; 
            `LUI_OP:    
                imm = ext_s16;
            default:    
                imm = `ZeroWord;
        endcase
    end
    
    // we：目的寄存器写入使能
    always @(*) begin
        case(op) 
            `SPECIAL_OP:   // 只有 jr 指令分支跳转不写回
                we = ((fun == `JR_FUNC)) ? `WriteDisable : `WriteEnable;
            `MUL_OP, `ADDIU_OP, `ADDI_OP, `ANDI_OP, `ORI_OP, `XORI_OP,
            `LUI_OP, `JAL_OP,   `LW_OP,   `LB_OP: 
                we = `WriteEnable;
            default:        // 其他分支跳转不写寄存器、j、B类指令*6、S类指令*2
                we = `WriteDisable;
        endcase
    end
    
    // wR：目的寄存器地址，写入使能为0的不必管
    always @(*) begin
        case(op)
            `SPECIAL_OP,`MUL_OP:    
                wR = rd;
            `JAL_OP:
                wR = 5'b11111;
            `ADDIU_OP, `ADDI_OP, `ANDI_OP, `ORI_OP, `XORI_OP, `LUI_OP,   `LW_OP,   `LB_OP:    
                wR = rt;
            default:    
                wR = rd;
        endcase
    end
    
    // branch_flag_o：判断是否需要跳转
    always @(*) begin
        case(op)
            `SPECIAL_OP:      
                branch_flag_o = fun_is_JR_JALR ? `Branch : `NotBranch;
            `J_OP,  `JAL_OP:    
                branch_flag_o = `Branch;
            `BEQ_OP:    
                branch_flag_o = `NotBranch;  // 在ID2中根据数据判断
            `BNE_OP:    
                branch_flag_o = `NotBranch;  // 在ID2中根据数据判断
            `REGIMM_OP:     // bgez和bltz
                branch_flag_o = `NotBranch;  // 在ID2中根据数据判断
            `BGTZ_OP:    
                branch_flag_o = `NotBranch;  // 在ID2中根据数据判断
            `BLEZ_OP:    
                branch_flag_o = `NotBranch;  // 在ID2中根据数据判断
            default:    
                branch_flag_o = `NotBranch;
        endcase
    end
    
    // branch_target_addr_o：跳转地址
    assign branch_target_addr_o = is_JR ? `ZeroWord :  // 对于 JR 类指令，跳转到 rd寄存器 的内容数据地址
                                  is_J ? ext_za :   // 对于 J  类指令，跳转到 za  扩展立即数
                                  ext_ss2;          // 对于 B  类指令，跳转到 ss2 扩展立即数
    
endmodule 