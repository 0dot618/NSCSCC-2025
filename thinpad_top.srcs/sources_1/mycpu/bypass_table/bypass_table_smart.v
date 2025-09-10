module bypass_table_smart #(
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
    
    // ���ܵ�ַ����
    wire[15:0] write_page = write_addr[31:16];  // ҳ��
    wire[15:0] read_page = read_addr[31:16];
    wire[15:0] write_offset = write_addr[15:0]; // ҳ��ƫ��
    wire[15:0] read_offset = read_addr[15:0];
    
    // ������ģʽ
    wire same_page = (write_page == read_page);
    wire sequential_access = (write_offset + 4 == read_offset);
    wire matrix_access = (write_offset[15:8] == read_offset[15:8]); // ͬ������
    wire stream_access = (write_page == 16'h8010 && read_page == 16'h8040); // STREAMģʽ
    
    // �����߼� - ��������߼���ʱ���߼�
    reg found_read;
    reg[2:0] found_read_index;
    reg[3:0] match_quality; // ƥ��������0=��ƥ�䣬1=��ַƥ�䣬2=ҳƥ�䣬3=ģʽƥ��
    integer i;
    
    // ����߼����������ƥ��
    always @(*) begin
        found_read = 1'b0;
        found_read_index = 0;
        match_quality = 0;
        
        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            if (valid_table[i]) begin
                // ��ȫ��ַƥ��
                if (addr_table[i] == read_addr) begin
                    if (!found_read || match_quality < 4'd1) begin
                        found_read = 1'b1;
                        found_read_index = i;
                        match_quality = 4'd1;
                    end
                end
                // ͬҳƥ��
                else if (addr_table[i][31:16] == read_page) begin
                    if (!found_read || match_quality < 4'd2) begin
                        found_read = 1'b1;
                        found_read_index = i;
                        match_quality = 4'd2;
                    end
                end
                // ģʽƥ�䣨������ʣ�
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
    // д���߼��������滻����
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
            // ����д�����ȼ�
            if (stream_access) begin
                write_priority = 4'd4; // STREAMģʽ���ȼ����
            end else if (matrix_access) begin
                write_priority = 4'd3; // ����ģʽ���ȼ���
            end else if (sequential_access) begin
                write_priority = 4'd2; // ˳��������ȼ��е�
            end else begin
                write_priority = 4'd1; // �����������ȼ���
            end
            
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
                // �����滻�������滻�����ȼ���Ŀ
                replace_candidate = 0;
                lowest_priority = 4'd15;
                
                for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                    if (!valid_table[i]) begin
                        replace_candidate = i;
                        lowest_priority = 4'd0;
                    end else begin
                        // ���������Ӹ����ӵ��滻����
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
    
    // ��ȡ�߼�������ƥ��������������
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