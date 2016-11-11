--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package constants is

-- Declare constants
	constant CLOCK_RATE			: integer := 62_500_000;
	constant BAUD_RATE			: integer := 128_000;
	constant MDIO_RATE			: integer := 625_000;
	constant LED_BLINK_RATE		: integer := 1;	--1 seconds	
	
--	constant MDIO_PREAMBLE		: std_logic := '1';
	constant MDIO_SOF				: std_logic_vector(1 downto 0) := "01";	
	constant MDIO_TURNAROUND	: std_logic_vector(1 downto 0) := "10";
	
	constant MDIO_WR_CTRL_LEN	: integer := 13;
	constant MDIO_WR_DATA_LEN	: integer := 16;	
	constant MDIO_RD_DATA_LEN	: integer := 16;	
	
	constant BAZLINK_SOF			: std_logic_vector(4 downto 0) := "11001";
	
end constants;


