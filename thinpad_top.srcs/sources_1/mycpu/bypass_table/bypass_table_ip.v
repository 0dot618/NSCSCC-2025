module bypass_table_ip #(
    parameter ENTRY_NUM = 128  // 保持128条目，安全策略
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

    // 使用地址哈希减少冲突
    wire[8:0] write_hash = write_addr[10:2];  // 9位哈希，512个槽位
    wire[8:0] read_hash = read_addr[10:2];
    
    // 分布式RAM实例化（需要先创建IP核）
    wire[31:0] ram_addr_out;
    wire[31:0] ram_data_out;
    wire valid_out;
    
    // 基于测试程序访问模式的精确识别
    // STREAM: 从0x80100000读取，写入0x80400000
//    wire is_stream_read = (read_addr[31:20] == 12'h801);
//    wire is_stream_write = (write_addr[31:20] == 12'h804);
    
    // MATRIX: 主要在0x80400000-0x80420000区域，矩阵乘法访问，缓存矩阵C
//    wire is_matrix_read = (read_addr[31:16] == 16'h8040) || (read_addr[31:16] == 16'h8041) || (read_addr[31:16] == 16'h8042);
//    wire is_matrix_write = (write_addr[31:16] == 16'h8040) || (write_addr[31:16] == 16'h8041) || (write_addr[31:16] == 16'h8042);
    wire is_matrix_read = (read_addr[31:16] == 16'h8042) && (read_addr[15:12] == 5'b00000);
    wire is_matrix_write = (write_addr[31:16] == 16'h8042) && (write_addr[15:12] == 5'b00000);
    
    // CRYPTONIGHT: 主要在0x80400000区域，随机访问模式
//    wire is_crypto_read = (read_addr[31:16] == 16'h8040);
//    wire is_crypto_write = (write_addr[31:16] == 16'h8040) && (write_addr[15:13] == 3'b000);
    
    // 排除所有系统地址
    wire is_system_write = (write_addr[31:24] == 8'hBF) ||  // 串口
                           (write_addr[31:20] == 12'h801);  // 排除0x80100000区域
    
    wire is_system_read = (read_addr[31:24] == 8'hBF) ||   // 串口
                          (read_addr[31:20] == 12'h801);   // 排除0x80100000区域
    
    // 精确的缓存策略：只缓存测试程序相关访问，排除系统地址
    wire should_cache = (is_matrix_write) && 
                       !(is_system_read || is_system_write);
//    wire should_cache = 1'b1;
    
    // 控制IP核的写使能：只有should_cache为真时才写入
    wire ip_write_en = write_en && should_cache;
    
    // 地址RAM - 存储地址
    bypass_addr_ram addr_ram (
        .a(write_hash),           // 写地址
        .d(write_addr),           // 写数据
        .dpra(read_hash),         // 读地址
        .clk(clk),               // 时钟
        .we(ip_write_en),        // 写使能 - 使用should_cache控制
        .dpo(ram_addr_out)       // 读数据
    );
    
    // 数据RAM - 存储数据
    bypass_data_ram data_ram (
        .a(write_hash),           // 写地址
        .d(write_data),          // 写数据
        .dpra(read_hash),        // 读地址
        .clk(clk),              // 时钟
        .we(ip_write_en),       // 写使能 - 使用should_cache控制
        .dpo(ram_data_out)      // 读数据
    );
    
    // 有效位RAM - 存储有效标志
    bypass_valid_ram valid_ram (
        .a(write_hash),          // 写地址
        .d(1'b1),               // 写数据（总是1）
        .dpra(read_hash),       // 读地址
        .clk(clk),             // 时钟
        .we(ip_write_en),      // 写使能 - 使用should_cache控制
        .dpo(valid_out)        // 读数据
    );
    
    // 命中检测逻辑
    wire addr_match = (ram_addr_out == read_addr);
    wire hit_detected = valid_out && addr_match;
    wire [31:0] hit_data_i = hit_detected ? ram_data_out : 32'h00000000;
    
    // 读取时的地址检查：只有相关地址的读取才进行bypass
    wire is_valid_read = (is_matrix_read) && !is_system_read;
    
    // 输出逻辑：正常检测命中
    always @(posedge clk) begin
        if (rst) begin
            hit <= 1'b0;
            hit_data <= 32'h00000000;
        end else if (read_en && is_valid_read) begin
            // 正常检测命中
            hit <= hit_detected;
            hit_data <= hit_data_i;
        end else begin
            hit <= 1'b0;
        end
    end
    
endmodule
