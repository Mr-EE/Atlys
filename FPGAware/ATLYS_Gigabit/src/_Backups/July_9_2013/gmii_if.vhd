--------------------------------------------------------------------------------
-- File       : gmii_if.vhd
-- Author     : Xilinx Inc.
-- ------------------------------------------------------------------------------
-- (c) Copyright 2004-2009 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES. 
-- ------------------------------------------------------------------------------
-- Description:  This module creates a Gigabit Media Independent
--               Interface (GMII) by instantiating Input/Output buffers
--               and Input/Output flip-flops as required.
--
--               This interface is used to connect the Ethernet MAC to
--               an external Ethernet PHY via GMII connection.
--
--               The GMII receiver clocking logic is also defined here: the
--               receiver clock received from the PHY is unique and cannot be
--               shared across multiple instantiations of the core.  For the
--               receiver clock:
--
--               A BUFIO/BUFG combination is used for the input clock to allow
--               the use of IODELAYs on the DATA.
--------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- The entity declaration for the PHY IF design.
--------------------------------------------------------------------------------
entity gmii_if is
    port(
        -- Synchronous resets
        tx_reset                      : in  std_logic;
        rx_reset                      : in  std_logic;

        -- The following ports are the GMII physical interface: these will be at
        -- pins on the FPGA
        gmii_txd                      : out std_logic_vector(7 downto 0);
        gmii_tx_en                    : out std_logic;
        gmii_tx_er                    : out std_logic;
        gmii_tx_clk                   : out std_logic;
        gmii_rxd                      : in  std_logic_vector(7 downto 0);
        gmii_rx_dv                    : in  std_logic;
        gmii_rx_er                    : in  std_logic;
        gmii_rx_clk                   : in  std_logic;

        -- The following ports are the internal GMII connections from IOB logic
        -- to the TEMAC core
        txd_from_mac                  : in  std_logic_vector(7 downto 0);
        tx_en_from_mac                : in  std_logic;
        tx_er_from_mac                : in  std_logic;
        tx_clk                        : in  std_logic;
        rxd_to_mac                    : out std_logic_vector(7 downto 0);
        rx_dv_to_mac                  : out std_logic;
        rx_er_to_mac                  : out std_logic;

        -- Receiver clock for the MAC and Client Logic
        rx_clk                        : out  std_logic
        );
end gmii_if;


architecture rtl of gmii_if is


  ------------------------------------------------------------------------------
  -- internal signals
  ------------------------------------------------------------------------------
  signal not_tx_clk           : std_logic;

  signal gmii_rx_dv_delay     : std_logic;
  signal gmii_rx_er_delay     : std_logic;
  signal gmii_rxd_delay       : std_logic_vector(7 downto 0);
  signal gmii_rx_clk_bufio    : std_logic;
  signal gmii_rx_clk_tobufg   : std_logic;

  signal rx_clk_int           : std_logic;




begin


  ------------------------------------------------------------------------------
  -- GMII Transmitter Clock Management :
  -- drive gmii_tx_clk through IOB onto GMII interface
  ------------------------------------------------------------------------------

   -- tx_clk is inverted.  This inversion will take place
   -- locally in IOBs.
   invert_tx_clk : INV
   port map(
      I           => tx_clk,
      O           => not_tx_clk
   );


   -- Instantiate a DDR output register.  This is a good way to drive
   -- GMII_TX_CLK since the clock-to-PAD delay will be the same as that
   -- for data driven from IOB Ouput flip-flops eg gmii_rxd[7:0].  This is set
   -- to produce an inverted clock w.r.t. tx_clk so that
   -- the rising edge is centralised within the
   -- gmii_rxd[7:0] valid window.
   gmii_tx_clk_ddr_iob : ODDR2
   port map (
      Q           => gmii_tx_clk, 
      C0          => tx_clk, 
      C1          => not_tx_clk, 
      CE          => '1', 
      D0          => '0', 
      D1          => '1', 
      R           => '0', 
      S           => '0'
   );
   -----------------------------------------------------------------------------
   -- GMII Transmitter Logic :
   -- drive TX signals through IOBs onto GMII interface
   -----------------------------------------------------------------------------

   -- Infer IOB Output flip-flops.
   reg_gmii_tx_out : process (tx_clk)
   begin
      if tx_clk'event and tx_clk = '1' then
         gmii_tx_en        <= tx_en_from_mac;
         gmii_tx_er        <= tx_er_from_mac;
         gmii_txd          <= txd_from_mac;
      end if;
   end process reg_gmii_tx_out;


  ------------------------------------------------------------------------------
  -- GMII Receiver Clock Logic
  ------------------------------------------------------------------------------

   -- Route gmii_rx_clk through a BUFIO2/BUFG and onto global clock routing
   bufio_gmii_rx_clk : BUFIO2
   port map  (
      DIVCLK         => gmii_rx_clk_tobufg,
      I              => gmii_rx_clk,
      IOCLK          => gmii_rx_clk_bufio,
      SERDESSTROBE   => open
   );                  

   -- Route rx_clk through a BUFG onto global clock routing
   bufg_gmii_rx_clk : BUFG
   port map  (
      I              => gmii_rx_clk_tobufg,
      O              => rx_clk_int
   );


   -- Assign the internal clock signal to the output port
   rx_clk <= rx_clk_int;


   -----------------------------------------------------------------------------
   -- GMII Receiver Logic : receive RX signals through IOBs from GMII interface
   -----------------------------------------------------------------------------

   --  Drive input GMII Rx signals from PADS through IODELAYS.

   -- Note: Delay value is set in UCF file
   -- Please modify the IOBDELAY_VALUE according to your design.
   -- For more information on IDELAYCTRL and IDELAY, please refer to
   -- the User Guide.
   delay_gmii_rx_dv : IODELAY2
   generic map (
      IDELAY_TYPE    => "FIXED",
      DELAY_SRC      => "IDATAIN"
   )
   port map (
      BUSY           => open,
      DATAOUT        => gmii_rx_dv_delay,
      DATAOUT2       => open,
      DOUT           => open,
      TOUT           => open,
      CAL            => '0',
      CE             => '0',
      CLK            => '0',
      IDATAIN        => gmii_rx_dv,
      INC            => '0',
      IOCLK0         => '0',
      IOCLK1         => '0',
      ODATAIN        => '0',
      RST            => '0',
      T              => '1'
   );


   delay_gmii_rx_er : IODELAY2
   generic map (
      IDELAY_TYPE    => "FIXED",
      DELAY_SRC      => "IDATAIN"
   )
   port map (
      BUSY           => open,
      DATAOUT        => gmii_rx_er_delay,
      DATAOUT2       => open,
      DOUT           => open,
      TOUT           => open,
      CAL            => '0',
      CE             => '0',
      CLK            => '0',
      IDATAIN        => gmii_rx_er,
      INC            => '0',
      IOCLK0         => '0',
      IOCLK1         => '0',
      ODATAIN        => '0',
      RST            => '0',
      T              => '1'
   );

   rxdata_bus: for I in 7 downto 0 generate
   delay_gmii_rxd : IODELAY2
   generic map (
      IDELAY_TYPE    => "FIXED",
      DELAY_SRC      => "IDATAIN"
   )
   port map (
      BUSY           => open,
      DATAOUT        => gmii_rxd_delay(I),
      DATAOUT2       => open,
      DOUT           => open,
      TOUT           => open,
      CAL            => '0',
      CE             => '0',
      CLK            => '0',
      IDATAIN        => gmii_rxd(I),
      INC            => '0',
      IOCLK0         => '0',
      IOCLK1         => '0',
      ODATAIN        => '0',
      RST            => '0',
      T              => '1'
   );
   end generate;


   -- Infer IOB Input flip-flops.
   reg_gmii_rx_in : process (gmii_rx_clk_bufio)
   begin
      if gmii_rx_clk_bufio'event and gmii_rx_clk_bufio = '1' then
         rx_dv_to_mac         <= gmii_rx_dv_delay;
         rx_er_to_mac         <= gmii_rx_er_delay;
         rxd_to_mac           <= gmii_rxd_delay;
      end if;
  end process reg_gmii_rx_in;


end rtl;
