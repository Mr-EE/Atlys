--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:08:13 05/05/2013
-- Design Name:   
-- Module Name:   E:/Projects/FPGAware/Osaka3/ATLYS_TestUART/tb_uart_cntrl.vhd
-- Project Name:  ATLYS_TestUART
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: uart_cntrl
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
 
ENTITY tb_uart_cntrl IS
END tb_uart_cntrl;
 
ARCHITECTURE behavior OF tb_uart_cntrl IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT uart_cntrl
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         sdo : OUT  std_logic;
         sdi : IN  std_logic;
         tx_fifo_din : IN  std_logic_vector(7 downto 0);
         tx_fifo_wr_en : IN  std_logic;
         tx_fifo_full : OUT  std_logic;
         rx_fifo_dout : OUT  std_logic_vector(7 downto 0);
         rx_fifo_rd_en : IN  std_logic;
         rx_fifo_empty : OUT  std_logic;
         rx_fifo_valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal sdi : std_logic := '1';
   signal tx_fifo_din : std_logic_vector(7 downto 0) := (others => '0');
   signal tx_fifo_wr_en : std_logic := '0';
   signal rx_fifo_rd_en : std_logic := '0';

 	--Outputs
   signal sdo : std_logic;
   signal tx_fifo_full : std_logic;
   signal rx_fifo_dout : std_logic_vector(7 downto 0);
   signal rx_fifo_empty : std_logic;
   signal rx_fifo_valid : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: uart_cntrl PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          sdo => sdo,
          sdi => sdi,
          tx_fifo_din => tx_fifo_din,
          tx_fifo_wr_en => tx_fifo_wr_en,
          tx_fifo_full => tx_fifo_full,
          rx_fifo_dout => rx_fifo_dout,
          rx_fifo_rd_en => rx_fifo_rd_en,
          rx_fifo_empty => rx_fifo_empty,
          rx_fifo_valid => rx_fifo_valid
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
	   wait for clk_i_period*10;	
		
      -- hold reset state for 10 clock cycles
		rst_i <= '1';
      wait for clk_i_period*10;	
		
		rst_i <= '0';

      wait for clk_i_period*10;

-- tx fifo test 
		tx_fifo_din <= X"0F";
		tx_fifo_wr_en <= '1';
		
		wait for clk_i_period;
	
		tx_fifo_wr_en <= '0';
		
		wait for clk_i_period;
		
		tx_fifo_din <= X"F0";
		tx_fifo_wr_en <= '1';
		
		wait for clk_i_period;
		
		tx_fifo_wr_en <= '0';

		wait for clk_i_period*100000;
		
		tx_fifo_din <= X"0E";
		tx_fifo_wr_en <= '1';

		wait for clk_i_period;
	
		tx_fifo_wr_en <= '0';
		
		wait for clk_i_period;
		
		tx_fifo_din <= X"E0";
		tx_fifo_wr_en <= '1';
		
		wait for clk_i_period;
		
		tx_fifo_wr_en <= '0';
		
		wait for clk_i_period;
		
-- rx fifo test		
		sdi <= '0';
		wait for 104us;
		sdi <= '1';
		wait for 104us;
		sdi <= '0';
		wait for 104us;
		sdi <= '1';
		wait for 104us;
		sdi <= '0';
		wait for 104us;
		sdi <= '1';
		wait for 104us;
		sdi <= '0';
		wait for 104us;
		sdi <= '1';
		wait for 104us;
		sdi <= '0';
		wait for 104us;
		sdi <= '1';
		
		-- read fifo contents
		wait for 104us;
		rx_fifo_rd_en <= '1';
		wait for clk_i_period;
		rx_fifo_rd_en <= '0';
		

      wait;
   end process;

END;
