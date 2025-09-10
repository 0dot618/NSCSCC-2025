`include "defines.v"

module id_ex (
    input wire clk,
    input wire rst,
    input wire[0:5] stallreq,

    input wire[`AluOpBus]   id_aluop,
    input wire[`RegBus]     id_data1,
    input wire[`RegBus]     id_data2,
    input wire[`RegAddrBus] id_wR,
    input wire              id_we,
    input wire[`InstAddrBus] id_pc_8,
    input wire[`InstBus]    id_inst,
    
    output reg[`AluOpBus]   ex_aluop,
    output reg[`RegBus]     ex_data1,
    output reg[`RegBus]     ex_data2,
    output reg[`RegAddrBus] ex_wR,
    output reg              ex_we,
    output reg[`InstAddrBus] ex_pc_8,
    output reg[`InstBus]    ex_inst,

    output reg mul_stallreq
);

    wire reset = rst | (stallreq[2] == `Stop & stallreq[3] == `NoStop);
    wire keep  = stallreq[2] == `Stop & stallreq[3] == `Stop;
    
    // 分离关键数据传递，预计算所有输出值
    wire [31:0] ex_data1_next;
    wire [31:0] ex_data2_next;
    wire [7:0] ex_aluop_next;
    wire [4:0] ex_wR_next;
    wire ex_we_next;
    wire [31:0] ex_pc_8_next;
    wire [31:0] ex_inst_next;
    wire mul_stallreq_next;
    assign ex_data1_next = id_data1;
    assign ex_data2_next = id_data2;
    assign ex_aluop_next = id_aluop;
    assign ex_wR_next = id_wR;
    assign ex_we_next = id_we;
    assign ex_pc_8_next = id_pc_8;
    assign ex_inst_next = id_inst;
    assign mul_stallreq_next = (id_aluop == `EXE_MUL_OP);
    
    always @(posedge clk) begin
        if (reset) begin
            ex_aluop <= `EXE_NOP_OP;
            ex_wR <= `NOPRegAddr;
            ex_we <= `WriteDisable;
            ex_pc_8 <= `ZeroWord;
            ex_inst <= `ZeroWord;
            mul_stallreq <= `NoStop;
        end else if (keep) begin
            ex_aluop <= ex_aluop;
            ex_wR <= ex_wR;
            ex_we <= ex_we;
            ex_pc_8 <= ex_pc_8;
            ex_inst <= ex_inst;
            mul_stallreq <= `NoStop;
        end else begin
            ex_aluop <= ex_aluop_next;
            ex_wR <= ex_wR_next;
            ex_we <= ex_we_next;
            ex_pc_8 <= ex_pc_8_next;
            ex_inst <= ex_inst_next;
            mul_stallreq <= mul_stallreq_next;
        end
    end
    
    // 独立处理关键数据寄存器
    always @(posedge clk) begin
        if (reset) begin
            ex_data1 <= `ZeroWord;
            ex_data2 <= `ZeroWord;
        end else if (keep) begin
            ex_data1 <= ex_data1;
            ex_data2 <= ex_data2;
        end else begin
            ex_data1 <= ex_data1_next;
            ex_data2 <= ex_data2_next;
        end
    end
    
endmodule