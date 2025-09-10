`include "defines.v"

module write_buffer (
    input wire clk,
    input wire rst,
    
    // 来自CPU的写请求
    input wire[`RegBus]     wb_addr_i,      // 写地址
    input wire[`RegBus]     wb_data_i,      // 写数据
    input wire              wb_we_i,        // 写使能（低有效）
    input wire              wb_ce_i,        // 片选使能
    input wire[3:0]         wb_sel_i,       // 字节选择
    input wire              wb_valid_i,     // 写请求有效
    
    // 输出到内存
    output reg[`RegBus]     wb_addr_o,      // 写地址
    output reg[`RegBus]     wb_data_o,      // 写数据
    output reg              wb_we_o,        // 写使能（低有效）
    output reg              wb_ce_o,        // 片选使能
    output reg[3:0]         wb_sel_o,       // 字节选择
    output reg              wb_valid_o,     // 写请求有效
    
    // 状态信号
    output wire             wb_full,        // buffer满
    output wire             wb_empty,       // buffer空
    input wire              wb_ready_i,     // 内存准备好接收
    
    // 旁路支持 - 读操作时检查是否命中write buffer
    input wire[`RegBus]     read_addr_i,    // 读地址
    input wire              read_valid_i,   // 读请求有效
    output wire             read_hit_o,     // 读地址命中write buffer
    output wire[`RegBus]    read_data_o     // 旁路数据（如果命中）
);

    // 1深度FIFO寄存器
    reg[`RegBus]     addr_reg;
    reg[`RegBus]     data_reg;
    reg              we_reg;
    reg              ce_reg;
    reg[3:0]         sel_reg;
    reg              valid_reg;
    
    // 状态寄存器
    reg              has_data;      // 是否有数据在buffer中
    
    // 预计算地址比较结果，减少关键路径延迟
    reg              addr_match_reg;
    reg              read_hit_reg;
    
    // 输出赋值
    assign wb_full = has_data && !wb_ready_i;
    assign wb_empty = !has_data;
    
    // 旁路逻辑 - 预计算地址比较，减少关键路径
    always @(posedge clk) begin
        if (rst) begin
            addr_match_reg <= 1'b0;
            read_hit_reg <= 1'b0;
        end else begin
            // 预计算地址匹配
            addr_match_reg <= (read_addr_i == addr_reg);
            // 预计算命中结果
            read_hit_reg <= has_data && read_valid_i && (read_addr_i == addr_reg);
        end
    end
    
    // 使用预计算的结果，减少组合逻辑延迟
    assign read_hit_o = read_hit_reg;
    assign read_data_o = read_hit_reg ? data_reg : `ZeroWord;
    
    // 输出逻辑 - 使用组合逻辑，但减少复杂度
    always @(*) begin
        if (has_data) begin
            wb_addr_o = addr_reg;
            wb_data_o = data_reg;
            wb_we_o = we_reg;
            wb_ce_o = ce_reg;
            wb_sel_o = sel_reg;
            wb_valid_o = valid_reg;
        end else begin
            wb_addr_o = wb_addr_i;
            wb_data_o = wb_data_i;
            wb_we_o = wb_we_i;
            wb_ce_o = wb_ce_i;
            wb_sel_o = wb_sel_i;
            wb_valid_o = wb_valid_i;
        end
    end
    
    // Buffer控制逻辑 - 优化状态机，减少关键路径
    wire buffer2ram =                has_data &&  wb_ready_i;
    wire wb2ram     = wb_valid_i && !has_data &&  wb_ready_i;
    wire wb2buffer  = wb_valid_i && !has_data && !wb_ready_i;
    wire keep_buffer= wb_valid_i &&  has_data && !wb_ready_i;
    wire wb2b2ram   = wb_valid_i &&  has_data &&  wb_ready_i;
    always @(posedge clk) begin
        if (rst) begin
            has_data <= 1'b0;
            addr_reg <= `ZeroWord;
            data_reg <= `ZeroWord;
            we_reg <= `WriteDisable_n;
            ce_reg <= `ChipDisable;
            sel_reg <= 4'b1111;
            valid_reg <= 1'b0;
        end else begin
            // 简化状态机逻辑，减少组合逻辑复杂度
            if (buffer2ram) begin
                // 内存准备好，输出buffer中的数据，清空buffer
                has_data <= 1'b0;
                valid_reg <= 1'b0;
            end else if (wb2ram) begin
                // 直接传递，不缓存
                has_data <= 1'b0;
            end else if (wb2buffer) begin
                // 缓存数据
                has_data <= 1'b1;
                addr_reg <= wb_addr_i;
                data_reg <= wb_data_i;
                we_reg <= wb_we_i;
                ce_reg <= wb_ce_i;
                sel_reg <= wb_sel_i;
                valid_reg <= 1'b1;
            end else if (keep_buffer) begin
                // buffer满且内存未准备好，保持状态
                has_data <= 1'b1;
            end else if (wb2b2ram) begin
                // 优化：当buffer有数据且内存准备好时，立即处理新数据
                has_data <= 1'b1;
                addr_reg <= wb_addr_i;
                data_reg <= wb_data_i;
                we_reg <= wb_we_i;
                ce_reg <= wb_ce_i;
                sel_reg <= wb_sel_i;
                valid_reg <= 1'b1;
            end
        end
    end

endmodule 