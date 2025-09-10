`include "defines.v"

module icache_dram (
    input wire clk,
    input wire rst,
    input wire[`InstAddrBus]    pc,
    input wire[`InstBus]        inst_i,
    input wire                  baseram_stallreq,

    output wire[`InstAddrBus]   pc2rom,
    output wire[31:0]           inst_from_cache,
    output wire                 icache_stallreq
);

    /* �������� */
    parameter LINES = 32;           // Cache ������ֱ��ӳ�䣩
    parameter TAG_WIDTH = 15;       // ���λ��
    parameter INDEX_WIDTH = 5;      // ����λ��
    
    wire [TAG_WIDTH-1:0]    pc_tag   = pc[21:INDEX_WIDTH+2];    // �ӵ�ַ����ȡ���
    wire [INDEX_WIDTH-1:0]  pc_index = pc[INDEX_WIDTH+1:2];     // �ӵ�ַ����ȡ����
    
    /* ״̬�� */
    parameter IDLE  = 2'b00;
    parameter WAIT  = 2'b01;
    parameter READY = 2'b10;
    parameter OK    = 2'b11;
    reg [1:0] state, next_state;

    /* IP �洢�壺���ݡ����+��Чλ */
    wire[`InstBus]          cache_data_rd;           // ������ RAM ������ָ��
    wire[TAG_WIDTH:0]       tag_and_valid_rd;        // �� tag RAM ������ {tag, valid}
    wire[TAG_WIDTH-1:0]     cache_tag_rd   = tag_and_valid_rd[TAG_WIDTH:1];
    wire                    cache_valid_rd = tag_and_valid_rd[0];
    
    assign pc2rom = pc;

    // д������ݣ�����дʹ��ʱʹ�ã�
    wire[TAG_WIDTH:0]       tag_and_valid_wr = {pc_tag, 1'b1};

    // �����ж�
    wire hit = (state == IDLE) && (cache_valid_rd === 1'b1) && (cache_tag_rd == pc_tag);
    assign icache_stallreq = ((state == IDLE) || (state == WAIT) || (state == READY)) && ~hit;
//    assign icache_stallreq = ((state == IDLE) || (state == WAIT)) && ~hit;

    /* ״̬ת�� */
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (hit || baseram_stallreq)
                    next_state = IDLE;
                else
                    next_state = WAIT;
            end
            WAIT: begin
                if (baseram_stallreq)
                    next_state = IDLE;
                else
                    next_state = READY;
            end
            READY: begin
                if (baseram_stallreq)
                    next_state = IDLE;
                else
                    next_state = OK;
            end
//            READY: next_state = IDLE;
            OK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    /* cache дʹ�� */
    reg write_enable;
    wire we = (state == READY && next_state == OK);
//    wire we = (state == READY);
    always @(posedge clk) begin
        if (rst) begin
            write_enable <= 0;
        end else begin
            write_enable <= we;
        end
    end

    /* IP ʵ�������� RAM �� tag RAM */
    icache_data_ram icache_ram_0 (
        .clk (clk),
        .a   (pc_index),           // д��ַ
        .d   (inst_i),             // д����
        .dpra(pc_index),           // ����ַ
        .we  (write_enable),       // дʹ��
        .dpo (cache_data_rd)       // ������
    );

    icache_tag_ram tag_ram_0 (
        .clk (clk),
        .a   (pc_index),           // д��ַ
        .d   (tag_and_valid_wr),   // д {tag, valid=1}
        .dpra(pc_index),           // ����ַ
        .we  (write_enable),       // дʹ��
        .dpo (tag_and_valid_rd)    // �� {tag, valid}
    );

    /* ָ����� */
    assign inst_from_cache = (state == OK) ? inst_i :
//    assign inst_from_cache = (state == READY) ? inst_i :
                             (state == IDLE && hit) ? cache_data_rd : `ZeroWord;

endmodule
