--------------------------------------------------------------------------------
--
--   FileName:         debounce.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 3/26/2012 Scott Larson
--     Initial Public Release
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debounce is
	generic(
		counter_size  :  integer := 19); --counter size
	port(
		clk_i	: in  std_logic;  --input clock
		rst_i	: in  std_logic;	--input reset
		sig_i	: in  std_logic;  --input signal to be debounced
		sig_o	: out std_logic	--debounced signal
	); 
	end debounce;

architecture rtl of debounce is
	signal flipflops   : std_logic_vector(1 downto 0); --input flip flops
	signal counter_set : std_logic;                    --sync reset to zero
	signal counter_out : std_logic_vector(counter_size downto 0) := (others => '0'); --counter output
begin
	
	counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter
  
	process(clk_i, rst_i)
		begin
			if rst_i = '1' then
				sig_o <= '0';
				counter_out <= (others => '0');
				flipflops <= (others => '0');
			elsif rising_edge(clk_i) then
				flipflops(0) <= sig_i;
				flipflops(1) <= flipflops(0);
				if(counter_set = '1') then                  --reset counter because input is changing
					counter_out <= (others => '0');
				elsif(counter_out(counter_size) = '0') then --stable input time is not yet met
					counter_out <= counter_out + 1;
				else                                        --stable input time is met
					sig_o <= flipflops(1);
				end if;    
			end if;
		end process;
		
end rtl;
