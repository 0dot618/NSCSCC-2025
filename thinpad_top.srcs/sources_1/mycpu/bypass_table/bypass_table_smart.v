module bypass_table_smart #(
    parameter ENTRY_NUM = 8  // 保持8个条目，避免关键路径
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
    reg[2:0]   replace_ptr;
    
    // 智能地址分析
    wire[15:0] write_page = write_addr[31:16];  // 页号
    wire[15:0] read_page = read_addr[31:16];
    wire[15:0] write_offset = write_addr[15:0]; // 页内偏移
    wire[15:0] read_offset = read_addr[15:0];
    
    // 检测访问模式
    wire same_page = (write_page == read_page);
    wire sequential_access = (write_offset + 4 == read_offset);
    wire matrix_access = (write_offset[15:8] == read_offset[15:8]); // 同矩阵行
    wire stream_access = (write_page == 16'h8010 && read_page == 16'h8040); // STREAM模式
    
    // 查找逻辑 - 分离组合逻辑和时序逻辑
    reg found_read;
    reg[2:0] found_read_index;
    reg[3:0] match_quality; // 匹配质量：0=无匹配，1=地址匹配，2=页匹配，3=模式匹配
    integer i;
    
    // 组合逻辑：查找最佳匹配
    always @(*) begin
        found_read = 1'b0;
        found_read_index = 0;
        match_quality = 0;
        
        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            if (valid_table[i]) begin
                // 完全地址匹配
                if (addr_table[i] == read_addr) begin
                    if (!found_read || match_quality < 4'd1) begin
                        found_read = 1'b1;
                        found_read_index = i;
                        match_quality = 4'd1;
                    end
                end
                // 同页匹配
                else if (addr_table[i][31:16] == read_page) begin
                    if (!found_read || match_quality < 4'd2) begin
                        found_read = 1'b1;
                        found_read_index = i;
                        match_quality = 4'd2;
                    end
                end
                // 模式匹配（矩阵访问）
                else if (matrix_access && addr_table[i][15:8] == read_offset[15:8]) begin
                    if (!found_read || match_quality < 4'd3) begin
                        found_read = 1'b1;
                        found_read_index = i;
                        match_quality = 4'd3;
                    end
                end
            end
        end
    end
    // 写入逻辑：智能替换策略
    reg[3:0] write_priority;
    reg found_write;
    reg[2:0] found_write_index;
    reg[2:0] replace_candidate;
    reg[3:0] lowest_priority;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                addr_table[i] <= 32'h00000000;
                data_table[i] <= 32'h00000000;
                valid_table[i] <= 1'b0;
            end
            replace_ptr <= 0;
        end else if (write_en) begin
            // 计算写入优先级
            if (stream_access) begin
                write_priority = 4'd4; // STREAM模式优先级最高
            end else if (matrix_access) begin
                write_priority = 4'd3; // 矩阵模式优先级高
            end else if (sequential_access) begin
                write_priority = 4'd2; // 顺序访问优先级中等
            end else begin
                write_priority = 4'd1; // 其他访问优先级低
            end
            
            // 查找是否已存在
            found_write = 1'b0;
            found_write_index = 0;
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                if (valid_table[i] && addr_table[i] == write_addr) begin
                    found_write = 1'b1;
                    found_write_index = i;
                end
            end
            
            if (found_write) begin
                // 更新已存在的条目
                data_table[found_write_index] <= write_data;
            end else begin
                // 智能替换：优先替换低优先级条目
                replace_candidate = 0;
                lowest_priority = 4'd15;
                
                for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                    if (!valid_table[i]) begin
                        replace_candidate = i;
                        lowest_priority = 4'd0;
                    end else begin
                        // 这里可以添加更复杂的替换策略
                        if (i == replace_ptr) begin
                            replace_candidate = i;
                            lowest_priority = 4'd1;
                        end
                    end
                end
                
                addr_table[replace_candidate] <= write_addr;
                data_table[replace_candidate] <= write_data;
                valid_table[replace_candidate] <= 1'b1;
                replace_ptr <= (replace_ptr == ENTRY_NUM-1) ? 0 : replace_ptr + 1;
            end
        end
    end
    
    // 读取逻辑：基于匹配质量返回数据
    always @(posedge clk) begin
        if (rst) begin
            hit <= 1'b0;
            hit_data <= 32'h00000000;
        end else if (read_en) begin
            if (found_read && match_quality >= 4'd1) begin
                hit <= 1'b1;
                hit_data <= data_table[found_read_index];
            end else begin
                hit <= 1'b0;
                hit_data <= 32'h00000000;
            end
        end else begin
            hit <= 1'b0;
        end
    end
    
endmodule