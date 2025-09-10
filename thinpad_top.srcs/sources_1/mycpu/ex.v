// 执行运算，访存地址计算，分支目标计算与分支历史记录更新
`include "defines.v"

module ex (
    input wire clk,
    input wire rst,
    input wire[`AluOpBus]       alu_op,
	input wire[`RegBus]         rdata1,
	input wire[`RegBus]         rdata2,
    input wire[`InstAddrBus]    pc_8,
    input wire[`InstBus]        inst,

    //访存相关变量
    output wire[2:0]         ls_op,
    output wire[`RegBus]     ls_addr,
    output wire[`RegBus]     ls_data,
    output wire              ls_we,
    output wire              ls_ce,
    output wire[3:0]         ls_sel,
    output wire              this_inst_is_load,
    
    // 写回寄存器相关变量
    output wire[`RegBus]     wdata

);
    
    wire [31:0] alu_op_d;
    decoder_5_32 u_dec2(.in(alu_op  ), .out(alu_op_d  ));
    
    wire op_nop;   //空操作
    wire op_add;   //加法操作
    wire op_sub;   //减法操作
    wire op_slt;   //有符号比较，小于置位
    wire op_sltu;  //无符号比较，小于置位
    wire op_and;   //按位与
    wire op_or;    //按位或
    wire op_xor;   //按位异或
    wire op_nor;   //按位或非
    wire op_sll;   //逻辑左移
    wire op_srl;   //逻辑右移
    wire op_sra;   //算术右移
    wire op_mul;   
    wire op_jal;
    wire op_lb;   
    wire op_lw;   
    wire op_sb;   
    wire op_sw;   
    
    assign op_nop  = alu_op_d[ 0];
    assign op_add  = alu_op_d[ 1];
    assign op_sub  = alu_op_d[ 2];
    assign op_slt  = alu_op_d[ 3];
    assign op_sltu = alu_op_d[ 4];
    assign op_and  = alu_op_d[ 5];
    assign op_or   = alu_op_d[ 6];
    assign op_xor  = alu_op_d[ 7];
    assign op_nor  = alu_op_d[ 8];
    assign op_sll  = alu_op_d[ 9];
    assign op_srl  = alu_op_d[10];
    assign op_sra  = alu_op_d[11];
    assign op_mul  = alu_op_d[12];
    assign op_jal  = alu_op_d[13];
    assign op_lb   = alu_op_d[14];
    assign op_lw   = alu_op_d[15];
    assign op_sb   = alu_op_d[16];
    assign op_sw   = alu_op_d[17];

    assign this_inst_is_load = op_lb | op_lw;
    
    wire [31:0] add_sub_result; 
    wire [31:0] slt_result; 
    wire [31:0] sltu_result;
    wire [31:0] and_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] nor_result;
    wire [31:0] sll_result; 
    wire [63:0] sr64_result; 
    wire [31:0] sr_result; 
    wire [63:0] mul_result64;
    wire [31:0] mul_result;

    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire        adder_cin;
    wire [31:0] adder_result;
    wire        adder_cout;
    
    assign adder_a   = rdata1;
    assign adder_b   = (op_sub | op_slt | op_sltu) ? ~rdata2 : rdata2;
    assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
    assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;
    
    assign add_sub_result = adder_result;
    
    assign slt_result[31:1] = 31'b0;
    assign slt_result[0]    = (rdata1[31] & ~rdata2[31])
                            | ((rdata1[31] ~^ rdata2[31]) & adder_result[31]);
    assign sltu_result[31:1] = 31'b0;
    assign sltu_result[0]    = ~adder_cout;
    
    assign and_result = rdata1 & rdata2;
    assign or_result  = rdata1 | rdata2;
    assign xor_result = rdata1 ^ rdata2;
    assign nor_result = ~or_result;
    
    assign sll_result = rdata2 << rdata1[4:0];
    
    assign sr64_result = {{32{op_sra & rdata2[31]}}, rdata2[31:0]} >> rdata1[4:0];
    assign sr_result   = sr64_result[31:0];
    
    wire [15:0] a1 = rdata1[31:16];
    wire [15:0] a2 = rdata1[15:0];
    wire [15:0] b1 = rdata2[31:16];
    wire [15:0] b2 = rdata2[15:0];
    reg [31:0] t1, t2, t3;
    always @(posedge clk) begin
        t1 <= a2 * b2;
        t2 <= a1 * b2;
        t3 <= a2 * b1;
    end
    wire [31:0] t2_t3_low16 = {16'b0, t2[15:0] + t3[15:0]};
    assign mul_result64 = t1 + (t2_t3_low16 << 16);
    assign mul_result = mul_result64[31:0];

    /*----------------------写回寄存器相关变量---------------------------------------------------------------------*/
    assign wdata = ({32{op_add|op_sub}} & add_sub_result)
                 | ({32{op_slt       }} & slt_result)
                 | ({32{op_sltu      }} & sltu_result)
                 | ({32{op_and       }} & and_result)
                 | ({32{op_or        }} & or_result)
                 | ({32{op_xor       }} & xor_result)
                 | ({32{op_nor       }} & nor_result)
                 | ({32{op_sll       }} & sll_result)
                 | ({32{op_srl|op_sra}} & sr_result)
                 | ({32{op_mul       }} & mul_result)
                 | ({32{op_jal       }} & pc_8);            // 指令jal、jalr
                                                            // 全0：L型指令、S型指令、无需写回的其他指令
    
    /*----------------------访存相关 提前计算：L型指令、S型指令--------------------------------------------------------*/
    wire[`RegBus] mem_addr = rdata1 + {{16{inst[15]}}, inst[15:0]};
    wire[3:0] sel_n = ~(4'b1 << mem_addr[1:0]);
    
    assign ls_op  = ({3{op_lb}} & `MEM_LB_OP)         
                  | ({3{op_lw}} & `MEM_LW_OP)
                  | ({3{op_sb}} & `MEM_SB_OP)
                  | ({3{op_sw}} & `MEM_SW_OP)
                  | `MEM_NOP_OP;
    assign ls_addr = ({32{op_lb | op_lw | op_sb | op_sw}} & mem_addr);
    assign ls_data  = ({32{op_sb}} & {{24{rdata2[7]}}, rdata2[7:0]})         
                    | ({32{op_sw}} & rdata2);
    assign ls_we = (!op_sb & !op_sw) & `WriteDisable_n;
    assign ls_ce = op_lb | op_lw | op_sb | op_sw;
    assign ls_sel  = (op_sw | op_lw) ? 4'b0000        
                   : (op_sb | op_lb) ? sel_n
                   : 4'b1111;
    
endmodule
