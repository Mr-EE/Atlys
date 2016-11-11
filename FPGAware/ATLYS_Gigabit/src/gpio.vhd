----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:49:13 05/10/2013 
-- Design Name: 
-- Module Name:    gpio - rtl 
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

	entity gpio is
	port(

-- sys con signals
		clk_i			: in  std_logic;
		rst_i			: in  std_logic;
		
-- Wishbone slave signals
		wb_cyc_i		: in  std_logic;
		wb_stb_i		: in  std_logic;
		wb_wr_i		: in  std_logic;
		wb_addr_i	: in  std_logic_vector (1 downto 0);
		wb_data_i	: in  std_logic_vector (6 downto 0);
		wb_ack_o		: out  std_logic;
		wb_data_o	: out  std_logic_vector (7 downto 0);
		
-- gpio signals
		leds			: out  std_logic_vector (6 downto 0);
		btns			: in  std_logic_vector (4 downto 0);
		switches		: in  std_logic_vector (7 downto 0)
		
	);
	end gpio;

architecture rtl of gpio is

	component debounce
	generic(
		counter_size  :  integer := 19); --counter size
	port(
		clk_i : in std_logic;
		rst_i : in std_logic;
		sig_i : in std_logic;          
		sig_o : out std_logic
		);
	end component;

-----------------------------------------------------
-- internal signals
-----------------------------------------------------		

-- Wishbone signals
	signal wb_wr_req		: std_logic := '0';
	signal wb_rd_req		: std_logic := '0';
	signal wb_int_ack_o	: std_logic := '0';

-- Core internal registers
	signal reg_led			: std_logic_vector (6 downto 0) := (others => '0');
	signal reg_btn			: std_logic_vector (4 downto 0) := (others => '0');
	signal reg_switch		: std_logic_vector (7 downto 0) := (others => '0');
	
	signal db_btns			: std_logic_vector (4 downto 0) := (others => '0');
	signal db_switches	: std_logic_vector (7 downto 0) := (others => '0');	
	
begin

	DB_BTN_GEN: for i in 0 to 4 generate    
		DEBOUNCE_BTNS: debounce
		generic map(
			counter_size => 19) -- 2^N/f = 2^19/62.5 Mhz ~ 8.39ms debounce period
		port map(
			clk_i => clk_i,
			rst_i => rst_i,
			sig_i => btns(i),
			sig_o => db_btns(i)
		);
	end generate;

	DB_SWITCHES_GEN: for i in 0 to 7 generate    
		DEBOUNCE_SWITCHES: debounce
		generic map(
			counter_size => 19) -- 2^N/f = 2^19/62.5 Mhz ~ 8.39ms debounce period
		port map(
			clk_i => clk_i,
			rst_i => rst_i,
			sig_i => switches(i),
			sig_o => db_switches(i)
		);
	end generate;	
	
	
-- I/O register mapping
	leds <= reg_led;
	reg_btn <= db_btns;
	reg_switch <= db_switches;
	
-----------------------------------------------------
-- Wishbone bus slave interface
-----------------------------------------------------
	-- Generate write/read request signal for wishbone interface processes
	wb_wr_req <= '1' when (wb_stb_i = '1' and wb_cyc_i = '1' and wb_wr_i = '1') else '0';
	wb_rd_req <= '1' when (wb_stb_i = '1' and wb_cyc_i = '1' and wb_wr_i = '0') else '0';    
	 
	wb_ack_o <= wb_int_ack_o;
	
	-- Wishbone ACK process. Slave will ACK master when STB and CYC signals go high. ACK will last one cycle then
	--  reset low.
	WB_ACK: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			wb_int_ack_o <= '0';
		elsif rising_edge(clk_i) then
			wb_int_ack_o <= wb_stb_i and wb_cyc_i and not(wb_int_ack_o);
		end if;     
	end process;

	-- Wishbone write process. Slave will store data to internal registers based on address/data from master
	WB_WRITE: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			reg_led <= (others => '0');
		elsif rising_edge(clk_i) then
			if (wb_wr_req = '1' and wb_int_ack_o = '0') then
				if wb_addr_i = "00" then
					reg_led	<= wb_data_i(6 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	-- Wishbone read process. Slave will output internal registers based on address requested from Master 
	WB_RD: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			wb_data_o <= (others => '0');
		elsif rising_edge(clk_i) then
			if (wb_rd_req = '1' and wb_int_ack_o = '0') then
				case wb_addr_i(1 downto 0) is
					when "00"   => wb_data_o	<= '0' & reg_led;
					when "01"   => wb_data_o	<= "000" & reg_btn;
					when "10"   => wb_data_o	<= reg_switch;
					when others => wb_data_o	<= (others => '0');
				end case;
			end if;     
		end if;
	end process;
-----------------------------------------------------
	

end rtl;

