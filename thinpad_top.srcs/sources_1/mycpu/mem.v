
`include "defines.v"

module mem (
    input wire clk,
    input wire rst,
    input wire[2:0]         ls_op,
    input wire[`RegBus]     wdata_i,
    input wire[`RegBus]     ram_data_i,
    // 旁路表接口
    input wire              bypass_hit_i,
    input wire[`RegBus]     bypass_data_i,
    // write buffer旁路
    input wire              read_hit_i,      // write buffer
    input wire[`RegBus]     read_bypass_i,
    output wire[`RegBus]    wdata_o
);
    // 优先级：bypass > write buffer > RAM
//    wire[`RegBus] read_data = read_hit_i ? read_bypass_i : ram_data_i;
    wire[`RegBus] read_data = bypass_hit_i ? bypass_data_i : (read_hit_i ? read_bypass_i : ram_data_i);
    assign wdata_o = (ls_op == `MEM_LB_OP || ls_op == `MEM_LW_OP) ? read_data : wdata_i;
endmodule