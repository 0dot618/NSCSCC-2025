// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Wed Aug 13 19:24:17 2025
// Host        : LYL5BCF running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/220110504/code/mycpu8.12/thinpad_top.srcs/sources_1/ip/icache_tag_ram/icache_tag_ram_stub.v
// Design      : icache_tag_ram
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "dist_mem_gen_v8_0_13,Vivado 2019.2" *)
module icache_tag_ram(a, d, dpra, clk, we, dpo)
/* synthesis syn_black_box black_box_pad_pin="a[4:0],d[15:0],dpra[4:0],clk,we,dpo[15:0]" */;
  input [4:0]a;
  input [15:0]d;
  input [4:0]dpra;
  input clk;
  input we;
  output [15:0]dpo;
endmodule
