`include "defines.v"

module regfile (
    input wire clk,
    input wire rst,
    input wire              we,
    input wire[`RegAddrBus] wR,
    input wire[`RegBus]     wD,
    input wire              re1,
    input wire              re2,
    input wire[`RegAddrBus] rR1,
    input wire[`RegAddrBus] rR2,
    
    output wire[`RegBus]    rD1,
    output wire[`RegBus]    rD2
);

    // ¼Ä´æÆ÷¶Ñ³õÊ¼»¯
    reg[31:0] register[0:31];
    integer i;

    /*----------------------Ð´----------------------*/
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < 32; i = i + 1) begin
                register[i] <= `ZeroWord;
            end
        end else if(we & (|wR)) begin
            register[wR] <= wD;
        end
    end
    
    /*----------------------¶Á----------------------*/
    assign rD1 = (~re1 | (~|rR1))  ? `ZeroWord : 
                 (~|(rR1 ^ wR) && we) ? wD :
                                     register[rR1];
    assign rD2 = (~re2 | (~|rR2))  ? `ZeroWord : 
                 (~|(rR2 ^ wR) && we) ? wD :
                                     register[rR2];
    
endmodule