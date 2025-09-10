-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Wed Jul 30 22:32:11 2025
-- Host        : 614-07 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim -rename_top bypass_valid_ram -prefix
--               bypass_valid_ram_ bypass_valid_ram_sim_netlist.vhdl
-- Design      : bypass_valid_ram
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xc7a200tfbg676-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bypass_valid_ram_sdpram is
  port (
    dpo : out STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC;
    d : in STD_LOGIC_VECTOR ( 0 to 0 );
    a : in STD_LOGIC_VECTOR ( 8 downto 0 );
    dpra : in STD_LOGIC_VECTOR ( 8 downto 0 );
    we : in STD_LOGIC
  );
end bypass_valid_ram_sdpram;

architecture STRUCTURE of bypass_valid_ram_sdpram is
  signal \^dpo\ : STD_LOGIC_VECTOR ( 0 to 0 );
  signal qsdpo_int : STD_LOGIC;
  attribute RTL_KEEP : string;
  attribute RTL_KEEP of qsdpo_int : signal is "true";
  signal ram_reg_0_127_0_0_i_1_n_0 : STD_LOGIC;
  signal ram_reg_0_127_0_0_n_0 : STD_LOGIC;
  signal ram_reg_0_127_0_0_n_1 : STD_LOGIC;
  signal ram_reg_128_255_0_0_i_1_n_0 : STD_LOGIC;
  signal ram_reg_128_255_0_0_n_0 : STD_LOGIC;
  signal ram_reg_128_255_0_0_n_1 : STD_LOGIC;
  signal ram_reg_256_383_0_0_i_1_n_0 : STD_LOGIC;
  signal ram_reg_256_383_0_0_n_0 : STD_LOGIC;
  signal ram_reg_256_383_0_0_n_1 : STD_LOGIC;
  signal ram_reg_384_511_0_0_i_1_n_0 : STD_LOGIC;
  signal ram_reg_384_511_0_0_n_0 : STD_LOGIC;
  signal ram_reg_384_511_0_0_n_1 : STD_LOGIC;
  attribute KEEP : string;
  attribute KEEP of \qsdpo_int_reg[0]\ : label is "yes";
  attribute equivalent_register_removal : string;
  attribute equivalent_register_removal of \qsdpo_int_reg[0]\ : label is "no";
  attribute METHODOLOGY_DRC_VIOS : string;
  attribute METHODOLOGY_DRC_VIOS of ram_reg_0_127_0_0 : label is "{SYNTH-5 {cell *THIS*}}";
  attribute RTL_RAM_BITS : integer;
  attribute RTL_RAM_BITS of ram_reg_0_127_0_0 : label is 512;
  attribute RTL_RAM_NAME : string;
  attribute RTL_RAM_NAME of ram_reg_0_127_0_0 : label is "synth_options.dist_mem_inst/gen_sdp_ram.sdpram_inst/ram";
  attribute ram_addr_begin : integer;
  attribute ram_addr_begin of ram_reg_0_127_0_0 : label is 0;
  attribute ram_addr_end : integer;
  attribute ram_addr_end of ram_reg_0_127_0_0 : label is 127;
  attribute ram_offset : integer;
  attribute ram_offset of ram_reg_0_127_0_0 : label is 0;
  attribute ram_slice_begin : integer;
  attribute ram_slice_begin of ram_reg_0_127_0_0 : label is 0;
  attribute ram_slice_end : integer;
  attribute ram_slice_end of ram_reg_0_127_0_0 : label is 0;
  attribute METHODOLOGY_DRC_VIOS of ram_reg_128_255_0_0 : label is "{SYNTH-5 {cell *THIS*}}";
  attribute RTL_RAM_BITS of ram_reg_128_255_0_0 : label is 512;
  attribute RTL_RAM_NAME of ram_reg_128_255_0_0 : label is "synth_options.dist_mem_inst/gen_sdp_ram.sdpram_inst/ram";
  attribute ram_addr_begin of ram_reg_128_255_0_0 : label is 128;
  attribute ram_addr_end of ram_reg_128_255_0_0 : label is 255;
  attribute ram_offset of ram_reg_128_255_0_0 : label is 0;
  attribute ram_slice_begin of ram_reg_128_255_0_0 : label is 0;
  attribute ram_slice_end of ram_reg_128_255_0_0 : label is 0;
  attribute METHODOLOGY_DRC_VIOS of ram_reg_256_383_0_0 : label is "{SYNTH-5 {cell *THIS*}}";
  attribute RTL_RAM_BITS of ram_reg_256_383_0_0 : label is 512;
  attribute RTL_RAM_NAME of ram_reg_256_383_0_0 : label is "synth_options.dist_mem_inst/gen_sdp_ram.sdpram_inst/ram";
  attribute ram_addr_begin of ram_reg_256_383_0_0 : label is 256;
  attribute ram_addr_end of ram_reg_256_383_0_0 : label is 383;
  attribute ram_offset of ram_reg_256_383_0_0 : label is 0;
  attribute ram_slice_begin of ram_reg_256_383_0_0 : label is 0;
  attribute ram_slice_end of ram_reg_256_383_0_0 : label is 0;
  attribute METHODOLOGY_DRC_VIOS of ram_reg_384_511_0_0 : label is "{SYNTH-5 {cell *THIS*}}";
  attribute RTL_RAM_BITS of ram_reg_384_511_0_0 : label is 512;
  attribute RTL_RAM_NAME of ram_reg_384_511_0_0 : label is "synth_options.dist_mem_inst/gen_sdp_ram.sdpram_inst/ram";
  attribute ram_addr_begin of ram_reg_384_511_0_0 : label is 384;
  attribute ram_addr_end of ram_reg_384_511_0_0 : label is 511;
  attribute ram_offset of ram_reg_384_511_0_0 : label is 0;
  attribute ram_slice_begin of ram_reg_384_511_0_0 : label is 0;
  attribute ram_slice_end of ram_reg_384_511_0_0 : label is 0;
begin
  dpo(0) <= \^dpo\(0);
\dpo[0]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AFA0CFCFAFA0C0C0"
    )
        port map (
      I0 => ram_reg_384_511_0_0_n_0,
      I1 => ram_reg_256_383_0_0_n_0,
      I2 => dpra(8),
      I3 => ram_reg_128_255_0_0_n_0,
      I4 => dpra(7),
      I5 => ram_reg_0_127_0_0_n_0,
      O => \^dpo\(0)
    );
\qsdpo_int_reg[0]\: unisim.vcomponents.FDRE
    generic map(
      INIT => '0'
    )
        port map (
      C => clk,
      CE => '1',
      D => \^dpo\(0),
      Q => qsdpo_int,
      R => '0'
    );
ram_reg_0_127_0_0: unisim.vcomponents.RAM128X1D
    generic map(
      INIT => X"00000000000000000000000000000000"
    )
        port map (
      A(6 downto 0) => a(6 downto 0),
      D => d(0),
      DPO => ram_reg_0_127_0_0_n_0,
      DPRA(6 downto 0) => dpra(6 downto 0),
      SPO => ram_reg_0_127_0_0_n_1,
      WCLK => clk,
      WE => ram_reg_0_127_0_0_i_1_n_0
    );
ram_reg_0_127_0_0_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"02"
    )
        port map (
      I0 => we,
      I1 => a(7),
      I2 => a(8),
      O => ram_reg_0_127_0_0_i_1_n_0
    );
ram_reg_128_255_0_0: unisim.vcomponents.RAM128X1D
    generic map(
      INIT => X"00000000000000000000000000000000"
    )
        port map (
      A(6 downto 0) => a(6 downto 0),
      D => d(0),
      DPO => ram_reg_128_255_0_0_n_0,
      DPRA(6 downto 0) => dpra(6 downto 0),
      SPO => ram_reg_128_255_0_0_n_1,
      WCLK => clk,
      WE => ram_reg_128_255_0_0_i_1_n_0
    );
ram_reg_128_255_0_0_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => a(8),
      I1 => a(7),
      I2 => we,
      O => ram_reg_128_255_0_0_i_1_n_0
    );
ram_reg_256_383_0_0: unisim.vcomponents.RAM128X1D
    generic map(
      INIT => X"00000000000000000000000000000000"
    )
        port map (
      A(6 downto 0) => a(6 downto 0),
      D => d(0),
      DPO => ram_reg_256_383_0_0_n_0,
      DPRA(6 downto 0) => dpra(6 downto 0),
      SPO => ram_reg_256_383_0_0_n_1,
      WCLK => clk,
      WE => ram_reg_256_383_0_0_i_1_n_0
    );
ram_reg_256_383_0_0_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => a(7),
      I1 => a(8),
      I2 => we,
      O => ram_reg_256_383_0_0_i_1_n_0
    );
ram_reg_384_511_0_0: unisim.vcomponents.RAM128X1D
    generic map(
      INIT => X"00000000000000000000000000000000"
    )
        port map (
      A(6 downto 0) => a(6 downto 0),
      D => d(0),
      DPO => ram_reg_384_511_0_0_n_0,
      DPRA(6 downto 0) => dpra(6 downto 0),
      SPO => ram_reg_384_511_0_0_n_1,
      WCLK => clk,
      WE => ram_reg_384_511_0_0_i_1_n_0
    );
ram_reg_384_511_0_0_i_1: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => we,
      I1 => a(7),
      I2 => a(8),
      O => ram_reg_384_511_0_0_i_1_n_0
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bypass_valid_ram_dist_mem_gen_v8_0_13_synth is
  port (
    dpo : out STD_LOGIC_VECTOR ( 0 to 0 );
    clk : in STD_LOGIC;
    d : in STD_LOGIC_VECTOR ( 0 to 0 );
    a : in STD_LOGIC_VECTOR ( 8 downto 0 );
    dpra : in STD_LOGIC_VECTOR ( 8 downto 0 );
    we : in STD_LOGIC
  );
end bypass_valid_ram_dist_mem_gen_v8_0_13_synth;

architecture STRUCTURE of bypass_valid_ram_dist_mem_gen_v8_0_13_synth is
begin
\gen_sdp_ram.sdpram_inst\: entity work.bypass_valid_ram_sdpram
     port map (
      a(8 downto 0) => a(8 downto 0),
      clk => clk,
      d(0) => d(0),
      dpo(0) => dpo(0),
      dpra(8 downto 0) => dpra(8 downto 0),
      we => we
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bypass_valid_ram_dist_mem_gen_v8_0_13 is
  port (
    a : in STD_LOGIC_VECTOR ( 8 downto 0 );
    d : in STD_LOGIC_VECTOR ( 0 to 0 );
    dpra : in STD_LOGIC_VECTOR ( 8 downto 0 );
    clk : in STD_LOGIC;
    we : in STD_LOGIC;
    i_ce : in STD_LOGIC;
    qspo_ce : in STD_LOGIC;
    qdpo_ce : in STD_LOGIC;
    qdpo_clk : in STD_LOGIC;
    qspo_rst : in STD_LOGIC;
    qdpo_rst : in STD_LOGIC;
    qspo_srst : in STD_LOGIC;
    qdpo_srst : in STD_LOGIC;
    spo : out STD_LOGIC_VECTOR ( 0 to 0 );
    dpo : out STD_LOGIC_VECTOR ( 0 to 0 );
    qspo : out STD_LOGIC_VECTOR ( 0 to 0 );
    qdpo : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute C_ADDR_WIDTH : integer;
  attribute C_ADDR_WIDTH of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 9;
  attribute C_DEFAULT_DATA : string;
  attribute C_DEFAULT_DATA of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is "0";
  attribute C_DEPTH : integer;
  attribute C_DEPTH of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 512;
  attribute C_ELABORATION_DIR : string;
  attribute C_ELABORATION_DIR of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is "./";
  attribute C_FAMILY : string;
  attribute C_FAMILY of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is "artix7";
  attribute C_HAS_CLK : integer;
  attribute C_HAS_CLK of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_HAS_D : integer;
  attribute C_HAS_D of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_HAS_DPO : integer;
  attribute C_HAS_DPO of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_HAS_DPRA : integer;
  attribute C_HAS_DPRA of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_HAS_I_CE : integer;
  attribute C_HAS_I_CE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QDPO : integer;
  attribute C_HAS_QDPO of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QDPO_CE : integer;
  attribute C_HAS_QDPO_CE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QDPO_CLK : integer;
  attribute C_HAS_QDPO_CLK of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QDPO_RST : integer;
  attribute C_HAS_QDPO_RST of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QDPO_SRST : integer;
  attribute C_HAS_QDPO_SRST of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QSPO : integer;
  attribute C_HAS_QSPO of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QSPO_CE : integer;
  attribute C_HAS_QSPO_CE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QSPO_RST : integer;
  attribute C_HAS_QSPO_RST of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_QSPO_SRST : integer;
  attribute C_HAS_QSPO_SRST of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_SPO : integer;
  attribute C_HAS_SPO of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_HAS_WE : integer;
  attribute C_HAS_WE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_MEM_INIT_FILE : string;
  attribute C_MEM_INIT_FILE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is "no_coe_file_loaded";
  attribute C_MEM_TYPE : integer;
  attribute C_MEM_TYPE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 4;
  attribute C_PARSER_TYPE : integer;
  attribute C_PARSER_TYPE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_PIPELINE_STAGES : integer;
  attribute C_PIPELINE_STAGES of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_QCE_JOINED : integer;
  attribute C_QCE_JOINED of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_QUALIFY_WE : integer;
  attribute C_QUALIFY_WE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_READ_MIF : integer;
  attribute C_READ_MIF of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_REG_A_D_INPUTS : integer;
  attribute C_REG_A_D_INPUTS of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_REG_DPRA_INPUT : integer;
  attribute C_REG_DPRA_INPUT of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 0;
  attribute C_SYNC_ENABLE : integer;
  attribute C_SYNC_ENABLE of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
  attribute C_WIDTH : integer;
  attribute C_WIDTH of bypass_valid_ram_dist_mem_gen_v8_0_13 : entity is 1;
end bypass_valid_ram_dist_mem_gen_v8_0_13;

architecture STRUCTURE of bypass_valid_ram_dist_mem_gen_v8_0_13 is
  signal \<const0>\ : STD_LOGIC;
begin
  qdpo(0) <= \<const0>\;
  qspo(0) <= \<const0>\;
  spo(0) <= \<const0>\;
GND: unisim.vcomponents.GND
     port map (
      G => \<const0>\
    );
\synth_options.dist_mem_inst\: entity work.bypass_valid_ram_dist_mem_gen_v8_0_13_synth
     port map (
      a(8 downto 0) => a(8 downto 0),
      clk => clk,
      d(0) => d(0),
      dpo(0) => dpo(0),
      dpra(8 downto 0) => dpra(8 downto 0),
      we => we
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bypass_valid_ram is
  port (
    a : in STD_LOGIC_VECTOR ( 8 downto 0 );
    d : in STD_LOGIC_VECTOR ( 0 to 0 );
    dpra : in STD_LOGIC_VECTOR ( 8 downto 0 );
    clk : in STD_LOGIC;
    we : in STD_LOGIC;
    dpo : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of bypass_valid_ram : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of bypass_valid_ram : entity is "bypass_valid_ram,dist_mem_gen_v8_0_13,{}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of bypass_valid_ram : entity is "yes";
  attribute x_core_info : string;
  attribute x_core_info of bypass_valid_ram : entity is "dist_mem_gen_v8_0_13,Vivado 2019.2";
end bypass_valid_ram;

architecture STRUCTURE of bypass_valid_ram is
  signal NLW_U0_qdpo_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_U0_qspo_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_U0_spo_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  attribute C_FAMILY : string;
  attribute C_FAMILY of U0 : label is "artix7";
  attribute C_HAS_CLK : integer;
  attribute C_HAS_CLK of U0 : label is 1;
  attribute C_HAS_D : integer;
  attribute C_HAS_D of U0 : label is 1;
  attribute C_HAS_DPO : integer;
  attribute C_HAS_DPO of U0 : label is 1;
  attribute C_HAS_DPRA : integer;
  attribute C_HAS_DPRA of U0 : label is 1;
  attribute C_HAS_QDPO : integer;
  attribute C_HAS_QDPO of U0 : label is 0;
  attribute C_HAS_QDPO_CE : integer;
  attribute C_HAS_QDPO_CE of U0 : label is 0;
  attribute C_HAS_QDPO_CLK : integer;
  attribute C_HAS_QDPO_CLK of U0 : label is 0;
  attribute C_HAS_QDPO_RST : integer;
  attribute C_HAS_QDPO_RST of U0 : label is 0;
  attribute C_HAS_QDPO_SRST : integer;
  attribute C_HAS_QDPO_SRST of U0 : label is 0;
  attribute C_HAS_QSPO : integer;
  attribute C_HAS_QSPO of U0 : label is 0;
  attribute C_HAS_QSPO_RST : integer;
  attribute C_HAS_QSPO_RST of U0 : label is 0;
  attribute C_HAS_QSPO_SRST : integer;
  attribute C_HAS_QSPO_SRST of U0 : label is 0;
  attribute C_HAS_SPO : integer;
  attribute C_HAS_SPO of U0 : label is 0;
  attribute C_HAS_WE : integer;
  attribute C_HAS_WE of U0 : label is 1;
  attribute C_MEM_TYPE : integer;
  attribute C_MEM_TYPE of U0 : label is 4;
  attribute C_REG_DPRA_INPUT : integer;
  attribute C_REG_DPRA_INPUT of U0 : label is 0;
  attribute c_addr_width : integer;
  attribute c_addr_width of U0 : label is 9;
  attribute c_default_data : string;
  attribute c_default_data of U0 : label is "0";
  attribute c_depth : integer;
  attribute c_depth of U0 : label is 512;
  attribute c_elaboration_dir : string;
  attribute c_elaboration_dir of U0 : label is "./";
  attribute c_has_i_ce : integer;
  attribute c_has_i_ce of U0 : label is 0;
  attribute c_has_qspo_ce : integer;
  attribute c_has_qspo_ce of U0 : label is 0;
  attribute c_mem_init_file : string;
  attribute c_mem_init_file of U0 : label is "no_coe_file_loaded";
  attribute c_parser_type : integer;
  attribute c_parser_type of U0 : label is 1;
  attribute c_pipeline_stages : integer;
  attribute c_pipeline_stages of U0 : label is 0;
  attribute c_qce_joined : integer;
  attribute c_qce_joined of U0 : label is 0;
  attribute c_qualify_we : integer;
  attribute c_qualify_we of U0 : label is 0;
  attribute c_read_mif : integer;
  attribute c_read_mif of U0 : label is 0;
  attribute c_reg_a_d_inputs : integer;
  attribute c_reg_a_d_inputs of U0 : label is 0;
  attribute c_sync_enable : integer;
  attribute c_sync_enable of U0 : label is 1;
  attribute c_width : integer;
  attribute c_width of U0 : label is 1;
begin
U0: entity work.bypass_valid_ram_dist_mem_gen_v8_0_13
     port map (
      a(8 downto 0) => a(8 downto 0),
      clk => clk,
      d(0) => d(0),
      dpo(0) => dpo(0),
      dpra(8 downto 0) => dpra(8 downto 0),
      i_ce => '1',
      qdpo(0) => NLW_U0_qdpo_UNCONNECTED(0),
      qdpo_ce => '1',
      qdpo_clk => '0',
      qdpo_rst => '0',
      qdpo_srst => '0',
      qspo(0) => NLW_U0_qspo_UNCONNECTED(0),
      qspo_ce => '1',
      qspo_rst => '0',
      qspo_srst => '0',
      spo(0) => NLW_U0_spo_UNCONNECTED(0),
      we => we
    );
end STRUCTURE;
