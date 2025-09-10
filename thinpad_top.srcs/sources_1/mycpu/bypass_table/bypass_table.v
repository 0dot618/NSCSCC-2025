//`include "defines.v"

//module bypass_table #(
//    parameter ENTRY_NUM = 32
//)(
//    input wire clk,
//    input wire rst,
//    // 写入接口
//    input wire        write_en,
//    input wire[`RegBus] write_addr,
//    input wire[`RegBus] write_data,
//    // 查询接口
//    input wire        read_en,
//    input wire[`RegBus] read_addr,
//    output reg        hit,
//    output reg[`RegBus] hit_data
//);
//    reg[`RegBus] addr_table[ENTRY_NUM-1:0];
//    reg[`RegBus] data_table[ENTRY_NUM-1:0];
//    reg          valid_table[ENTRY_NUM-1:0];
//    reg[4:0]     replace_ptr;
//    integer i;
//    reg found;

//    always @(posedge clk) begin
//        if (rst) begin
//            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
//                addr_table[i] <= `ZeroWord;
//                data_table[i] <= `ZeroWord;
//                valid_table[i] <= 1'b0;
//            end
//            replace_ptr <= 0;
//        end else if (write_en) begin
//            found = 1'b0;
//            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
//                if (valid_table[i] && addr_table[i] == write_addr) begin
//                    data_table[i] <= write_data;
//                    found = 1'b1;
//                end
//            end
//            if (found == 1'b0) begin
//                addr_table[replace_ptr] <= write_addr;
//                data_table[replace_ptr] <= write_data;
//                valid_table[replace_ptr] <= 1'b1;
//                replace_ptr <= replace_ptr + 1;
//                if (replace_ptr == ENTRY_NUM-1)
//                    replace_ptr <= 0;
//            end
//        end
//    end

//    always @(*) begin
//        hit = 1'b0;
//        hit_data = `ZeroWord;
//        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
//            if (read_en && valid_table[i] && addr_table[i] == read_addr) begin
//                hit = 1'b1;
//                hit_data = data_table[i];
//            end
//        end
//    end
//endmodule 
 module bypass_table #(
    parameter ENTRY_NUM = 32
)(
    input wire clk,
    input wire rst,
    // 写入接口
    input wire        write_en,
    input wire[31:0] write_addr,
    input wire[31:0] write_data,
    // 查询接口
    input wire        read_en,
    input wire[31:0] read_addr,
    output reg        hit,
    output reg[31:0] hit_data
);
    reg[31:0] addr_table [0:ENTRY_NUM-1];
    reg[31:0] data_table [0:ENTRY_NUM-1];
    reg        valid_table [0:ENTRY_NUM-1];
    reg[4:0]   replace_ptr;
    integer i;
    reg found;
    reg[4:0] found_index;

    // 写入逻辑 - 修复时序问题
    reg found_write;
    reg[4:0] found_write_index;
    
    // 组合逻辑查找已存在的地址
    always @(*) begin
        found_write = 1'b0;
        found_write_index = 0;
        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            if (!found_write && valid_table[i] && addr_table[i] == write_addr) begin
                found_write = 1'b1;
                found_write_index = i;
            end
        end
    end
    
    // 时序逻辑更新表项
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                addr_table[i] <= 32'h00000000;
                data_table[i] <= 32'h00000000;
                valid_table[i] <= 1'b0;
            end
            replace_ptr <= 0;
        end else if (write_en) begin
            // 更新或插入
            if (found_write) begin
                data_table[found_write_index] <= write_data;
            end else begin
                addr_table[replace_ptr] <= write_addr;
                data_table[replace_ptr] <= write_data;
                valid_table[replace_ptr] <= 1'b1;
                replace_ptr <= (replace_ptr == ENTRY_NUM-1) ? 0 : replace_ptr + 1;
            end
        end
    end

    // 读取逻辑 - 修复时序问题
    reg found_read;
    reg[4:0] found_read_index;
    
    // 组合逻辑查找匹配项
    always @(*) begin
        found_read = 1'b0;
        found_read_index = 0;
        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            if (!found_read && valid_table[i] && addr_table[i] == read_addr) begin
                found_read = 1'b1;
                found_read_index = i;
            end
        end
    end
    
    // 时序逻辑更新输出
    always @(posedge clk) begin
        if (rst) begin
            hit <= 1'b0;
            hit_data <= 32'h00000000;
        end else if (read_en) begin
            hit <= found_read;
            hit_data <= found_read ? data_table[found_read_index] : 32'h00000000;
        end else begin
            hit <= 1'b0;
        end
    end
endmodule

    
//    // 优化1：使用更高效的查找算法，减少组合逻辑延迟
//    wire[ENTRY_NUM-1:0] addr_match_write;  // 写地址匹配信号
//    wire[ENTRY_NUM-1:0] addr_match_read;   // 读地址匹配信号
//    wire[ENTRY_NUM-1:0] valid_and_match_write;  // 有效且匹配写地址
//    wire[ENTRY_NUM-1:0] valid_and_match_read;   // 有效且匹配读地址
    
//    // 优化2：并行生成匹配信号，减少关键路径
//    genvar i;
//    generate
//        for (i = 0; i < ENTRY_NUM; i = i + 1) begin : gen_match
//            assign addr_match_write[i] = (addr_table[i] == write_addr);
//            assign addr_match_read[i] = (addr_table[i] == read_addr);
//            assign valid_and_match_write[i] = valid_table[i] && addr_match_write[i];
//            assign valid_and_match_read[i] = valid_table[i] && addr_match_read[i];
//        end
//    endgenerate
    
//    // 优化3：使用优先级编码器快速找到第一个匹配项
//    wire[4:0] write_match_index;
//    wire[4:0] read_match_index;
//    wire write_found;
//    wire read_found;
    
//    // 优先级编码器：找到第一个匹配的写地址
//    priority_encoder #(.WIDTH(ENTRY_NUM)) write_encoder(
//        .in(valid_and_match_write),
//        .out(write_match_index),
//        .valid(write_found)
//    );
    
//    // 优先级编码器：找到第一个匹配的读地址
//    priority_encoder #(.WIDTH(ENTRY_NUM)) read_encoder(
//        .in(valid_and_match_read),
//        .out(read_match_index),
//        .valid(read_found)
//    );
    
//    // 优化4：简化写入逻辑，减少关键路径
//    integer j;  // 将变量声明移到always块外
//    always @(posedge clk) begin
//        if (rst) begin
//            for (j = 0; j < ENTRY_NUM; j = j + 1) begin
//                addr_table[j] <= 32'h00000000;
//                data_table[j] <= 32'h00000000;
//                valid_table[j] <= 1'b0;
//            end
//            replace_ptr <= 0;
//        end else if (write_en) begin
//            if (write_found) begin
//                // 更新已存在的条目
//                data_table[write_match_index] <= write_data;
//            end else begin
//                // 插入新条目
//                addr_table[replace_ptr] <= write_addr;
//                data_table[replace_ptr] <= write_data;
//                valid_table[replace_ptr] <= 1'b1;
//                replace_ptr <= (replace_ptr == ENTRY_NUM-1) ? 0 : replace_ptr + 1;
//            end
//        end
//    end
    
//    // 优化5：简化读取逻辑，减少关键路径
//    always @(posedge clk) begin
//        if (rst) begin
//            hit <= 1'b0;
//            hit_data <= 32'h00000000;
//        end else if (read_en) begin
//            hit <= read_found;
//            hit_data <= read_found ? data_table[read_match_index] : 32'h00000000;
//        end else begin
//            hit <= 1'b0;
//        end
//    end
    
//endmodule

//// 优化6：添加优先级编码器模块，提高查找效率
//module priority_encoder #(
//    parameter WIDTH = 32
//)(
//    input wire[WIDTH-1:0] in,
//    output reg[4:0] out,
//    output reg valid
//);
//    integer i;
//    always @(*) begin
//        out = 0;
//        valid = 1'b0;
//        for (i = 0; i < WIDTH; i = i + 1) begin
//            if (!valid && in[i]) begin
//                out = i[4:0];
//                valid = 1'b1;
//            end
//        end
//    end
//endmodule 
