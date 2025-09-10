/*----------------------分支跳转----------------------*/
// 1. 分支跳转判断放在 EX 执行：需要阻塞流水线
// 2. 分支跳转判断提前到 ID 执行：会导致关键路径过长，限制频率
// 3. 延迟槽静态分支预测 + 动态分支预测（基于2位饱和计数器和分支历史记录表实现）：try

`include "defines.v"

module llyCPU (
    input wire                     clk,
    input wire                     rst,

    //连接指令存储器
	input wire[`RegBus]            rom_data_i,
	output wire[`RegBus]           rom_addr_o,
	output wire                    rom_ce_o,

    //连接数据存储器data_ram
	input wire[`RegBus]            ram_data_i,
	output wire[`RegBus]           ram_addr_o,
	output wire[`RegBus]           ram_data_o,
	output wire                    ram_we_o,
	output wire[3:0]               ram_sel_o,
	output wire                    ram_ce_o,
	input wire                     ram_wb_ready_i
);


    /*----------------------暂停相关----------------------*/
    wire icache_stallreq;
    wire baseram_stallreq = (ram_addr_o[31:22] == 10'b1000000000);
    wire id_stallreq;
    wire ex_stallreq;
    wire mem_stallreq;
    wire [0:5] stallreq;
    
    /*----------------------if阶段-------------------------*/
    wire[`RegBus] if_pc;
    wire branch_flag;
    wire[`InstAddrBus] branch_target_addr;
    pc_reg u_pc_reg(
        .clk            (clk),
        .rst            (rst),
        .stallreq       (stallreq),
        .branch_flag_i          (branch_flag),
        .branch_target_address_i(branch_target_addr),
    
        .pc             (if_pc),
        .ce             (rom_ce_o)
    );
    
    
    /*----------------------icache-------------------------*/
    wire[`InstBus] inst_from_cache;
    icache_dram u_icache(
        .clk            (clk),
        .rst            (rst),
        .pc             (if_pc),
        .inst_i         (rom_data_i),
        .baseram_stallreq   (baseram_stallreq),
    
        .pc2rom         (rom_addr_o),
        .inst_from_cache    (inst_from_cache),
        .icache_stallreq    (icache_stallreq)
    );
    
    
    /*----------------------if_id寄存器---------------------------*/
    wire[`InstAddrBus] id_pc;
    wire[`InstBus] id_inst;
    if_id u_if_id(
        .clk            (clk),
        .rst            (rst),
        .stallreq       (stallreq),
    
        .if_pc          (rom_addr_o),
        .if_inst        (inst_from_cache),
        .id_pc          (id_pc),
        .id_inst        (id_inst)
    );
    
    
    /*----------------------id阶段---------------------------*/
    wire[`AluOpBus] id_aluop;
    wire[`RegBus] id_data1;
    wire[`RegBus] id_data2;
    wire[`RegAddrBus] id_wR;
    wire id_we;
    wire[`InstAddrBus] id_pc_8;
    // 数据前递【数据冒险】
    wire ex_we;
    wire[`RegBus] ex_wdata;
    wire[`RegAddrBus] ex_wR;
    wire mem_we;
    wire[`RegBus] mem_wdata_real;
    wire[`RegAddrBus] mem_wR;
    wire inst_is_load;      // 判断上一条是不是load指令，是的话需要暂停
    // 写回阶段在这
    wire wb_we;
    wire[`RegBus] wb_wdata;
    wire[`RegAddrBus] wb_wR;
    id u_id(
        .clk            (clk),
        .rst            (rst),
        .id_pc          (id_pc),
        .id_inst        (id_inst),
        
        .ex_we          (ex_we),
        .ex_wdata       (ex_wdata),
        .ex_wR          (ex_wR),
        .mem_we         (mem_we),
        .mem_wdata      (mem_wdata_real),
        .mem_wR         (mem_wR),
        .pre_inst_is_load       (inst_is_load),
        .wb_we          (wb_we),
        .wb_wdata       (wb_wdata),
        .wb_wR          (wb_wR),
    
        .id_aluop       (id_aluop),
        .id_data1       (id_data1),
        .id_data2       (id_data2),
        .id_wR          (id_wR),
        .id_we          (id_we),
    
        .branch_flag    (branch_flag),
        .branch_target_addr     (branch_target_addr),
        .id_pc_8        (id_pc_8),
    
        .load_relate_stallreq   (id_stallreq)
    );
    
    
    /*----------------------id_ex寄存器----------------------*/ 
    wire[`AluOpBus] ex_aluop;
    wire[`RegBus] ex_data1;
    wire[`RegBus] ex_data2;
    wire[`InstAddrBus] ex_pc_8;
    wire[`InstBus] ex_inst;
    id_ex u_id_ex(
        .clk        (clk),
        .rst        (rst),
        .stallreq   (stallreq),
    
        .id_aluop   (id_aluop),
        .id_data1   (id_data1),
        .id_data2   (id_data2),
        .id_wR      (id_wR),
        .id_we      (id_we),
        .id_pc_8    (id_pc_8),    
        .id_inst    (id_inst),
    
        .ex_aluop   (ex_aluop),
        .ex_data1   (ex_data1),
        .ex_data2   (ex_data2),
        .ex_wR      (ex_wR),
        .ex_we      (ex_we),
        .ex_pc_8    (ex_pc_8),
        .ex_inst    (ex_inst),
    
        .mul_stallreq   (ex_stallreq)
    );
    
    
    /*----------------------ex阶段----------------------*/
    wire[2:0] ex_ls_op;
    wire[`RegBus] ex_ls_addr;
    wire[`RegBus] ex_ls_data;
    wire ex_ls_we;
    wire ex_ls_ce;
    wire[3:0] ex_ls_sel;
    ex u_ex(
        .clk        (clk),
        .rst        (rst),
        
        .alu_op     (ex_aluop),
        .rdata1     (ex_data1),
        .rdata2     (ex_data2),
        .pc_8       (ex_pc_8),
        .inst       (ex_inst),
        // 内存访存相关变量
        .ls_op      (ex_ls_op),
        .ls_addr    (ex_ls_addr),
        .ls_data    (ex_ls_data),
        .ls_we      (ex_ls_we),
        .ls_ce      (ex_ls_ce),
        .ls_sel     (ex_ls_sel),
        .this_inst_is_load  (inst_is_load),
        // 待写回寄存器相关变量
        .wdata      (ex_wdata)
    );
    
    
    /*----------------------ex_mem寄存器---------------------*/
    wire[`RegBus] mem_wdata;
    wire[2:0] mem_ls_op;
    wire mem_read_hit;
    wire[`RegBus] mem_read_bypass;
    wire mem_bypass_hit;
    wire[`RegBus] mem_bypass_data;
    ex_mem u_ex_mem(
        .clk        (clk),
        .rst        (rst),
    
        .ex_we      (ex_we),
        .ex_wR      (ex_wR),
        .ex_wdata   (ex_wdata),
        .ex_ls_op   (ex_ls_op),
        .ex_ls_addr (ex_ls_addr),
        .ex_ls_data (ex_ls_data),
        .ex_ls_we   (ex_ls_we),
        .ex_ls_ce   (ex_ls_ce),
        .ex_ls_sel  (ex_ls_sel),
    
        .stallreq   (stallreq),
        .ram_wb_ready_i (ram_wb_ready_i),
    
        .mem_stallreq   (mem_stallreq),
    
        .mem_we     (mem_we),
        .mem_wR     (mem_wR),
        .mem_wdata  (mem_wdata),
        .mem_ls_op  (mem_ls_op),
        .mem_ls_addr(ram_addr_o),
        .mem_ls_data(ram_data_o),
        .mem_ls_we  (ram_we_o),
        .mem_ls_ce  (ram_ce_o),
        .mem_ls_sel (ram_sel_o),
        
        // 旁路支持
        .mem_read_hit_o     (mem_read_hit),
        .mem_read_bypass_o  (mem_read_bypass),
        .mem_bypass_hit     (mem_bypass_hit),
        .mem_bypass_data    (mem_bypass_data)
    );
    
    
    /*----------------------mem阶段----------------------*/
    mem u_mem(
        .clk        (clk),
        .rst        (rst),
        .ls_op      (mem_ls_op),
        .wdata_i    (mem_wdata),
        .ram_data_i (ram_data_i),
        
        // 旁路支持
        .bypass_hit_i   (mem_bypass_hit),
        .bypass_data_i  (mem_bypass_data),
        .read_hit_i     (mem_read_hit),
        .read_bypass_i  (mem_read_bypass),
        
        .wdata_o    (mem_wdata_real)
    );
    
    
    /*----------------------mem_wb寄存器----------------------*/
    mem_wb u_mem_wb(
        .clk        (clk),
        .rst        (rst),
    
        .mem_we     (mem_we),
        .mem_wR     (mem_wR),
        .mem_wdata  (mem_wdata_real),
    
        .stallreq   (stallreq),
    
        .wb_we      (wb_we),
        .wb_wR      (wb_wR),
        .wb_wdata   (wb_wdata)
    );
    
    
    /*----------------------暂停信号相关----------------------*/
    ctrl u_ctrl(
        .clk        (clk),
        .rst        (rst),
        .icache_stallreq        (icache_stallreq),
        .baseram_stallreq       (baseram_stallreq),
        .id_stallreq            (id_stallreq),
        .ex_stallreq            (ex_stallreq),
        .mem_stallreq           (mem_stallreq),
        
        .stallreq               (stallreq)
    );
    
endmodule