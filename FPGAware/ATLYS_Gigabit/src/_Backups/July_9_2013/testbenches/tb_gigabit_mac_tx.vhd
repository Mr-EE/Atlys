--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:02:49 06/13/2013
-- Design Name:   
-- Module Name:   E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/tb_gigabit_mac_tx.vhd
-- Project Name:  ATLYS_Gigabit
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gigabit_mac
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_gigabit_mac_tx IS
END tb_gigabit_mac_tx;
 
ARCHITECTURE behavior OF tb_gigabit_mac_tx IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT gigabit_mac
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         clk_gtx : IN  std_logic;
         wb_cyc_i : IN  std_logic;
         wb_stb_i : IN  std_logic;
         wb_wr_i : IN  std_logic;
         wb_addr_i : IN  std_logic_vector(1 downto 0);
         wb_data_i : IN  std_logic_vector(0 downto 0);
         wb_data_o : OUT  std_logic_vector(15 downto 0);
         wb_ack_o : OUT  std_logic;
         gmii_tx_clk : OUT  std_logic;
         gmii_tx_en : OUT  std_logic;
         gmii_txd : OUT  std_logic_vector(7 downto 0);
         gmii_tx_er : OUT  std_logic;
         gmii_rx_clk : IN  std_logic;
         gmii_rx_dv : IN  std_logic;
         gmii_rxd : IN  std_logic_vector(7 downto 0);
         gmii_rx_er : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal clk_gtx : std_logic := '0';
   signal wb_cyc_i : std_logic := '0';
   signal wb_stb_i : std_logic := '0';
   signal wb_wr_i : std_logic := '0';
   signal wb_addr_i : std_logic_vector(1 downto 0) := (others => '0');
   signal wb_data_i : std_logic_vector(0 downto 0) := (others => '0');
   signal gmii_rx_clk : std_logic := '0';
   signal gmii_rx_dv : std_logic := '0';
   signal gmii_rxd : std_logic_vector(7 downto 0) := (others => '0');
   signal gmii_rx_er : std_logic := '0';

 	--Outputs
   signal wb_data_o : std_logic_vector(15 downto 0);
   signal wb_ack_o : std_logic;
   signal gmii_tx_clk : std_logic;
   signal gmii_tx_en : std_logic;
   signal gmii_txd : std_logic_vector(7 downto 0);
   signal gmii_tx_er : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 16 ns;
   constant clk_gtx_period : time := 8 ns;
   --constant gmii_tx_clk_period : time := 10 ns;
   constant gmii_rx_clk_period : time := 8 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: gigabit_mac PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          clk_gtx => clk_gtx,
          wb_cyc_i => wb_cyc_i,
          wb_stb_i => wb_stb_i,
          wb_wr_i => wb_wr_i,
          wb_addr_i => wb_addr_i,
          wb_data_i => wb_data_i,
          wb_data_o => wb_data_o,
          wb_ack_o => wb_ack_o,
          gmii_tx_clk => gmii_tx_clk,
          gmii_tx_en => gmii_tx_en,
          gmii_txd => gmii_txd,
          gmii_tx_er => gmii_tx_er,
          gmii_rx_clk => gmii_rx_clk,
          gmii_rx_dv => gmii_rx_dv,
          gmii_rxd => gmii_rxd,
          gmii_rx_er => gmii_rx_er
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 
   clk_gtx_process :process
   begin
		clk_gtx <= '1';
		wait for clk_gtx_period/2;
		clk_gtx <= '0';
		wait for clk_gtx_period/2;
   end process;
 
--   gmii_tx_clk_process :process
--   begin
--		gmii_tx_clk <= '0';
--		wait for gmii_tx_clk_period/2;
--		gmii_tx_clk <= '1';
--		wait for gmii_tx_clk_period/2;
--   end process;
 
   gmii_rx_clk_process :process
   begin
		gmii_rx_clk <= '0';
		wait for gmii_rx_clk_period/2;
		gmii_rx_clk <= '1';
		wait for gmii_rx_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      rst_i <= '1';
      wait for clk_i_period*10;	
		rst_i <= '0';
      wait for clk_i_period*10;
		wait for clk_i_period/2;
		
-- insert stimulus here 
		
		wait for clk_i_period/2;  -- setup data on falling edge
-- Enable packet generation
		wb_cyc_i <= '1';
		wb_stb_i <= '1';
		wb_wr_i <= '1';
		wb_addr_i <= "00";
		wb_data_i <= "1";
		wait for clk_i_period;
		
		wb_cyc_i <= '0';
		wb_stb_i <= '0';
		wb_wr_i <= '0';
		wait for clk_i_period;
		
		
		wait for 10 us;
		
-- Disable packet generation
		wb_cyc_i <= '1';
		wb_stb_i <= '1';
		wb_wr_i <= '1';
		wb_addr_i <= "00";
		wb_data_i <= "0";
		wait for clk_i_period;
		
		wb_cyc_i <= '0';
		wb_stb_i <= '0';
		wb_wr_i <= '0';
		wait for clk_i_period;
		
		
		wait for 10 us;
		
		
-- Re-enable packet generation
		wb_cyc_i <= '1';
		wb_stb_i <= '1';
		wb_wr_i <= '1';
		wb_addr_i <= "00";
		wb_data_i <= "1";
		wait for clk_i_period;
		
		wb_cyc_i <= '0';
		wb_stb_i <= '0';
		wb_wr_i <= '0';
		wait for clk_i_period;

      wait;
   end process;

END;
