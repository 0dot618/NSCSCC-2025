`include "defines.v"

module if_id (
    input wire              clk,
    input wire              rst,
    input wire[0:5]         stallreq,

	input wire[`InstAddrBus]   if_pc,
	input wire[`InstBus]       if_inst,
	output reg[`InstAddrBus]   id_pc,
	output reg[`InstBus]       id_inst  
);
    
    wire reset = rst | (stallreq[1] == `Stop & stallreq[2] == `NoStop);
    wire keep  = stallreq[1] == `Stop & stallreq[2] == `Stop;
    wire[`InstAddrBus]  id_pc_next = if_pc;
    wire[`InstBus]      id_inst_next = if_inst;
    always @(posedge clk) begin
        if (reset) begin
            id_pc <= 32'h80000000;
            id_inst <= `ZeroWord;
        end else if (keep) begin
            id_pc <= id_pc;
            id_inst <= id_inst;
        end else begin
            id_pc <= id_pc_next;
            id_inst <= id_inst_next;
        end
    end
    
endmodule