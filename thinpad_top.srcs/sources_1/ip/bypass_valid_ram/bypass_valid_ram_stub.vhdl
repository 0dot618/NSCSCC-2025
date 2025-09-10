-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Wed Jul 30 22:32:11 2025
-- Host        : 614-07 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top bypass_valid_ram -prefix
--               bypass_valid_ram_ bypass_valid_ram_stub.vhdl
-- Design      : bypass_valid_ram
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a200tfbg676-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bypass_valid_ram is
  Port ( 
    a : in STD_LOGIC_VECTOR ( 8 downto 0 );
    d : in STD_LOGIC_VECTOR ( 0 to 0 );
    dpra : in STD_LOGIC_VECTOR ( 8 downto 0 );
    clk : in STD_LOGIC;
    we : in STD_LOGIC;
    dpo : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end bypass_valid_ram;

architecture stub of bypass_valid_ram is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "a[8:0],d[0:0],dpra[8:0],clk,we,dpo[0:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "dist_mem_gen_v8_0_13,Vivado 2019.2";
begin
end;
