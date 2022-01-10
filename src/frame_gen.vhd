-------------------------------------------------------------------------------
-- Title      : Frame Gen
-- Project    : MEEP
-------------------------------------------------------------------------------
-- File        : frame_gen.vhd
-- Author      : Francelly K. Cano Ladino; francelly.canoladino@bsc.es
-- Company     : Barcelona Supercomputing Center (BSC)
-- Created     : 19/01/2021 - 19:12:35
-- Last update : Tue Jan 19 17:36:02 2021
-- Synthesizer : <Name> <version>
-- FPGA        : Alveo U280
-------------------------------------------------------------------------------
-- Description: This module will implement a Frame generator to test a loopback using 
--              Aurora 64B/66B full-duplex connection.
-- Signals:
--   USER_CLK: The user_clk INPUT signal is a BUFG output deriving its input from tx_out_clk (Transceivers).   
--   RESET: This INPUT  signal reset the frame generator module.
-- /User Interface: TX interface
--   AXIS_UI_TX_TDATA:This output signal is used to provide the random data generated that is passing across the interface.
--   AXIS_UI_TX_TVALID:This output  signal indicates that this modules is driving a valid transfer.
--   AXIS_UI_TX_TREADY: The core indicates is ready for the transaction.
--- Comments    : <Extra comments if they were needed>
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

entity frame_gen is
  generic (
    DATA_WIDTH : integer := 256;
    STRB_WIDTH : integer := 32           -- STROBE bus width
    );
  port (

    -------------------------------------------------------------------------------
    -- System Interface
    -------------------------------------------------------------------------------     

    USER_CLK : in std_logic;            -- Aurora User Clk
    RESET    : in std_logic;

    DATA_INJ: in std_logic;
    -------------------------------------------------------------------------------
    -- USER INTERFACE : TX INTERFACE
    -------------------------------------------------------------------------------

    AXIS_UI_TX_TDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    AXIS_UI_TX_TVALID : out std_logic;  --Handshake signal  
    AXIS_UI_TX_TREADY : in  std_logic


    );

end entity frame_gen;

architecture rtl of frame_gen is

-----------------------------------------------------------------------------
  -- CONSTANTS
-----------------------------------------------------------------------------
  constant AURORA_LANES    : integer := 4;
  constant LANE_DATA_WIDTH : integer := (AURORA_LANES*64);


-----------------------------------------------------------------------------
-- SIGNALS
-----------------------------------------------------------------------------
  signal ui_lfsr_r           : std_logic_vector (0 to 15)             := (others=>'0');
  signal ui_lfsr_r1          : std_logic_vector (0 to 15)             := (others=>'0');
  signal ui_lfsr_r2          : std_logic_vector (0 to 15)             := (others=>'0');
  signal AXIS_UI_TX_TDATA_i  : std_logic_vector (0 to (DATA_WIDTH-1)) := (others=>'0');
  signal r_axis_ui_tx_tvalid : std_logic                              := '0';

  signal data_i              : std_logic                              :='1';
  
begin
    data_i<=DATA_INJ;

-- Generate random data using XNOR feedback LFSR 
  process(USER_CLK)
  begin
    if rising_edge(USER_CLK) then
      if RESET = '1' then
        r_axis_ui_tx_tvalid <= '0';
      else
        r_axis_ui_tx_tvalid <= '1';
      end if;
    end if;
  end process;

  process(USER_CLK)
  begin    
    if rising_edge(USER_CLK) then  
      if  RESET = '1' then
         ui_lfsr_r1 <= X"ABCD";             --initial seed to start
      elsif (AXIS_UI_TX_TREADY = '1' and r_axis_ui_tx_tvalid = '1') then
        ui_lfsr_r1 <= (not((ui_lfsr_r1(3))xor(ui_lfsr_r1(12))xor(ui_lfsr_r1(14))xor(ui_lfsr_r1(15)))&(ui_lfsr_r1(0 to 14)));
      end if;
    end if;
 
  end process;
  
 process(USER_CLK)
  begin    
    if rising_edge(USER_CLK) then  
      if  RESET = '1' then
         ui_lfsr_r2 <= X"1234";             --initial seed to start
      elsif (AXIS_UI_TX_TREADY = '1' and r_axis_ui_tx_tvalid = '1') then
        ui_lfsr_r2 <= (not((ui_lfsr_r2(3))xor(ui_lfsr_r2(12))xor(ui_lfsr_r2(14))xor(ui_lfsr_r2(15)))&(ui_lfsr_r2(0 to 14)));
      end if;
    end if;
 
  end process;
  
  ui_lfsr_r<=ui_lfsr_r1 when data_i='1' else
             ui_lfsr_r2;   

-- Connect TX_D to the ui_lfsr_r register


  AXIS_UI_TX_TDATA_i <= ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&
                        ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&
                        ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&
                        ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15)&ui_lfsr_r(0 to 15);

  gen_tdata : for a in 0 to STRB_WIDTH-1 generate
    AXIS_UI_TX_TDATA(((STRB_WIDTH-1-a)*8)+7 downto ((STRB_WIDTH-1-a)*8)) <= AXIS_UI_TX_TDATA_i(((STRB_WIDTH-1-a)*8) to ((STRB_WIDTH-1-a)*8)+7);
  end generate gen_tdata;

  AXIS_UI_TX_TVALID <= r_axis_ui_tx_tvalid;

end architecture rtl;
      
