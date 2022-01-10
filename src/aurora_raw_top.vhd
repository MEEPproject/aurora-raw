-------------------------------------------------------------------------------
-- Title      : User Interface
-- Project    : MEEP
-------------------------------------------------------------------------------
-- File        : user_interface_top.vhd
-- Author      : Francelly K. Cano Ladino; francelly.canoladino@bsc.es
-- Company     : Barcelona Supercomputing Center (BSC)
-- Created     : 19/01/2021 - 19:12:35
-- Last update : Mon Feb 15 15:03:07 2021
-- Synthesizer : <Name> <version>
-- FPGA        : Alveo U280
-------------------------------------------------------------------------------
-- Description: User interface /Aurora64B/66B. First shot
--
-- Comments    : <Extra comments if they were needed>
-------------------------------------------------------------------------------
-- Copyright (c) 2019 DDR/TICH
-------------------------------------------------------------------------------
-- Revisions  : 1.0
-- Date/Time                Version               Engineer
-- dd/mm/yyyy - hh:mm        1.0             francelly.canoladino@bsc.es
-- Comments   : <Highlight the modifications>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.STD_LOGIC_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity aurora_raw_top is
  generic (
    DATA_WIDTH  : integer := 256;
    STRB_WIDTH  : integer := 32);
  port (
    ----------------------------------------------------------------------------
    -- System Interfaces
    ----------------------------------------------------------------------------     
    --user inpout
    ----------------------------------------------------------------------------
    S_USER_AXIS_UI_TX_TDATA  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    S_USER_AXIS_UI_TX_TVALID : in std_logic;
    S_USER_AXIS_UI_TX_TREADY : out std_logic;
    --user output   
    ----------------------------------------------------------------------------
    M_USER_AXIS_UI_RX_TDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    M_USER_AXIS_UI_RX_TVALID : out std_logic;
    --aurora interfaces
    ----------------------------------------------------------------------------
    CHANNEL_UP_OUT         : out std_logic;
    LANE_UP_OUT            : out std_logic_vector(0 to 3);
    ----------------------------------------------------------------------------
    -- Simulation Interfaces
    ---------------------------------------------------------------------------- 
    DATA_INJ              : in std_logic;
    SIMULATE_FRAME_GEN    : in std_logic;
    SIMULATE_FRAME_CHECK  : in std_logic;
    DATA_ERR_COUNT        : out std_logic_vector(7 downto 0);
    ----------------------------------------------------------------------------
    -- GT SERIAL RX
    ----------------------------------------------------------------------------
    RXN : in std_logic_vector(0 to 3);
    RXP : in std_logic_vector(0 to 3);
    ----------------------------------------------------------------------------
    -- GT SERIAL TX
    ----------------------------------------------------------------------------
    TXN : out std_logic_vector(0 to 3);
    TXP : out std_logic_vector(0 to 3);
    ---------------------------------------------------------------------------- 
    -- GT DIFF REFCLK
    ----------------------------------------------------------------------------
    GT_REFCLK1_N : in  std_logic;
    GT_REFCLK1_P : in  std_logic;
    --
    QSFP0_FS     : out  std_logic;
    QSFP0_OEB    : out std_logic;
    ----------------------------------------------------------------------------
    -- Clocks and Resets
    ----------------------------------------------------------------------------
    INIT_CLK  : in std_logic;
    RESET     : in std_logic;
    USER_CLK_OUT           : out std_logic;
    SYS_RESET_OUT          : out std_logic
    );

end entity aurora_raw_top;

architecture rtl of aurora_raw_top is
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- User interface: 
------------------------------------------------------------------------------
  -- From frame_gen
  signal frame_gen_axis_ui_tx_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal frame_gen_axis_ui_tx_tvalid : std_logic;

  -- To Aurora 
  signal aurora_axis_ui_tx_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal aurora_axis_ui_tx_tvalid : std_logic;
  signal aurora_axis_ui_tx_tready : std_logic;
   
  -- From frame_gcheck
  signal s_data_error_count  : std_logic_vector(7 downto 0);
  
  -- To Aurora    
  signal aurora_axis_ui_rx_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal aurora_axis_ui_rx_tvalid : std_logic;
   
  signal reset_fg          : std_logic;
  signal reset_fc          : std_logic;
  signal reset_pb          : std_logic; 
  
  signal hab_fg          : std_logic;
  signal hab_fc          : std_logic;
  
  signal pma_init          : std_logic;
---------------------------------------------------------------------------------
  -- Aurora core: 
  -------------------------------------------------------------------------------
  signal user_clk_out_s              : std_logic;
  signal power_down                  : std_logic;
  signal lane_up_out_s               : std_logic_vector(0 to 3);
  signal loopback                    : std_logic_vector(2 downto 0);
  signal hard_err                    : std_logic;
  signal soft_err                    : std_logic;
  signal channel_up_out_s            : std_logic;
  signal tx_out_clk                  : std_logic;
  signal gt_pll_lock                 : std_logic;
  signal mmcm_not_locked_out         : std_logic;
  signal gt0_drpaddr                 : std_logic_vector(9 downto 0);
  signal gt1_drpaddr                 : std_logic_vector(9 downto 0);
  signal gt2_drpaddr                 : std_logic_vector(9 downto 0);
  signal gt3_drpaddr                 : std_logic_vector(9 downto 0);
  signal gt0_drpdi                   : std_logic_vector(15 downto 0);
  signal gt1_drpdi                   : std_logic_vector(15 downto 0);
  signal gt2_drpdi                   : std_logic_vector(15 downto 0);
  signal gt3_drpdi                   : std_logic_vector(15 downto 0);
  signal gt0_drprdy                  : std_logic;
  signal gt1_drprdy                  : std_logic;
  signal gt2_drprdy                  : std_logic;
  signal gt3_drprdy                  : std_logic;
  signal gt0_drpwe                   : std_logic;
  signal gt1_drpwe                   : std_logic;
  signal gt2_drpwe                   : std_logic;
  signal gt3_drpwe                   : std_logic;
  signal gt0_drpen                   : std_logic;
  signal gt1_drpen                   : std_logic;
  signal gt2_drpen                   : std_logic;
  signal gt3_drpen                   : std_logic;
  signal gt0_drpdo                   : std_logic_vector(15 downto 0);
  signal gt1_drpdo                   : std_logic_vector(15 downto 0);
  signal gt2_drpdo                   : std_logic_vector(15 downto 0);
  signal gt3_drpdo                   : std_logic_vector(15 downto 0);
  signal link_reset_out              : std_logic;
  signal sync_clk_out                : std_logic;
  signal gt_qpllclk_quad1_out        : std_logic;
  signal gt_qpllrefclk_quad1_out     : std_logic;
  signal gt_qpllrefclklost_quad1_out : std_logic;
  signal gt_qplllock_quad1_out       : std_logic;
  signal gt_rxcdrovrden_in           : std_logic;
  signal sys_reset_out_s             : std_logic;
  signal gt_reset_out                : std_logic;
  signal gt_refclk1_out              : std_logic;
  signal gt_powergood                : std_logic_vector(3 downto 0);
 ------------------------------------------------------------------------------

  component aurora_64b66b_0
    port (
      rxp                         : in  std_logic_vector(0 to 3);
      rxn                         : in  std_logic_vector(0 to 3);
      reset_pb                    : in  std_logic;
      power_down                  : in  std_logic;
      pma_init                    : in  std_logic;
      loopback                    : in  std_logic_vector(2 downto 0);
      txp                         : out std_logic_vector(0 to 3);
      txn                         : out std_logic_vector(0 to 3);
      hard_err                    : out std_logic;
      soft_err                    : out std_logic;
      channel_up                  : out std_logic;
      lane_up                     : out std_logic_vector(0 to 3);
      tx_out_clk                  : out std_logic;
      gt_pll_lock                 : out std_logic;
      s_axi_tx_tdata              : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      s_axi_tx_tvalid             : in  std_logic;
      s_axi_tx_tready             : out std_logic;
      m_axi_rx_tdata              : out std_logic_vector(DATA_WIDTH-1 downto 0);
      m_axi_rx_tvalid             : out std_logic;
      mmcm_not_locked_out         : out std_logic;
      gt0_drpaddr                 : in  std_logic_vector(9 downto 0);
      gt1_drpaddr                 : in  std_logic_vector(9 downto 0);
      gt2_drpaddr                 : in  std_logic_vector(9 downto 0);
      gt3_drpaddr                 : in  std_logic_vector(9 downto 0);
      gt0_drpdi                   : in  std_logic_vector(15 downto 0);
      gt1_drpdi                   : in  std_logic_vector(15 downto 0);
      gt2_drpdi                   : in  std_logic_vector(15 downto 0);
      gt3_drpdi                   : in  std_logic_vector(15 downto 0);
      gt0_drprdy                  : out std_logic;
      gt1_drprdy                  : out std_logic;
      gt2_drprdy                  : out std_logic;
      gt3_drprdy                  : out std_logic;
      gt0_drpwe                   : in  std_logic;
      gt1_drpwe                   : in  std_logic;
      gt2_drpwe                   : in  std_logic;
      gt3_drpwe                   : in  std_logic;
      gt0_drpen                   : in  std_logic;
      gt1_drpen                   : in  std_logic;
      gt2_drpen                   : in  std_logic;
      gt3_drpen                   : in  std_logic;
      gt0_drpdo                   : out std_logic_vector(15 downto 0);
      gt1_drpdo                   : out std_logic_vector(15 downto 0);
      gt2_drpdo                   : out std_logic_vector(15 downto 0);
      gt3_drpdo                   : out std_logic_vector(15 downto 0);
      init_clk                    : in  std_logic;
      link_reset_out              : out std_logic;
      gt_refclk1_p                : in  std_logic;
      gt_refclk1_n                : in  std_logic;
      user_clk_out                : out std_logic;
      sync_clk_out                : out std_logic;
      gt_qpllclk_quad1_out        : out std_logic;
      gt_qpllrefclk_quad1_out     : out std_logic;
      gt_qpllrefclklost_quad1_out : out std_logic;
      gt_qplllock_quad1_out       : out std_logic;
      gt_rxcdrovrden_in           : in  std_logic;
      sys_reset_out               : out std_logic;
      gt_reset_out                : out std_logic;
      gt_refclk1_out              : out std_logic;
      gt_powergood                : out std_logic_vector(3 downto 0)
      );
  end component;
-------------------------------------------------------------------------------
begin

    QSFP0_FS  <= '1';
    QSFP0_OEB <= '0';

-------------------------------------------------------------------------------
-- Frame_Gen instantiation
-------------------------------------------------------------------------------
  hab_fg <= reset_fg or not(SIMULATE_FRAME_GEN);
  
  framegen_0 : entity work.frame_gen
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      STRB_WIDTH => STRB_WIDTH)
    port map (
      USER_CLK          => user_clk_out_s,
      RESET             => hab_fg,
      DATA_INJ          => DATA_INJ,
      AXIS_UI_TX_TDATA  => frame_gen_axis_ui_tx_tdata,
      AXIS_UI_TX_TVALID => frame_gen_axis_ui_tx_tvalid,
      AXIS_UI_TX_TREADY => aurora_axis_ui_tx_tready);

-------------------------------------------------------------------------------
 --Frame Checker instantiation
 -------------------------------------------------------------------------------  
 hab_fc <= reset_fc or not(SIMULATE_FRAME_CHECK);
   
  framecheck_0 : entity work.frame_check
  generic map (
      DATA_WIDTH => DATA_WIDTH,
      STRB_WIDTH => STRB_WIDTH)
    port map (
      USER_CLK          => user_clk_out_s,
      RESET             => hab_fc,
      AXIS_UI_RX_TDATA  => aurora_axis_ui_rx_tdata,
      AXIS_UI_RX_TVALID => aurora_axis_ui_rx_tvalid,
      DATA_ERR_COUNT    => s_data_error_count);

-------------------------------------------------------------------------------
-- Reset block instantiation
-------------------------------------------------------------------------------
  reset_0 : entity work.reset_block
    port map (
      INIT_CLK   => INIT_CLK,
      RESET      => RESET,
      CHANNEL_UP => channel_up_out_s,
      SYS_RESET  => sys_reset_out_s,
      PMA_INIT   => pma_init,
      RESET_PB   => reset_pb,
      RESET_FG   => reset_fg,
      RESET_FC   => reset_fc);

-------------------------------------------------------------------------------
-- Aurora Core instantiation
-------------------------------------------------------------------------------
 -- Comes from Simulation selectors
 -- MUX using if-then-else
 
 MUX_frame_gen : process (SIMULATE_FRAME_GEN, S_USER_AXIS_UI_TX_TDATA, S_USER_AXIS_UI_TX_TVALID, frame_gen_axis_ui_tx_tdata, frame_gen_axis_ui_tx_tvalid) is
 begin
     if SIMULATE_FRAME_GEN = '0' then
        aurora_axis_ui_tx_tdata  <= S_USER_AXIS_UI_TX_TDATA;
        aurora_axis_ui_tx_tvalid <= S_USER_AXIS_UI_TX_TVALID;  
     elsif SIMULATE_FRAME_GEN = '1' then
        aurora_axis_ui_tx_tdata  <= frame_gen_axis_ui_tx_tdata;
        aurora_axis_ui_tx_tvalid <= frame_gen_axis_ui_tx_tvalid;  
     else 
        aurora_axis_ui_tx_tdata  <= (others => 'X');
        aurora_axis_ui_tx_tvalid <= 'X';  
     end if;
 end process  MUX_frame_gen;
 
 S_USER_AXIS_UI_TX_TREADY  <= aurora_axis_ui_tx_tready;
 
  MUX_frame_check : process (SIMULATE_FRAME_CHECK, s_data_error_count) is
 begin
     if SIMULATE_FRAME_CHECK = '1' then
        DATA_ERR_COUNT    <= s_data_error_count;
     else 
        DATA_ERR_COUNT  <= (others => 'X');
     end if;
 end process  MUX_frame_check;

 M_USER_AXIS_UI_RX_TDATA  <= aurora_axis_ui_rx_tdata;
 m_USER_AXIS_UI_RX_TVALID <= aurora_axis_ui_rx_tvalid; 

--Auxiliary signals  assign to 'GND' if they are not unused
  power_down        <= '0';
  gt_rxcdrovrden_in <= '0';
  loopback          <= (others => '0');
  gt0_drpaddr       <= (others => '0');
  gt1_drpaddr       <= (others => '0');
  gt2_drpaddr       <= (others => '0');
  gt3_drpaddr       <= (others => '0');
  gt0_drpdi         <= (others => '0');
  gt1_drpdi         <= (others => '0');
  gt2_drpdi         <= (others => '0');
  gt3_drpdi         <= (others => '0');
  gt0_drpen         <= '0';
  gt1_drpen         <= '0';
  gt2_drpen         <= '0';
  gt3_drpen         <= '0';
  gt0_drpwe         <= '0';
  gt1_drpwe         <= '0';
  gt2_drpwe         <= '0';
  gt3_drpwe         <= '0';
  --------------------------------------------------------------------------
  CHANNEL_UP_OUT    <= channel_up_out_s;
  LANE_UP_OUT       <= lane_up_out_s;
  USER_CLK_OUT      <= user_clk_out_s;
  SYS_RESET_OUT      <= sys_reset_out_s;
    
  aurora_0 : aurora_64b66b_0
    port map (
      rxp                         => RXP,
      rxn                         => RXN,
      reset_pb                    => reset_pb,
      power_down                  => power_down,
      pma_init                    => pma_init,
      loopback                    => loopback,
      txp                         => TXP,
      txn                         => TXN,
      hard_err                    => hard_err,
      soft_err                    => soft_err,
      channel_up                  => channel_up_out_s,
      lane_up                     => lane_up_out_s,
      tx_out_clk                  => tx_out_clk,
      gt_pll_lock                 => gt_pll_lock,
      s_axi_tx_tdata              => aurora_axis_ui_tx_tdata,
      s_axi_tx_tvalid             => aurora_axis_ui_tx_tvalid,
      s_axi_tx_tready             => aurora_axis_ui_tx_tready,
      m_axi_rx_tdata              => aurora_axis_ui_rx_tdata,
      m_axi_rx_tvalid             => aurora_axis_ui_rx_tvalid,
      mmcm_not_locked_out         => mmcm_not_locked_out,
      gt0_drpaddr                 => gt0_drpaddr,
      gt1_drpaddr                 => gt1_drpaddr,
      gt2_drpaddr                 => gt2_drpaddr,
      gt3_drpaddr                 => gt3_drpaddr,
      gt0_drpdi                   => gt0_drpdi,
      gt1_drpdi                   => gt1_drpdi,
      gt2_drpdi                   => gt2_drpdi,
      gt3_drpdi                   => gt3_drpdi,
      gt0_drprdy                  => gt0_drprdy,
      gt1_drprdy                  => gt1_drprdy,
      gt2_drprdy                  => gt2_drprdy,
      gt3_drprdy                  => gt3_drprdy,
      gt0_drpwe                   => gt0_drpwe,
      gt1_drpwe                   => gt1_drpwe,
      gt2_drpwe                   => gt2_drpwe,
      gt3_drpwe                   => gt3_drpwe,
      gt0_drpen                   => gt0_drpen,
      gt1_drpen                   => gt1_drpen,
      gt2_drpen                   => gt2_drpen,
      gt3_drpen                   => gt3_drpen,
      gt0_drpdo                   => gt0_drpdo,
      gt1_drpdo                   => gt1_drpdo,
      gt2_drpdo                   => gt2_drpdo,
      gt3_drpdo                   => gt3_drpdo,
      init_clk                    => INIT_CLK,
      link_reset_out              => link_reset_out,
      gt_refclk1_p                => GT_REFCLK1_P,
      gt_refclk1_n                => GT_REFCLK1_N,
      user_clk_out                => user_clk_out_s,
      sync_clk_out                => sync_clk_out,
      gt_qpllclk_quad1_out        => gt_qpllclk_quad1_out,
      gt_qpllrefclk_quad1_out     => gt_qpllrefclk_quad1_out,
      gt_qpllrefclklost_quad1_out => gt_qpllrefclklost_quad1_out,
      gt_qplllock_quad1_out       => gt_qplllock_quad1_out,
      gt_rxcdrovrden_in           => gt_rxcdrovrden_in,
      sys_reset_out               => sys_reset_out_s,
      gt_reset_out                => gt_reset_out,
      gt_refclk1_out              => gt_refclk1_out,
      gt_powergood                => gt_powergood
      );

end architecture rtl;
