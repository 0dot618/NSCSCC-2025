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

    /* 参数定义 */
    parameter LINES = 32;           // Cache 行数（直接映射）
    parameter TAG_WIDTH = 15;       // 标记位宽
    parameter INDEX_WIDTH = 5;      // 索引位宽
    
    wire [TAG_WIDTH-1:0]    pc_tag   = pc[21:INDEX_WIDTH+2];    // 从地址中提取标记
    wire [INDEX_WIDTH-1:0]  pc_index = pc[INDEX_WIDTH+1:2];     // 从地址中提取索引
    
    /* 状态机 */
    parameter IDLE  = 2'b00;
    parameter WAIT  = 2'b01;
    parameter READY = 2'b10;
    parameter OK    = 2'b11;
    reg [1:0] state, next_state;

    /* IP 存储体：数据、标记+有效位 */
    wire[`InstBus]          cache_data_rd;           // 从数据 RAM 读出的指令
    wire[TAG_WIDTH:0]       tag_and_valid_rd;        // 从 tag RAM 读出的 {tag, valid}
    wire[TAG_WIDTH-1:0]     cache_tag_rd   = tag_and_valid_rd[TAG_WIDTH:1];
    wire                    cache_valid_rd = tag_and_valid_rd[0];
    
    assign pc2rom = pc;

    // 写入的数据（仅在写使能时使用）
    wire[TAG_WIDTH:0]       tag_and_valid_wr = {pc_tag, 1'b1};

    // 命中判断
    wire hit = (state == IDLE) && (cache_valid_rd === 1'b1) && (cache_tag_rd == pc_tag);
    assign icache_stallreq = ((state == IDLE) || (state == WAIT) || (state == READY)) && ~hit;
//    assign icache_stallreq = ((state == IDLE) || (state == WAIT)) && ~hit;

    /* 状态转移 */
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
    
    /* cache 写使能 */
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

    /* IP 实例：数据 RAM 与 tag RAM */
    icache_data_ram icache_ram_0 (
        .clk (clk),
        .a   (pc_index),           // 写地址
        .d   (inst_i),             // 写数据
        .dpra(pc_index),           // 读地址
        .we  (write_enable),       // 写使能
        .dpo (cache_data_rd)       // 读数据
    );

    icache_tag_ram tag_ram_0 (
        .clk (clk),
        .a   (pc_index),           // 写地址
        .d   (tag_and_valid_wr),   // 写 {tag, valid=1}
        .dpra(pc_index),           // 读地址
        .we  (write_enable),       // 写使能
        .dpo (tag_and_valid_rd)    // 读 {tag, valid}
    );

    /* 指令输出 */
    assign inst_from_cache = (state == OK) ? inst_i :
//    assign inst_from_cache = (state == READY) ? inst_i :
                             (state == IDLE && hit) ? cache_data_rd : `ZeroWord;

endmodule
