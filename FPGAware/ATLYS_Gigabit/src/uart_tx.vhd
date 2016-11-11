----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:15:55 04/14/2010 
-- Design Name: 
-- Module Name:    uart_tx - RTL 
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


entity uart_tx is
	port (
			baud				: in std_logic;
			rst_i				: in std_logic;
			tx_data			: in std_logic_vector (7 downto 0);		
			tx_data_rdy		: in std_logic;
			tx_out			: out std_logic;
			tx_data_done	: out std_logic
	);
end uart_tx;


architecture rtl of uart_tx is

	signal tx_reg		: std_logic_vector (7 downto 0) := (others => '0');
	signal tx_empty	: std_logic := '1';
	
begin

	process (baud, rst_i) 
		variable cnt : integer range 0 to 9 := 0;
	begin
		if (rst_i = '1') then
			tx_reg 			<= (others=>'0');
			tx_data_done	<= '1';
			tx_empty			<= '1';
			tx_out 			<= '1';
			cnt 				:= 0;
		elsif rising_edge(baud) then
		
			-- reset done pulse
			--tx_data_done 	<= '0';
		
			-- load data to be transmitted to register if previous byte 
			--  has finished sending out
			if (tx_data_rdy = '1' and tx_empty = '1') then
				tx_reg 			<= tx_data;
				tx_empty			<= '0';
				tx_data_done 	<= '0';
				cnt 				:= 0;		
			end if;
			
			if (tx_empty = '0') then
				-- send start bit
				if (cnt = 0) then
					tx_out <= '0';
				-- shift out 8 data bits lsb first
				elsif (cnt < 9) then
					tx_out <= tx_reg(conv_integer(cnt)-1);
				-- send stop bit
				elsif (cnt = 9) then
					tx_out <= '1';
					cnt := 0;
					tx_empty <= '1';
					tx_data_done 	<= '1';
				end if;
				
				cnt := cnt + 1;
				
			end if;	
		end if;
	end process;
end rtl;


