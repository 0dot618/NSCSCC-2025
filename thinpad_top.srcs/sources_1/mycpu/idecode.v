// 实现load-use冒险的前递和暂停
// 当前支持分支预测和转移判断，原来在ex阶段进行，现在提前到id阶段，
`include "defines.v"

module idecode (
    input wire              rst,
    input wire[`InstAddrBus] pc,
    input wire[`InstBus]    inst,

    input wire[`RegBus]     rD1,
    input wire[`RegBus]     rD2,

    // 数据前递信号。需要用到当前指令的目标寄存器数据。
	// 来自ex执行阶段的指令要写入的目标寄存器信息，用于EX阶段前递。
    input wire              ex_wen_i,
    input wire[`RegBus]     ex_wdata_i,
    input wire[`RegAddrBus] ex_wR_i,
	// 来自mem阶段阶段的指令要写入的目标寄存器信息，用于MEM阶段前递。
    input wire              mem_wen_i,
    input wire[`RegBus]     mem_wdata_i,
    input wire[`RegAddrBus] mem_wR_i,
    
    // 暂停信号，用于load指令
    // 来自ex执行阶段的指令的一些信息，用于解决load-use冒险
    input wire              pre_inst_is_load,

    //regfile
    output wire              re1,
    output wire              re2,
    output wire[`RegAddrBus] rR1,
    output wire[`RegAddrBus] rR2,
    //ex
    output wire[`AluOpBus]  alu_op,
    output wire[`RegBus]    data1, //源1
    output wire[`RegBus]    data2, //源2
    output wire[`RegAddrBus] wR,
    output wire              we, 
    //转移
    output wire                 branch_flag_o,
    output wire[`InstAddrBus]   branch_target_addr_o,
    output wire[`InstAddrBus]   pc_8,    // 保存的pc+8

    output wire             stallreq_o    //流水线暂停
);
    
    /*----------------------指令解码，开始解码信号--------------------------------------------------------------------*/
    wire[5:0] op = inst[31:26];
    wire[4:0] rs = inst[25:21];
    wire[4:0] rt = inst[20:16];
    wire[4:0] rd = inst[15:11];
    wire[4:0] sha = inst[10:6];
    wire[5:0] fun = inst[5:0];
    
    wire[15:0] i16 = inst[15:0];
    wire[25:0] addr = inst[25:0];
    
    wire[`InstAddrBus] pc_plus_4 = pc + 4;
    
    wire[`RegBus] imm; //立即数的最终输出
    
    // 使用硬件指令识别
    wire[63:0] op_d, func_d;
    wire[31:0] rs_d, rt_d, rd_d, sha_d;
    
    decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
    decoder_6_64 u_dec1(.in(fun ), .out(func_d));
    decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
    decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
    decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
    decoder_5_32 u_dec5(.in(sha ), .out(sha_d ));
    
    // 指令识别使用位
    wire inst_add    = op_d[6'h00] & func_d[6'h20] & sha_d[5'h00];
    wire inst_addu   = op_d[6'h00] & func_d[6'h21] & sha_d[5'h00];
    wire inst_sub    = op_d[6'h00] & func_d[6'h22] & sha_d[5'h00];
    wire inst_subu   = op_d[6'h00] & func_d[6'h23] & sha_d[5'h00];
    wire inst_slt    = op_d[6'h00] & func_d[6'h2a] & sha_d[5'h00];
    wire inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sha_d[5'h00];
    wire inst_and    = op_d[6'h00] & func_d[6'h24] & sha_d[5'h00];
    wire inst_or     = op_d[6'h00] & func_d[6'h25] & sha_d[5'h00];
    wire inst_xor    = op_d[6'h00] & func_d[6'h26] & sha_d[5'h00];
    wire inst_nor    = op_d[6'h00] & func_d[6'h27] & sha_d[5'h00];
    wire inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
    wire inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
    wire inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
    wire inst_sllv   = op_d[6'h00] & func_d[6'h04] & sha_d[5'h00];
    wire inst_srlv   = op_d[6'h00] & func_d[6'h06] & sha_d[5'h00];
    wire inst_srav   = op_d[6'h00] & func_d[6'h07] & sha_d[5'h00];
    wire inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sha_d[5'h00];
    wire inst_jalr   = op_d[6'h00] & func_d[6'h09] & rt_d[5'h00];
    wire inst_mul    = op_d[6'h1c] & func_d[6'h02] & sha_d[5'h00];
    
    wire inst_addi   = op_d[6'h08];
    wire inst_addiu  = op_d[6'h09];
    wire inst_andi   = op_d[6'h0c];
    wire inst_ori    = op_d[6'h0d];
    wire inst_xori   = op_d[6'h0e];
    wire inst_lui    = op_d[6'h0f] & rs_d[5'h00];
    wire inst_slti   = op_d[6'h0a];
    wire inst_sltiu  = op_d[6'h0b];
    wire inst_beq    = op_d[6'h04];
    wire inst_bne    = op_d[6'h05];
    wire inst_bgez   = op_d[6'h01] & rt_d[5'h01];
    wire inst_bgtz   = op_d[6'h07] & rt_d[5'h00];
    wire inst_blez   = op_d[6'h06] & rt_d[5'h00];
    wire inst_bltz   = op_d[6'h01] & rt_d[5'h00];
    wire inst_j      = op_d[6'h02];
    wire inst_jal    = op_d[6'h03];
    
    wire inst_lb     = op_d[6'h20];
    wire inst_lh     = op_d[6'h21];
    wire inst_lw     = op_d[6'h23];
    wire inst_sb     = op_d[6'h28];
    wire inst_sh     = op_d[6'h29];
    wire inst_sw     = op_d[6'h2b];
    
    // alu_op：待写回数据的计算
    assign alu_op  = ({5{inst_add | inst_addu | inst_addi | inst_addiu}} & `EXE_ADD_OP)         
                  | ({5{inst_sub | inst_subu}}  & `EXE_SUB_OP)
                  | ({5{inst_slt | inst_slti}}  & `EXE_SLT_OP)
                  | ({5{inst_sltu | inst_sltiu}}& `EXE_SLTU_OP)
                  | ({5{inst_and | inst_andi}}  & `EXE_AND_OP)
                  | ({5{inst_or | inst_ori}}    & `EXE_OR_OP)
                  | ({5{inst_xor | inst_xori}}  & `EXE_XOR_OP)
                  | ({5{inst_nor}}              & `EXE_NOR_OP)
                  | ({5{inst_sll | inst_sllv}}  & `EXE_SLL_OP)
                  | ({5{inst_srl | inst_srlv}}  & `EXE_SRL_OP)
                  | ({5{inst_sra | inst_srav}}  & `EXE_SRA_OP)
                  | ({5{inst_lui}}              & `EXE_OR_OP)    // 立即数 | 全0 = 立即数
                  | ({5{inst_mul}}              & `EXE_MUL_OP)
                  | ({5{inst_jalr | inst_jal}}  & `EXE_JAL_OP)
                  | ({5{inst_lb}}               & `EXE_LB_OP)
                  | ({5{inst_sb}}               & `EXE_SB_OP)
                  | ({5{inst_lw}}               & `EXE_LW_OP)
                  | ({5{inst_sw}}               & `EXE_SW_OP)
                  | ({5'b11111}                 & `EXE_NOP_OP);   // 其余均跳转，无需写回【jr、j、B型指令*6】
    
    // re1：源寄存器1读使能
    assign re1 = inst_add | inst_addu | inst_addi | inst_addiu | inst_sub | inst_subu | 
                 inst_slt |  inst_slti | inst_sltiu | inst_mul | inst_and | inst_nor |
                 inst_or | inst_xor | inst_andi | inst_ori | inst_xori | inst_sltu | 
                 inst_sllv | inst_srlv | inst_srav | inst_beq | inst_bne | 
                 inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_lb | 
                 inst_lw | inst_sb | inst_sw | inst_jalr | inst_jr;
    
    // re2：源寄存器2读使能
    assign re2 = inst_add | inst_addu | inst_sub | inst_slt | inst_mul | inst_subu |
                 inst_and | inst_or | inst_xor | inst_sllv | inst_srlv | inst_nor |
                 inst_srav | inst_beq | inst_bne | inst_sll | inst_srl | inst_sltu |
                 inst_sra | inst_sb | inst_sw;
                        
    // rR1、rR2：源寄存器1、2地址
    assign rR1 = inst[25:21];
    assign rR2 = inst[20:16];
    
    // imm：立即数扩展
    wire ext_sha    = inst_sll | inst_srl | inst_sra;
    wire ext_ss     = inst_addi | inst_addiu | inst_lb | inst_lw | inst_sb | inst_sw | inst_slti | inst_sltiu;
    wire ext_zu     = inst_andi | inst_ori | inst_xori;
    wire ext_s16    = inst_lui;
    
    // 立即数生成 - 使用位操作并行化
    assign imm = ({32{ext_sha}} & {27'b0, sha[4:0]})         
               | ({32{ext_ss}}  & {{16{i16[15]}}, i16[15:0]})
               | ({32{ext_zu}}  & {16'b0, i16[15:0]})
               | ({32{ext_s16}} & {i16,{16'b0}});
    
    // 两个操作数输出
    // 前递信号 
    wire ex_forwarding1 = (re1 && ex_wen_i && ~|(rR1 ^ ex_wR_i));
    wire ex_forwarding2 = (re2 && ex_wen_i && ~|(rR2 ^ ex_wR_i));
    wire mem_forwarding1 = (re1 && mem_wen_i && ~|(rR1 ^ mem_wR_i));
    wire mem_forwarding2 = (re2 && mem_wen_i && ~|(rR2 ^ mem_wR_i));
    // 判断是否出现load加载-使用数据冒险，若出现需要使用暂停，使控制信号清空、保持当前pc不变，保持if/id寄存器各信号不变
    assign stallreq_o = (pre_inst_is_load && ~|(ex_wR_i ^ rR1) && re1)
                        | (pre_inst_is_load && ~|(ex_wR_i ^ rR2) && re2);
    
    assign data1 = stallreq_o ? `ZeroWord :             // 如果load数据冒险，清空控制信号
                    ex_forwarding1 ? ex_wdata_i :       // 如果 EX 数据冒险，前递ex数据
                    mem_forwarding1 ? mem_wdata_i :     // 如果MEM 数据冒险，前递mem数据
                    re1 ? rD1 :                         // 如果为读某一寄存器的值，从寄存器堆取值
                    imm;                                // 否则为扩展后的立即数
    assign data2 = stallreq_o ? `ZeroWord :
                    ex_forwarding2 ? ex_wdata_i :
                    mem_forwarding2 ? mem_wdata_i :
                    re2 ? rD2 : 
                    imm;
    
    // we：目的寄存器写回使能
    assign we = (inst_mul | inst_addiu | inst_addi | inst_andi | inst_ori | inst_xori | inst_lui |
                 inst_jal | inst_lw | inst_lb | inst_slti | inst_sltiu | (op_d[6'h00] & ~inst_jr))
                  ? `WriteEnable : `WriteDisable;
    
    // wR：目的寄存器地址（写回使能为0的不用管）
    assign wR = (inst_addiu | inst_addi | inst_andi | inst_ori | inst_xori | inst_lui | inst_lw | 
                inst_lb | inst_slti | inst_sltiu) ? rt : 
                ((inst_jal) ? 5'b11111 : rd);
    
    /*--------------------------跳转相关--------------------------------------------------------------------------------*/
    assign pc_8 = pc + 8;
    // branch_flag_o：判断是否需要跳转
    wire eq = ~(|(data1 ^ data2));
    wire le = (data1[31] || ~(|data1));
    wire lt = data1[31];
    // 并行计算所有分支条件
    wire beq_taken = inst_beq && eq;
    wire bne_taken = inst_bne && !eq;
    wire bgez_taken = inst_bgez && !lt;
    wire bltz_taken = inst_bltz && lt;
    wire bgtz_taken = inst_bgtz && !le;
    wire blez_taken = inst_blez && le;
    wire is_JR = inst_jr | inst_jalr;
    wire is_J  = inst_j | inst_jal;
    
    assign branch_flag_o = beq_taken || bne_taken || bgez_taken || bltz_taken || 
                            bgtz_taken || blez_taken || is_JR || is_J ? 
                            `Branch : `NotBranch;
    
    // branch_target_addr_o：跳转地址
    wire[31:0] ext_ss2 = pc_plus_4 + {{14{i16[15]}},i16,{2'b0}};
    wire[31:0] ext_za  = {{pc_plus_4[31:28]},addr,{2'b0}};
    assign branch_target_addr_o = is_JR ? data1 :  // 如果是 JR 型指令，跳转到 rd寄存器 所储存的数据地址
                                  is_J ? ext_za :   // 如果是 J  型指令，跳转到经 za  扩展的立即数
                                  ext_ss2;          // 否则是 B  型指令，跳转到经 ss2 扩展的立即数
    
endmodule
