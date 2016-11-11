----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:15:55 04/14/2010 
-- Design Name: 
-- Module Name:    uart_baud_gen - RTL 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.constants.all;


entity uart_baud_gen is
	port ( 
			clk_i		: in  std_logic;					-- clock_in
			rst_i		: in  std_logic;					-- external reset in
			baud		: out  std_logic;					-- baud rate
			baudx16	: out  std_logic					-- 16 times the baud rate
	);
end uart_baud_gen;


architecture rtl of uart_baud_gen is
begin
	process (clk_i, rst_i)
		constant oversample_value1	: integer := (CLOCK_RATE/(BAUD_RATE));
		constant oversample_value2	: integer := (CLOCK_RATE/(BAUD_RATE*16));
		variable cnt1					: integer range 0 to oversample_value1 := 0;
		variable cnt2					: integer range 0 to oversample_value2 := 0;
	begin
		if (rst_i = '1') then
			cnt1 := 0;
			cnt2 := 0;
			baud <= '0';
			baudx16 <= '0';	
		elsif (rising_edge(clk_i)) then 
			baud <= '0';
			baudx16 <= '0';
			-- baud rate generator
			if (cnt1 = oversample_value1) then
				baud <= '1';
				cnt1 := 0;
			else   
				cnt1 := cnt1 + 1;
			end if;
			-- baud rate x 16 generator
			if (cnt2 = oversample_value2) then
				baudx16   <= '1';
				cnt2 := 0;
			else   
				cnt2 := cnt2 + 1;
			end if;			
		end if;
	end process;
end rtl;

