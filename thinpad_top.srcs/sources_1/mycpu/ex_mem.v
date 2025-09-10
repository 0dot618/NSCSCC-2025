`include "defines.v"

module ex_mem (
    input wire clk,
    input wire rst,
    input wire              ex_we,
    input wire[`RegAddrBus] ex_wR,
    input wire[`RegBus]     ex_wdata,
    input wire[2:0]         ex_ls_op,
    input wire[`RegBus]     ex_ls_addr,
    input wire[`RegBus]     ex_ls_data,
    input wire              ex_ls_we,
    input wire              ex_ls_ce,
    input wire[3:0]         ex_ls_sel,

    input wire[0:5]         stallreq,
    input wire              ram_wb_ready_i,

    output reg              mem_stallreq,
    
    output reg              mem_we,
    output reg[`RegAddrBus] mem_wR,
    output reg[`RegBus]     mem_wdata,
    output reg[2:0]         mem_ls_op,
    output reg[`RegBus]     mem_ls_addr,
    output reg[`RegBus]     mem_ls_data,
    output reg              mem_ls_we,
    output reg              mem_ls_ce,
    output reg[3:0]         mem_ls_sel,
    
    // 旁路支持
    output wire             mem_read_hit_o,     // mem阶段读操作命中write buffer
    output wire[`RegBus]    mem_read_bypass_o,  // 旁路数据
    output reg             mem_bypass_hit,
    output reg[`RegBus]    mem_bypass_data
);

    // Write buffer实例
    wire[`RegBus]     wb_addr_to_ram;
    wire[`RegBus]     wb_data_to_ram;
    wire              wb_we_to_ram;
    wire              wb_ce_to_ram;
    wire[3:0]         wb_sel_to_ram;
    wire              wb_valid_to_ram;
    wire              wb_full;
    wire              wb_empty;
    wire              wb_ready_from_ram;
    
    // 判断是否为写操作和读操作
    wire is_write_op = (ex_ls_op == `MEM_SB_OP || ex_ls_op == `MEM_SW_OP);
    wire is_read_op = (ex_ls_op == `MEM_LB_OP || ex_ls_op == `MEM_LW_OP);
    
    // bypass_table实例
    wire bypass_hit;
    wire[`RegBus] bypass_data;
//    bypass_table_ip #(.ENTRY_NUM(512)) u_bypass_table(
    bypass_table_simple #(.ENTRY_NUM(8)) u_bypass_table(
//    bypass_table #(.ENTRY_NUM(8)) u_bypass_table(
        .clk(clk),
        .rst(rst),
        .write_en(is_write_op && ex_ls_ce),
        .write_addr(ex_ls_addr),
        .write_data(ex_ls_data),
        .read_en(is_read_op && ex_ls_ce),
        .read_addr(ex_ls_addr),
        .hit(bypass_hit),
        .hit_data(bypass_data)
    );
//    assign mem_bypass_hit = bypass_hit;
//    assign mem_bypass_data = bypass_data;
    
    // 读操作时，如果bypass命中，则不需要访存
    wire bypass_read_hit = is_read_op && ex_ls_ce && bypass_hit;
    
    // 写操作时，如果有读操作且未命中bypass，则阻止write buffer写RAM
    wire mem_has_read = is_read_op && ex_ls_ce && !bypass_hit;
    assign wb_ready_from_ram = mem_has_read ? 1'b0 : ram_wb_ready_i;
    
    write_buffer u_write_buffer(
        .clk            (clk),
        .rst            (rst),
        .wb_addr_i      (ex_ls_addr),
        .wb_data_i      (ex_ls_data),
        .wb_we_i        (ex_ls_we),
        .wb_ce_i        (ex_ls_ce),
        .wb_sel_i       (ex_ls_sel),
        .wb_valid_i     (is_write_op && ex_ls_ce),
        .wb_addr_o      (wb_addr_to_ram),
        .wb_data_o      (wb_data_to_ram),
        .wb_we_o        (wb_we_to_ram),
        .wb_ce_o        (wb_ce_to_ram),
        .wb_sel_o       (wb_sel_to_ram),
        .wb_valid_o     (wb_valid_to_ram),
        .wb_full        (wb_full),
        .wb_empty       (wb_empty),
        .wb_ready_i     (wb_ready_from_ram),
        
        // 旁路支持
        .read_addr_i    (ex_ls_addr),
        .read_valid_i   (mem_has_read),
        .read_hit_o     (mem_read_hit_o),
        .read_data_o    (mem_read_bypass_o)
    );

    reg [1:0] mem_access_cnt;  // 0~3记录访存阶段
    wire read_bypass    = ex_ls_ce && !is_write_op && bypass_read_hit;
    wire read_nobypass  = ex_ls_ce && !is_write_op && !bypass_read_hit;
    wire write_nobuffer = ex_ls_ce && is_write_op && wb_full;
    wire write_buffer   = ex_ls_ce && is_write_op;
    always @(posedge clk) begin
        if (rst) begin
            mem_stallreq <= `NoStop;
            mem_access_cnt <= 2'd0;
        end else begin
            case (mem_access_cnt)
                2'd0: begin
//                    if(read_nobypass | read_bypass) begin                // 读操作开始访存
                    if(read_nobypass) begin                // 读操作开始访存
                        mem_stallreq <= `Stop;
                        mem_access_cnt <= 2'b1;
                    end else if(write_nobuffer) begin  // 写操作但buffer满
                        mem_stallreq <= `Stop;
                        mem_access_cnt <= 2'b0;  // 保持等待
                    end else if(write_buffer | read_bypass) begin  // 写操作
                        mem_stallreq <= `Stop;
                        mem_access_cnt <= 2'd3;  // 停一周期
                    end else begin
                        mem_stallreq <= `NoStop;
                        mem_access_cnt <= 2'd0;
                    end
                end
                2'd1: begin
                    mem_stallreq <= `Stop;            // 第一个周期
                    mem_access_cnt <= 2'd2;
                end
                2'd2: begin
                    mem_stallreq <= `Stop;            // 第二个周期
                    mem_access_cnt <= 2'd3;
                end
                2'd3: begin
                    mem_stallreq <= `NoStop;          // 恢复流水线
                    mem_access_cnt <= 2'd0;
                end
                default: begin
                    mem_stallreq <= `NoStop;
                    mem_access_cnt <= 2'd0;
                end
            endcase
        end
    end
    
    wire reset = rst | (stallreq[3] == `Stop & stallreq[4] == `NoStop);
    wire keep  = stallreq[3] == `Stop & stallreq[4] == `Stop;
        
    // 简化数据选择逻辑
    wire [31:0] mem_wdata_next;
    wire [31:0] mem_ls_addr_next;
    wire [31:0] mem_ls_data_next;
    wire mem_ls_we_next;
    wire mem_ls_ce_next;
    wire [3:0] mem_ls_sel_next;
    
    assign mem_wdata_next = bypass_read_hit ? bypass_data : ex_wdata;
    assign mem_ls_addr_next = is_write_op ? wb_addr_to_ram : ex_ls_addr;
    assign mem_ls_data_next = is_write_op ? wb_data_to_ram : ex_ls_data;
    assign mem_ls_we_next = is_write_op ? wb_we_to_ram : ex_ls_we;
    assign mem_ls_ce_next = is_write_op ? wb_ce_to_ram : ex_ls_ce;
    assign mem_ls_sel_next = is_write_op ? wb_sel_to_ram : ex_ls_sel;
    
    always @(posedge clk ) begin
        if(reset) begin
            mem_we <= `WriteDisable;
            mem_wR <= `NOPRegAddr;
            mem_wdata <= `ZeroWord;
            mem_ls_op <= `MEM_NOP_OP;
            mem_ls_addr <= `ZeroWord;
            mem_ls_data <= `ZeroWord;
            mem_ls_we <= `WriteDisable_n;
            mem_ls_ce <= `ChipDisable;
            mem_ls_sel <= 4'b1111;
            mem_bypass_hit <= 1'b0;
            mem_bypass_data <= `ZeroWord;
        end else if (keep) begin
            mem_we <= mem_we;
            mem_wR <= mem_wR;
            mem_wdata <= mem_wdata;
            mem_ls_op <= mem_ls_op;
            mem_ls_addr <= mem_ls_addr;
            mem_ls_data <= mem_ls_data;
            mem_ls_we <= mem_ls_we;
            mem_ls_ce <= mem_ls_ce;
            mem_ls_sel <= mem_ls_sel;
            mem_bypass_hit <= mem_bypass_hit;
            mem_bypass_data <= mem_bypass_data;
        end else begin
            mem_we <= ex_we;
            mem_wR <= ex_wR;
            mem_wdata <= mem_wdata_next;
            mem_ls_op <= ex_ls_op;
            mem_ls_addr <= mem_ls_addr_next;
            mem_ls_data <= mem_ls_data_next;
            mem_ls_we <= mem_ls_we_next;
            mem_ls_ce <= mem_ls_ce_next;
            mem_ls_sel <= mem_ls_sel_next;
            mem_bypass_hit <= bypass_read_hit;
            mem_bypass_data <= bypass_data;
        end
    end
    
endmodule
    
//endmodule