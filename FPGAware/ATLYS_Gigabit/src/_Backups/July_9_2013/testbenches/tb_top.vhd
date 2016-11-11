--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:34:14 05/10/2013
-- Design Name:   
-- Module Name:   E:/Projects/FPGAware/Osaka3/ATLYS_TestUART/tb_top.vhd
-- Project Name:  ATLYS_TestUART
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Top
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
 
ENTITY tb_top IS
END tb_top;
 
ARCHITECTURE behavior OF tb_top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Top
    PORT(
		clk_in 		: in  std_logic;
		hard_rst 	: in  std_logic;
		
		leds 			: out  std_logic_vector(7 downto 0);				
		btns 			: in  std_logic_vector(4 downto 0);
		switches 	: in  std_logic_vector(7 downto 0);
		
		phy_mdc		: out  std_logic;
		phy_mdio		: inout  std_logic;

		uart_rx 		: in  std_logic;
		uart_tx 		: out  std_logic
        );
    END COMPONENT;
	 

   --Inputs
   signal clk_in : std_logic := '0';
   signal hard_rst : std_logic := '0';
   signal uart_rx : std_logic := '1';
   signal btns : std_logic_vector(4 downto 0):= (others => '0');
   signal switches : std_logic_vector(7 downto 0):= (others => '0');
   signal phy_mdc : std_logic := '0';


 	--Outputs
   signal leds : std_logic_vector(7 downto 0);
   signal uart_tx : std_logic;
	signal phy_mdio : std_logic;

   -- Clock period definitions
   constant clk_in_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Top PORT MAP (
          clk_in => clk_in,
          hard_rst => hard_rst,
          leds => leds,
			 btns => btns,
			 switches => switches,
          uart_rx => uart_rx,
          uart_tx => uart_tx
			 
			 
        );

   -- Clock process definitions
   clk_in_process :process
   begin
		clk_in <= '0';
		wait for clk_in_period/2;
		clk_in <= '1';
		wait for clk_in_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		hard_rst <= '0';
	   wait for clk_in_period*20;
		hard_rst <= '1';
		
	   wait for clk_in_period*1000;

-- write register
---------------------------------
-- Send header	 [LSB->MSB]
---------------------------------		
-- Start bit
		uart_rx <= '0';
		wait for 104us;
-- 0xC8 [11001000] (wr to reg)
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
-- Stop bit
		uart_rx <= '1';		
		wait for 104us*4;
---------------------------------		
-- Send address
---------------------------------
-- Start bit
		uart_rx <= '0';
		wait for 104us;
-- 0x05
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
-- Stop bit
		uart_rx <= '1';		
		wait for 104us*4;
---------------------------------	
-- Send data hi
---------------------------------
-- Start bit
		uart_rx <= '0';
		wait for 104us;
-- 0x00
		uart_rx <= '0';
		wait for 104us*8;
-- Stop bit
		uart_rx <= '1';		
		wait for 104us*4;
---------------------------------	
-- Send data lo
---------------------------------
-- Start bit
		uart_rx <= '0';
		wait for 104us;
-- 0xE2 [11100010]
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '0';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
		uart_rx <= '1';
		wait for 104us;
-- Stop bit
		uart_rx <= '1';		
		wait for 104us*4;
---------------------------------	


--
---- Read registers
-----------------------------------
---- Send header	 [LSB->MSB]
-----------------------------------		
---- Start bit
--		uart_rx <= '0';
--		wait for 104us;
---- Packet type (reg read)
--		uart_rx <= '1';
--		wait for 104us;
--		uart_rx <= '0';
--		wait for 104us;
--		uart_rx <= '0';
--		wait for 104us;
---- SOF 0x19 (11001)
--		uart_rx <= '1';
--		wait for 104us;
--		uart_rx <= '0';
--		wait for 104us;
--		uart_rx <= '0';
--		wait for 104us;
--		uart_rx <= '1';
--		wait for 104us;
--		uart_rx <= '1';
--		wait for 104us;
---- Stop bit
--		uart_rx <= '1';		
--		wait for 104us*4;
-----------------------------------		
---- Send address
-----------------------------------
---- Start bit
--		uart_rx <= '0';
--		wait for 104us;
---- 0x00
--		uart_rx <= '0';
--		wait for 104us*8;
---- Stop bit
--		uart_rx <= '1';		
--		wait for 104us*4;
-----------------------------------	
---- Send data hi
-----------------------------------
---- Start bit
--		uart_rx <= '0';
--		wait for 104us;
---- 0x00
--		uart_rx <= '0';
--		wait for 104us*8;
---- Stop bit
--		uart_rx <= '1';		
--		wait for 104us*4;
-----------------------------------	
---- Send data lo
-----------------------------------
---- Start bit
--		uart_rx <= '0';
--		wait for 104us;
---- 0x00
--		uart_rx <= '0';
--		wait for 104us*8;
---- Stop bit
--		uart_rx <= '1';		
--		wait for 104us*4;
-----------------------------------	

      wait;
   end process;

END;
