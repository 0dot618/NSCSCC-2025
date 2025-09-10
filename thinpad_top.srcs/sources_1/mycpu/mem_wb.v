`include "defines.v"

module mem_wb (
    input wire clk,
    input wire rst,

    input wire mem_we,
    input wire[`RegAddrBus] mem_wR,
    input wire[`RegBus] mem_wdata,

    input wire[0:5]             stallreq,

    output reg wb_we,
    output reg[`RegAddrBus] wb_wR,
    output reg[`RegBus] wb_wdata
);

    wire reset = rst | (stallreq[4] == `Stop & stallreq[5] == `NoStop);
    wire keep  = stallreq[4] == `Stop & stallreq[5] == `Stop;
    always @(posedge clk) begin
        if(reset) begin
            wb_we <= `WriteDisable;
            wb_wR <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
        end else if (keep) begin
            wb_we <= wb_we;
            wb_wR <= wb_wR;
            wb_wdata <= wb_wdata;
        end else begin
            wb_we <= mem_we;
            wb_wR <= mem_wR;
            wb_wdata <= mem_wdata;
        end
    end
    
endmodule