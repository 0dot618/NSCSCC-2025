`include "defines.v"

module id (
    input wire                  clk,
    input wire                  rst,
    input wire[`InstAddrBus]    id_pc,
    input wire[`InstBus]        id_inst,

    input wire                  ex_we,
    input wire[`RegBus]         ex_wdata,
    input wire[`RegAddrBus]     ex_wR,
    input wire                  mem_we,
    input wire[`RegBus]         mem_wdata,
    input wire[`RegAddrBus]     mem_wR,
    input wire                  pre_inst_is_load,
    input wire                  wb_we,
    input wire[`RegBus]         wb_wdata,
    input wire[`RegAddrBus]     wb_wR,
    
    output wire[`AluOpBus]      id_aluop,
    output wire[`RegBus]        id_data1,
    output wire[`RegBus]        id_data2,
    output wire[`RegAddrBus]    id_wR,
    output wire                 id_we,
    output wire[`InstAddrBus]   id_pc_8,

    output wire                 branch_flag,
    output wire[`InstAddrBus]   branch_target_addr,

    output wire                 load_relate_stallreq    //load相关暂停请求

);

    wire reg1_read;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegBus] reg1_data;
    wire reg2_read;
    wire[`RegAddrBus] reg2_addr;
    wire[`RegBus] reg2_data;
    
    /*----------------------regfile寄存器堆的存取----------------------*/
    regfile u_regfile(
        .clk    (clk),
        .rst    (rst),
        .we     (wb_we),
        .wR     (wb_wR),
        .wD     (wb_wdata),
        .re1    (reg1_read),
        .re2    (reg2_read),
        .rR1    (reg1_addr),
        .rR2    (reg2_addr),
    
        .rD1    (reg1_data),
        .rD2    (reg2_data)
    );
    
    
    /*----------------------id译码----------------------*/
    idecode u_idecode(
        .rst        (rst),
        .pc         (id_pc),
        .inst       (id_inst),
    
        .rD1        (reg1_data),
        .rD2        (reg2_data),
    
        .ex_wen_i   (ex_we),
        .ex_wdata_i (ex_wdata),
        .ex_wR_i    (ex_wR),
        .mem_wen_i  (mem_we),
        .mem_wdata_i(mem_wdata),
        .mem_wR_i   (mem_wR),
    
        .pre_inst_is_load   (pre_inst_is_load),
    
        .re1        (reg1_read),
        .re2        (reg2_read),
        .rR1        (reg1_addr),
        .rR2        (reg2_addr),
    
        .alu_op     (id_aluop),
        .data1      (id_data1),
        .data2      (id_data2),
        .wR         (id_wR),
        .we         (id_we),
    
        .branch_flag_o  (branch_flag),
        .branch_target_addr_o   (branch_target_addr),
        .pc_8           (id_pc_8),
    
        .stallreq_o (load_relate_stallreq)
    );

//    /*----------------------ID1级：指令解码----------------------*/
//    wire[`AluOpBus] id1_alu_op;
//    wire id1_re1, id1_re2;
//    wire[`RegAddrBus] id1_rR1, id1_rR2, id1_wR;
//    wire id1_we;
//    wire[`RegBus] id1_imm;
//    wire[`InstAddrBus] id1_pc_8;
//    wire id1_branch_flag;
//    wire[`InstAddrBus] id1_branch_target_addr;
    
//    id1 u_id1(
//        .rst        (rst),
//        .pc         (id_pc),
//        .inst       (id_inst),
        
//        .alu_op     (id1_alu_op),
//        .re1        (id1_re1),
//        .re2        (id1_re2),
//        .rR1        (id1_rR1),
//        .rR2        (id1_rR2),
//        .wR         (id1_wR),
//        .we         (id1_we),
//        .imm        (id1_imm),
//        .pc_8       (id1_pc_8),
//        .branch_flag_o (id1_branch_flag),
//        .branch_target_addr_o (id1_branch_target_addr)
//    );
    
//    /*----------------------ID1_ID2流水线寄存器----------------------*/
//    wire[`AluOpBus] id2_alu_op;
//    wire id2_re1, id2_re2;
//    wire[`RegAddrBus] id2_rR1, id2_rR2, id2_wR;
//    wire id2_we;
//    wire[`RegBus] id2_imm;
//    wire[`InstAddrBus] id2_pc_8;
//    wire id2_branch_flag;
//    wire[`InstAddrBus] id2_branch_target_addr;
//    wire[`InstAddrBus] id2_pc;
//    wire[`InstBus] id2_inst;
    
//    id1_id2 u_id1_id2(
//        .clk        (clk),
//        .rst        (rst),
//        .stallreq   (6'b000000),  // 暂时不使用暂停，后续可以扩展
        
//        .id1_alu_op (id1_alu_op),
//        .id1_re1    (id1_re1),
//        .id1_re2    (id1_re2),
//        .id1_rR1    (id1_rR1),
//        .id1_rR2    (id1_rR2),
//        .id1_wR     (id1_wR),
//        .id1_we     (id1_we),
//        .id1_imm    (id1_imm),
//        .id1_pc_8   (id1_pc_8),
//        .id1_branch_flag (id1_branch_flag),
//        .id1_branch_target_addr (id1_branch_target_addr),
//        .id1_pc     (id_pc),
//        .id1_inst   (id_inst),
        
//        .id2_alu_op (id2_alu_op),
//        .id2_re1    (id2_re1),
//        .id2_re2    (id2_re2),
//        .id2_rR1    (id2_rR1),
//        .id2_rR2    (id2_rR2),
//        .id2_wR     (id2_wR),
//        .id2_we     (id2_we),
//        .id2_imm    (id2_imm),
//        .id2_pc_8   (id2_pc_8),
//        .id2_branch_flag (id2_branch_flag),
//        .id2_branch_target_addr (id2_branch_target_addr),
//        .id2_pc     (id2_pc),
//        .id2_inst   (id2_inst)
//    );
    
//    /*----------------------ID2级：寄存器访问和前递逻辑----------------------*/
//    id2 u_id2(
//        .rst        (rst),
//        .pc         (id2_pc),
//        .inst       (id2_inst),
        
//        .alu_op_i   (id2_alu_op),
//        .re1_i      (id2_re1),
//        .re2_i      (id2_re2),
//        .rR1_i      (id2_rR1),
//        .rR2_i      (id2_rR2),
//        .wR_i       (id2_wR),
//        .we_i       (id2_we),
//        .imm_i      (id2_imm),
//        .pc_8_i     (id2_pc_8),
//        .branch_flag_i (id2_branch_flag),
//        .branch_target_addr_i (id2_branch_target_addr),
        
//        .reg1_data_i(reg1_data),
//        .reg2_data_i(reg2_data),
        
//        .ex_wen_i   (ex_we),
//        .ex_wdata_i (ex_wdata),
//        .ex_wreg_i  (ex_wR),
//        .mem_wen_i  (mem_we),
//        .mem_wdata_i(mem_wdata),
//        .mem_wreg_i (mem_wR),
//        .pre_inst_is_load (pre_inst_is_load),
        
//        .alu_op     (id_aluop),
//        .data1      (id_data1),
//        .data2      (id_data2),
//        .wR         (id_wR),
//        .we         (id_we),
//        .pc_8       (id_pc_8),
        
//        .branch_flag (branch_flag),
//        .branch_target_addr (branch_target_addr),
        
//        .re1        (reg1_read),
//        .re2        (reg2_read),
//        .rR1        (reg1_addr),
//        .rR2        (reg2_addr),
        
//        .stallreq_o (load_relate_stallreq)
//    );


endmodule