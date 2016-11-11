----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:49:13 05/10/2013 
-- Design Name: 
-- Module Name:    leds - rtl 
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

library work;
use work.constants.all;

	entity led_blink is
	port(
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		led			: out  std_logic
		
	);
	end led_blink;

architecture rtl of led_blink is

-----------------------------------------------------
-- internal signals
-----------------------------------------------------		

	signal blink	: std_logic := '0';
	
begin

	led <= blink;
	
	process (clk_i, rst_i)
		constant oversample_value1	: integer := (CLOCK_RATE/(LED_BLINK_RATE));
		variable cnt1					: integer range 0 to oversample_value1 := 0;
	begin
		if (rst_i = '1') then
			cnt1 := 0;
			blink <= '0';	
		elsif (rising_edge(clk_i)) then 
			if (cnt1 = oversample_value1) then
				blink <= blink xor '1';
				cnt1 := 0;
			else   
				cnt1 := cnt1 + 1;
			end if;	
		end if;
	end process;
	
end rtl;


