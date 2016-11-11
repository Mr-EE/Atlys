----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:29:07 05/15/2013 
-- Design Name: 
-- Module Name:    sync_reset - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sync_reset is
	port
	( 
			clk_i			: in  std_logic;
			locked_i		: in  std_logic;
			sync_rst_o	: out  std_logic
	);
end sync_reset;

architecture rtl of sync_reset is

	signal rst_shift_reg						: std_logic_vector (19 downto 0);
	
begin
-- Generation of synchronous reset
	reset_proc:process(clk_i, locked_i)
	begin
		if locked_i = '0' then
			rst_shift_reg <= (others => '1'); --asynchronous preload
		elsif rising_edge(clk_i) then
			rst_shift_reg <= rst_shift_reg(18 downto 0) & '0';
		end if;
	end process;

	sync_rst_o <= rst_shift_reg(19);
	 
end rtl;

