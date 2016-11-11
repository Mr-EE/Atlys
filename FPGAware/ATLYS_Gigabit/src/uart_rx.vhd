----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:15:55 04/14/2010 
-- Design Name: 
-- Module Name:    uart_rx - RTL 
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


entity uart_rx is
	port (
			baudx16			: in  std_logic;
			rst_i				: in  std_logic;
			rx_in				: in  std_logic;
			rx_data			: out std_logic_vector (7 downto 0);
			rx_data_rdy		: out std_logic
	);
end uart_rx;


architecture rtl of uart_rx is

	signal rx_reg			: std_logic_vector (7 downto 0) := (others => '0');
	signal rx_frame_err	: std_logic := '0';
	signal rx_d1			: std_logic := '1';
	signal rx_d2			: std_logic := '1';
	signal rx_busy			: std_logic := '0';
	 
begin

	process (baudx16, rst_i)
		variable rx_data_cnt		: integer range 0 to 8 := 0;
		variable rx_sample_cnt	: integer range 0 to 15 := 0;
	begin
		if (rst_i = '1') then
			rx_reg			<= (others=>'0');
			rx_data			<= (others=>'0');
			rx_sample_cnt	:= 0;
			rx_data_cnt		:= 0;
			rx_frame_err	<= '0';
			rx_data_rdy		<= '0';
			rx_d1				<= '1';
			rx_d2				<= '1';
			rx_busy			<= '0';
		elsif rising_edge(baudx16) then
		
			-- synchronize the asynch signal
			rx_d1 <= rx_in;
			rx_d2 <= rx_d1;
			
			-- reset data ready signal
			rx_data_rdy  <= '0';
					
			-- Check if just received start of frame
			if (rx_busy = '0' and rx_d2 = '0') then
				if (rx_sample_cnt = 7) then
					rx_busy			<= '1';	
					rx_sample_cnt	:= 0;
					rx_data_cnt		:= 0;
				else
					rx_sample_cnt := rx_sample_cnt + 1;
				end if;
			end if;
			
			-- Start of frame detected, Proceed with rest of data
			if (rx_busy = '1') then
			  -- Logic to sample at middle of start bit
				if (rx_sample_cnt = 15) then
					-- Start storing the rx data
					if (rx_data_cnt < 8) then
						rx_reg(conv_integer(rx_data_cnt)) <= rx_d2;
					elsif (rx_data_cnt = 8) then
						rx_busy <= '0';
						rx_data_cnt := 0;
						-- Check if End of frame received correctly
						if (rx_d2 = '0') then
							rx_frame_err <= '1';
						else
							-- load received data to rx_data, and signal rx_data_rdy
							rx_data <= rx_reg;
							rx_data_rdy  <= '1';
							rx_frame_err <= '0';
						end if;
					end if;
					rx_sample_cnt := 0;
					rx_data_cnt := rx_data_cnt + 1;
				else
					rx_sample_cnt := rx_sample_cnt + 1;
				end if;
			end if;
		end if;
	end process;
end rtl;