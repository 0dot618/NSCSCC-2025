module bypass_table_simple #(
    parameter ENTRY_NUM = 8  // ����8����Ŀ������ؼ�·��
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
    
    reg[31:0] addr_table [0:ENTRY_NUM-1];
    reg[31:0] data_table [0:ENTRY_NUM-1];
    reg        valid_table [0:ENTRY_NUM-1];
    reg[2:0]   replace_ptr;
    
    // ����ض����Գ���ĵ�ַ��Χ���
    wire is_stream_write = (write_addr[31:20] == 12'h801);  // 0x80100000����
    wire is_stream_read = (read_addr[31:20] == 12'h804);    // 0x80400000����
    wire is_matrix_access = (write_addr[31:16] == 16'h8040 || read_addr[31:16] == 16'h8040); // ��������
    wire is_crypto_access = (write_addr[31:16] == 16'h8040 || read_addr[31:16] == 16'h8040); // ��������
    
    // ֻ�����ض�ģʽ�ķ���
    wire should_cache = is_stream_write || is_matrix_access || is_crypto_access;
    
    // �����߼� - ��������߼���ʱ���߼�
    reg found_read;
    reg[2:0] found_read_index;
    integer i;
    
    // ����߼�������ƥ��
    always @(*) begin
        found_read = 1'b0;
        found_read_index = 0;
        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            if (valid_table[i] && addr_table[i] == read_addr) begin
                found_read = 1'b1;
                found_read_index = i;
            end
        end
    end
    
    // д���߼���ֻ�����ض�ģʽ�ķ���
    reg found_write;
    reg[2:0] found_write_index;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                addr_table[i] <= 32'h00000000;
                data_table[i] <= 32'h00000000;
                valid_table[i] <= 1'b0;
            end
            replace_ptr <= 0;
        end else if (write_en && should_cache) begin  // ֻ�����ض�ģʽ
            // �����Ƿ��Ѵ���
            found_write = 1'b0;
            found_write_index = 0;
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                if (valid_table[i] && addr_table[i] == write_addr) begin
                    found_write = 1'b1;
                    found_write_index = i;
                end
            end
            
            if (found_write) begin
                // �����Ѵ��ڵ���Ŀ
                data_table[found_write_index] <= write_data;
            end else begin
                // ��������Ŀ
                addr_table[replace_ptr] <= write_addr;
                data_table[replace_ptr] <= write_data;
                valid_table[replace_ptr] <= 1'b1;
                replace_ptr <= (replace_ptr == ENTRY_NUM-1) ? 0 : replace_ptr + 1;
            end
        end
    end
    
    // ��ȡ�߼���ʱ�����
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