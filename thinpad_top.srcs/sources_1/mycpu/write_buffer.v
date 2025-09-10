`include "defines.v"

module write_buffer (
    input wire clk,
    input wire rst,
    
    // ����CPU��д����
    input wire[`RegBus]     wb_addr_i,      // д��ַ
    input wire[`RegBus]     wb_data_i,      // д����
    input wire              wb_we_i,        // дʹ�ܣ�����Ч��
    input wire              wb_ce_i,        // Ƭѡʹ��
    input wire[3:0]         wb_sel_i,       // �ֽ�ѡ��
    input wire              wb_valid_i,     // д������Ч
    
    // ������ڴ�
    output reg[`RegBus]     wb_addr_o,      // д��ַ
    output reg[`RegBus]     wb_data_o,      // д����
    output reg              wb_we_o,        // дʹ�ܣ�����Ч��
    output reg              wb_ce_o,        // Ƭѡʹ��
    output reg[3:0]         wb_sel_o,       // �ֽ�ѡ��
    output reg              wb_valid_o,     // д������Ч
    
    // ״̬�ź�
    output wire             wb_full,        // buffer��
    output wire             wb_empty,       // buffer��
    input wire              wb_ready_i,     // �ڴ�׼���ý���
    
    // ��·֧�� - ������ʱ����Ƿ�����write buffer
    input wire[`RegBus]     read_addr_i,    // ����ַ
    input wire              read_valid_i,   // ��������Ч
    output wire             read_hit_o,     // ����ַ����write buffer
    output wire[`RegBus]    read_data_o     // ��·���ݣ�������У�
);

    // 1���FIFO�Ĵ���
    reg[`RegBus]     addr_reg;
    reg[`RegBus]     data_reg;
    reg              we_reg;
    reg              ce_reg;
    reg[3:0]         sel_reg;
    reg              valid_reg;
    
    // ״̬�Ĵ���
    reg              has_data;      // �Ƿ���������buffer��
    
    // Ԥ�����ַ�ȽϽ�������ٹؼ�·���ӳ�
    reg              addr_match_reg;
    reg              read_hit_reg;
    
    // �����ֵ
    assign wb_full = has_data && !wb_ready_i;
    assign wb_empty = !has_data;
    
    // ��·�߼� - Ԥ�����ַ�Ƚϣ����ٹؼ�·��
    always @(posedge clk) begin
        if (rst) begin
            addr_match_reg <= 1'b0;
            read_hit_reg <= 1'b0;
        end else begin
            // Ԥ�����ַƥ��
            addr_match_reg <= (read_addr_i == addr_reg);
            // Ԥ�������н��
            read_hit_reg <= has_data && read_valid_i && (read_addr_i == addr_reg);
        end
    end
    
    // ʹ��Ԥ����Ľ������������߼��ӳ�
    assign read_hit_o = read_hit_reg;
    assign read_data_o = read_hit_reg ? data_reg : `ZeroWord;
    
    // ����߼� - ʹ������߼��������ٸ��Ӷ�
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
    
    // Buffer�����߼� - �Ż�״̬�������ٹؼ�·��
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
            // ��״̬���߼�����������߼����Ӷ�
            if (buffer2ram) begin
                // �ڴ�׼���ã����buffer�е����ݣ����buffer
                has_data <= 1'b0;
                valid_reg <= 1'b0;
            end else if (wb2ram) begin
                // ֱ�Ӵ��ݣ�������
                has_data <= 1'b0;
            end else if (wb2buffer) begin
                // ��������
                has_data <= 1'b1;
                addr_reg <= wb_addr_i;
                data_reg <= wb_data_i;
                we_reg <= wb_we_i;
                ce_reg <= wb_ce_i;
                sel_reg <= wb_sel_i;
                valid_reg <= 1'b1;
            end else if (keep_buffer) begin
                // buffer�����ڴ�δ׼���ã�����״̬
                has_data <= 1'b1;
            end else if (wb2b2ram) begin
                // �Ż�����buffer���������ڴ�׼����ʱ����������������
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