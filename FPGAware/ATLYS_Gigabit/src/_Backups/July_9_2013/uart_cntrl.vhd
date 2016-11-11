----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:53:37 05/11/2010 
-- Design Name: 
-- Module Name:    uart_cntrl - RTL 
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_cntrl is
	port ( 

-- system common signals
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;

-- tx_fifo signals
		tx_fifo_din 	: in  std_logic_vector (7 downto 0);
		tx_fifo_wr_en	: in  std_logic;
		tx_fifo_full	: out  std_logic;
		
-- rx_fifo signals
		rx_fifo_dout 	: out  std_logic_vector (7 downto 0);
		rx_fifo_rd_en	: in  std_logic;
		rx_fifo_empty	: out  std_logic;
		rx_fifo_valid	: out  std_logic;

--- uart signals
		sdo				: out  std_logic;
		sdi				: in  std_logic	
		
	);
	end uart_cntrl;

architecture rtl of uart_cntrl is

	component uart_baud_gen
	port(
			clk_i		: in std_logic;
			rst_i		: in std_logic;
			baud		: out std_logic;
			baudx16	: out std_logic
	);
	end component;	
	
	component uart_tx is
	port (
			baud				: in std_logic;
			rst_i				: in std_logic;
			tx_data			: in std_logic_vector (7 downto 0);		
			tx_data_rdy		: in std_logic;
			tx_out			: out std_logic;
			tx_data_done	: out std_logic
	);
	end component;
	
	component uart_rx is
	port (
			baudx16		: in  std_logic;
			rst_i			: in  std_logic;
			rx_in			: in  std_logic;
			rx_data		: out std_logic_vector (7 downto 0);
			rx_data_rdy	: out std_logic
	);
	end component;
	
	component asyncfifo_16d_8w
	port (
			rst		: in std_logic;
			wr_clk	: in std_logic;
			rd_clk	: in std_logic;
			din		: in std_logic_vector(7 downto 0);
			wr_en		: in std_logic;
			rd_en		: in std_logic;
			dout		: out std_logic_vector(7 downto 0);
			full		: out std_logic;
			empty		: out std_logic;
			valid		: out std_logic
	);
	end component;

-- Synplicity black box declaration
--	attribute syn_black_box : boolean;
--	attribute syn_black_box of uart_fifo: component is true;

-----------------------------------------------------
-- internal signals
-----------------------------------------------------		
-- uart signals
	signal baud				: std_logic := '0';
	signal baudx16			: std_logic := '0';
	signal tx_data_done	: std_logic := '0';	
	signal rx_data_rdy	: std_logic := '0';		

-- uart_tx signals
	signal tx_fifo_dout	: std_logic_vector(7 downto 0) := (others => '0');
	signal tx_fifo_rd_en	: std_logic := '0';
	signal tx_fifo_empty	: std_logic := '0';
	signal tx_fifo_valid	: std_logic := '0';	
	
-- uart_rx signals
	signal rx_fifo_din	: std_logic_vector(7 downto 0) := (others => '0');
	signal rx_fifo_wr_en	: std_logic := '0';
	signal rx_fifo_full	: std_logic := '0';


--	attribute BUFFER_TYPE : string;
--	attribute BUFFER_TYPE of sdi: signal is "IBUFG";
--	attribute BUFFER_TYPE of sdo: signal is "OBUFG";
begin

-- generate the baud rate for uart_tx, and baudx16 for uart_rx
	BAUD_GEN: uart_baud_gen 
	port map(
			clk_i		=> clk_i,
			rst_i		=> rst_i,
			baud 		=> baud,
			baudx16 	=> baudx16
	);
	
-- controller for sending data on the uart
	TX: uart_tx 
	port map(
			baud 				=> baud,
			rst_i 			=> rst_i,
			tx_data 			=> tx_fifo_dout,
			tx_data_rdy 	=> tx_fifo_valid,
			tx_out 			=> sdo,
			tx_data_done	=> tx_data_done
	);
	
-- controller for receiving data on the uart
	RX: uart_rx 
	port map(
			baudx16 		=> baudx16,
			rst_i	 		=> rst_i,
			rx_in 		=> sdi,
			rx_data 		=> rx_fifo_din,
			rx_data_rdy	=> rx_data_rdy
	);
	
-- uart_tx fifo. fifo-in(clk_ref) is from inside FPGA, fifo-out(clk_baud) is to uart_tx
	TX_FIFO : asyncfifo_16d_8w
	port map (
			rst 		=> rst_i,
			wr_clk	=> clk_i,
			rd_clk 	=> baud,
			din 		=> tx_fifo_din,
			wr_en 	=> tx_fifo_wr_en,
			rd_en 	=> tx_fifo_rd_en,
			dout 		=> tx_fifo_dout,
			full 		=> tx_fifo_full,
			empty 	=> tx_fifo_empty,
			valid		=> tx_fifo_valid
	);

-- uart_rx fifo. fifo-in(clk_baudx16) is from uart_rx, fifo-out(clk_ref) is to inside FPGA
	RX_FIFO : asyncfifo_16d_8w
	port map (
			rst 		=> rst_i,
			wr_clk	=> baudx16,
			rd_clk 	=> clk_i,
			din 		=> rx_fifo_din,
			wr_en 	=> rx_fifo_wr_en,
			rd_en 	=> rx_fifo_rd_en,
			dout 		=> rx_fifo_dout,
			full 		=> rx_fifo_full,
			empty 	=> rx_fifo_empty,
			valid		=> rx_fifo_valid
	);
	

--	tx_fifo_rd_en <= not(tx_fifo_empty) and tx_data_done and not(tx_fifo_valid);
	tx_fifo_rd_en <= '1' when (tx_fifo_empty = '0' and tx_data_done = '1' and tx_fifo_valid = '0') else '0';
	
	
--	rx_fifo_wr_en <= not(rx_fifo_full) and rx_data_rdy;
	rx_fifo_wr_en <= '1' when (rx_fifo_full = '0' and rx_data_rdy = '1') else '0';
	
end rtl;

