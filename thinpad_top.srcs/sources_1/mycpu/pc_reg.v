// ������һ��ָ��ĵ�ַ

`include "defines.v"
module pc_reg (
    input wire                  clk,
    input wire                  rst,
    input wire[0:5]             stallreq,
	// id�׶���ǰ���з�֧��ת�ж�
	input wire                  branch_flag_i,
	input wire[`RegBus]         branch_target_address_i,
	
	output reg[`InstAddrBus]    pc,
	output reg                  ce
);
    
    wire reset = rst | (stallreq[0] == `Stop & stallreq[1] == `NoStop);
    wire keep  = stallreq[0] == `Stop & stallreq[1] == `Stop;
    wire [`InstAddrBus] next_pc = (branch_flag_i == `Branch) ? branch_target_address_i : pc+4;
    
    // ȷ��pc
    always @(posedge clk) begin
        if(reset) begin
            pc <= 32'h80000000;
        end else if(keep) begin
            pc <= pc;
//        end else begin
//            pc <= next_pc;
        end else if(branch_flag_i == `Branch) begin
            pc <= branch_target_address_i;
        end else begin
            pc <= pc + 4;
        end
    end
    
//     ָ��洢��Ƭѡʹ���ź�
    always @(posedge clk) begin
        if(rst) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end
    
endmodule
