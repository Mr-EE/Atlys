--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:50:39 05/26/2013
-- Design Name:   
-- Module Name:   E:/Projects/FPGAware/Osaka3/In Progress/ATLYS_Gigabit/tb_mdio_if.vhd
-- Project Name:  ATLYS_Gigabit
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mdio_if
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
 
ENTITY tb_mdio_if IS
END tb_mdio_if;
 
ARCHITECTURE behavior OF tb_mdio_if IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mdio_if
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         wb_cyc_i : IN  std_logic;
         wb_stb_i : IN  std_logic;
         wb_wr_i : IN  std_logic;
         wb_addr_i : IN  std_logic_vector(1 downto 0);
         wb_data_i : IN  std_logic_vector(15 downto 0);
         wb_data_o : OUT  std_logic_vector(15 downto 0);
         wb_ack_o : OUT  std_logic;
         pad_mdc : OUT  std_logic;
         pad_mdio : INOUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal wb_cyc_i : std_logic := '0';
   signal wb_stb_i : std_logic := '0';
   signal wb_wr_i : std_logic := '0';
   signal wb_addr_i : std_logic_vector(1 downto 0) := (others => '0');
   signal wb_data_i : std_logic_vector(15 downto 0) := (others => '0');

	--BiDirs
   signal pad_mdio : std_logic := 'Z';

 	--Outputs
   signal wb_data_o : std_logic_vector(15 downto 0);
   signal wb_ack_o : std_logic;
   signal pad_mdc : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 16 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mdio_if PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          wb_cyc_i => wb_cyc_i,
          wb_stb_i => wb_stb_i,
          wb_wr_i => wb_wr_i,
          wb_addr_i => wb_addr_i,
          wb_data_i => wb_data_i,
          wb_data_o => wb_data_o,
          wb_ack_o => wb_ack_o,
          pad_mdc => pad_mdc,
          pad_mdio => pad_mdio
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
      rst_i <= '1';
      wait for clk_i_period*10;	
		rst_i <= '0';
      wait for clk_i_period*10;
		wait for clk_i_period/2;
		
-- insert stimulus here 
		
		wait for clk_i_period/2;  -- setup data on falling edge
-- data reg
		wb_cyc_i <= '1';
		wb_stb_i <= '1';
		wb_wr_i <= '1';
		wb_addr_i <= "10";
		wb_data_i <= X"0303";
		wait for clk_i_period;
		
		wb_cyc_i <= '0';
		wb_stb_i <= '0';
		wb_wr_i <= '1';
		wait for clk_i_period;
		
-- address reg		
		wb_cyc_i <= '1';
		wb_stb_i <= '1';
		wb_wr_i <= '1';
		wb_addr_i <= "01";
		wb_data_i <= X"04E2";
		wait for clk_i_period;
		
		wb_cyc_i <= '0';
		wb_stb_i <= '0';
		wb_wr_i <= '1';
		
		
--		wait for 51480.1 ns;
--		wb_wr_i <= '0';
--		
--		pad_mdio <= '0';
--		wait for 3232 ns;
--		pad_mdio <= '1';
--		wait for 3232*8 ns;
--		pad_mdio <= '0';
--		wait for 3232 ns;
--		pad_mdio <= '1';
--		wait for 3232*7 ns;
--		
--		pad_mdio <= 'Z';
		
      wait;
   end process;

END;
