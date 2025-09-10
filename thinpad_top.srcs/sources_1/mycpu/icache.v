`include "defines.v"

module icache (
    input wire clk,
    input wire rst,
    input wire[`InstAddrBus]    pc,
    input wire[`InstBus]        inst_i,
    input wire                  baseram_stallreq,

    output wire[31:0]           inst_from_cache,
    output wire                 icache_stallreq
);

    /* �������� */
    parameter LINES = 32;           // Cache ������ֱ��ӳ�䣩
    parameter TAG_WIDTH = 15;       // ���λ��
    parameter INDEX_WIDTH = 5;      // ����λ��
    
    wire [TAG_WIDTH-1:0]    pc_tag   = pc[21:INDEX_WIDTH+2];    // �ӵ�ַ����ȡ���
    wire [INDEX_WIDTH-1:0]  pc_index = pc[INDEX_WIDTH+1:2];     // �ӵ�ַ����ȡ����
    
    /* Cache �洢�ṹ */
    reg [31:0]          cache_data[0:LINES-1];   // �������ݴ洢
    reg [TAG_WIDTH-1:0] cache_tag[0:LINES-1];    // �����Ǵ洢
    reg                 cache_valid[0:LINES-1];  // ������Чλ

    /* ״̬�� */
    parameter IDLE = 2'b00;
    parameter WAIT = 2'b01;
    parameter READY = 2'b10;
    parameter OK = 2'b11;
    reg [1:0] state, next_state;
    
    /* �����ж� */
    wire hit = (state == IDLE) && cache_valid[pc_index] && (cache_tag[pc_index] == pc_tag);
    assign icache_stallreq = ((state == IDLE) || (state == WAIT) || (state == READY)) && ~hit;
    
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
            OK: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    /* cache дʹ�� */
    reg write_enable;
    wire we = (state == READY && next_state == OK);
    always @(posedge clk) begin
        if (rst) begin
            write_enable <= 0;
        end else begin
            write_enable <= we;
        end
    end
    
    /* Cache ���� */
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LINES; i = i + 1) begin
                cache_valid[i] <= 1'b0;
            end
        end else if (write_enable) begin
            cache_data[pc_index] <= inst_i;
            cache_tag[pc_index] <= pc_tag;
            cache_valid[pc_index] <= 1'b1;
        end
    end
    
    /* ָ����� */
    assign inst_from_cache = (state == OK) ? inst_i :
                             (state == IDLE && hit) ? cache_data[pc_index] : `ZeroWord;
    
endmodule

