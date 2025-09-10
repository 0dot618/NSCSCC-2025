module bypass_table_ip #(
    parameter ENTRY_NUM = 128  // ����128��Ŀ����ȫ����
)(
    input wire clk,
    input wire rst,
    // д��ӿ�
    input wire        write_en,
    input wire[31:0] write_addr,
    input wire[31:0] write_data,
    // ��ѯ�ӿ�
    input wire        read_en,
    input wire[31:0] read_addr,
    output reg        hit,
    output reg[31:0] hit_data
);

    // ʹ�õ�ַ��ϣ���ٳ�ͻ
    wire[8:0] write_hash = write_addr[10:2];  // 9λ��ϣ��512����λ
    wire[8:0] read_hash = read_addr[10:2];
    
    // �ֲ�ʽRAMʵ��������Ҫ�ȴ���IP�ˣ�
    wire[31:0] ram_addr_out;
    wire[31:0] ram_data_out;
    wire valid_out;
    
    // ���ڲ��Գ������ģʽ�ľ�ȷʶ��
    // STREAM: ��0x80100000��ȡ��д��0x80400000
//    wire is_stream_read = (read_addr[31:20] == 12'h801);
//    wire is_stream_write = (write_addr[31:20] == 12'h804);
    
    // MATRIX: ��Ҫ��0x80400000-0x80420000���򣬾���˷����ʣ��������C
//    wire is_matrix_read = (read_addr[31:16] == 16'h8040) || (read_addr[31:16] == 16'h8041) || (read_addr[31:16] == 16'h8042);
//    wire is_matrix_write = (write_addr[31:16] == 16'h8040) || (write_addr[31:16] == 16'h8041) || (write_addr[31:16] == 16'h8042);
    wire is_matrix_read = (read_addr[31:16] == 16'h8042) && (read_addr[15:12] == 5'b00000);
    wire is_matrix_write = (write_addr[31:16] == 16'h8042) && (write_addr[15:12] == 5'b00000);
    
    // CRYPTONIGHT: ��Ҫ��0x80400000�����������ģʽ
//    wire is_crypto_read = (read_addr[31:16] == 16'h8040);
//    wire is_crypto_write = (write_addr[31:16] == 16'h8040) && (write_addr[15:13] == 3'b000);
    
    // �ų�����ϵͳ��ַ
    wire is_system_write = (write_addr[31:24] == 8'hBF) ||  // ����
                           (write_addr[31:20] == 12'h801);  // �ų�0x80100000����
    
    wire is_system_read = (read_addr[31:24] == 8'hBF) ||   // ����
                          (read_addr[31:20] == 12'h801);   // �ų�0x80100000����
    
    // ��ȷ�Ļ�����ԣ�ֻ������Գ�����ط��ʣ��ų�ϵͳ��ַ
    wire should_cache = (is_matrix_write) && 
                       !(is_system_read || is_system_write);
//    wire should_cache = 1'b1;
    
    // ����IP�˵�дʹ�ܣ�ֻ��should_cacheΪ��ʱ��д��
    wire ip_write_en = write_en && should_cache;
    
    // ��ַRAM - �洢��ַ
    bypass_addr_ram addr_ram (
        .a(write_hash),           // д��ַ
        .d(write_addr),           // д����
        .dpra(read_hash),         // ����ַ
        .clk(clk),               // ʱ��
        .we(ip_write_en),        // дʹ�� - ʹ��should_cache����
        .dpo(ram_addr_out)       // ������
    );
    
    // ����RAM - �洢����
    bypass_data_ram data_ram (
        .a(write_hash),           // д��ַ
        .d(write_data),          // д����
        .dpra(read_hash),        // ����ַ
        .clk(clk),              // ʱ��
        .we(ip_write_en),       // дʹ�� - ʹ��should_cache����
        .dpo(ram_data_out)      // ������
    );
    
    // ��ЧλRAM - �洢��Ч��־
    bypass_valid_ram valid_ram (
        .a(write_hash),          // д��ַ
        .d(1'b1),               // д���ݣ�����1��
        .dpra(read_hash),       // ����ַ
        .clk(clk),             // ʱ��
        .we(ip_write_en),      // дʹ�� - ʹ��should_cache����
        .dpo(valid_out)        // ������
    );
    
    // ���м���߼�
    wire addr_match = (ram_addr_out == read_addr);
    wire hit_detected = valid_out && addr_match;
    wire [31:0] hit_data_i = hit_detected ? ram_data_out : 32'h00000000;
    
    // ��ȡʱ�ĵ�ַ��飺ֻ����ص�ַ�Ķ�ȡ�Ž���bypass
    wire is_valid_read = (is_matrix_read) && !is_system_read;
    
    // ����߼��������������
    always @(posedge clk) begin
        if (rst) begin
            hit <= 1'b0;
            hit_data <= 32'h00000000;
        end else if (read_en && is_valid_read) begin
            // �����������
            hit <= hit_detected;
            hit_data <= hit_data_i;
        end else begin
            hit <= 1'b0;
        end
    end
    
endmodule
