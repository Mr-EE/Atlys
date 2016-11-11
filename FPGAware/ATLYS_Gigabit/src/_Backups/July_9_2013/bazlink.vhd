----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:10:36 05/05/2013 
-- Design Name: 
-- Module Name:    bazlink - RTL 
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

library work;
use work.constants.all;

entity bazlink is
	port (
-- system common signals
		clk_i				: in  std_logic;
		rst_i				: in  std_logic;
			
-- wishbone master interface
		wb_cyc_o 	: out std_logic;
		wb_stb_o 	: out std_logic;
--		wb_sel_o 	: in std_logic;
		wb_wr_o 		: out std_logic;
		wb_addr_o 	: out std_logic_vector (7 downto 0);
		wb_data_o 	: out std_logic_vector (15 downto 0);
		
		wb_data_i 	: in std_logic_vector (15 downto 0);
		wb_ack_i 	: in std_logic;
		
-- communication link signals
		sdo			: out  std_logic;
		sdi			: in  std_logic	
		);
end bazlink;

architecture rtl of bazlink is

	component uart_cntrl
	port(
		clk_i 			: in std_logic;
		rst_i 			: in std_logic;
		tx_fifo_din		: in std_logic_vector(7 downto 0);
		tx_fifo_wr_en	: in std_logic;
		rx_fifo_rd_en	: in std_logic;
		sdi				: in std_logic;          
		tx_fifo_full	: out std_logic;
		rx_fifo_dout	: out std_logic_vector(7 downto 0);
		rx_fifo_empty	: out std_logic;
		rx_fifo_valid	: out std_logic;
		sdo 				: out std_logic
		);
	end component;
	
-----------------------------------------------------
-- internal signals
-----------------------------------------------------		
-- wishbone signals
	
-- com tx fifo signals
	signal tx_fifo_din				: std_logic_vector (7 downto 0) := (others => '0');
	signal tx_fifo_wr_en				: std_logic := '0';
	signal tx_fifo_full				: std_logic := '0';
	
-- com rx fifo signals	
	signal rx_fifo_dout				: std_logic_vector (7 downto 0) := (others => '0');
	signal rx_fifo_rd_en				: std_logic := '0';
	signal rx_fifo_empty				: std_logic := '0';
	signal rx_fifo_valid				: std_logic := '0';	
	
-- process packet signals
	type packet_states				is (packet_idle, get_packet_address, get_packet_data, 
													wb_master_wr, wb_master_rd, send_packet_header, 
													send_packet_address, send_packet_data);
	signal process_packet_state	: packet_states := packet_idle;
	signal rx_packet_type			: std_logic_vector (2 downto 0) := (others => '0');
	signal rx_packet_address		: std_logic_vector (7 downto 0) := (others => '0');
	signal rx_packet_data			: std_logic_vector (15 downto 0) := (others => '0');
	
	signal tx_packet_data			: std_logic_vector (15 downto 0) := (others => '0');

	
begin

	COM_CNTRL: uart_cntrl 
	port map(
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		tx_fifo_din		=> tx_fifo_din,
		tx_fifo_wr_en	=> tx_fifo_wr_en,
		tx_fifo_full	=> tx_fifo_full,
		rx_fifo_dout	=> rx_fifo_dout,
		rx_fifo_rd_en	=> rx_fifo_rd_en,
		rx_fifo_empty	=> rx_fifo_empty,
		rx_fifo_valid	=> rx_fifo_valid,
		sdo				=> sdo,
		sdi				=> sdi
	);


	wb_addr_o <= rx_packet_address;
	wb_data_o <= rx_packet_data(15 downto 0);
	--rx_fifo_rd_en <= '1' when (rx_fifo_empty = '0' and rx_fifo_valid = '0') else '0';
	
	
--** Debugging **
--	DEBUG: process (clk_i, rst_i)
--	begin
--		if (rst_i = '1') then
--			tx_fifo_wr_en <= '0';
--		elsif rising_edge(clk_i) then
--			if (rx_fifo_valid = '1') then
--				tx_fifo_wr_en <= '1';
--				tx_fifo_din <= rx_fifo_dout;
--			else
--				tx_fifo_wr_en <= '0';
--			end if;
--		end if;
--	end process;
--** Debugging **
	

	PROCESS_PACKET: process (clk_i, rst_i)
		variable rd_data_hi	: std_logic := '1';
		variable wr_data_hi	: std_logic := '1';
	begin
		if (rst_i = '1') then
			process_packet_state <= packet_idle;
			rd_data_hi := '1';
			wr_data_hi := '1';
			wb_wr_o <= '0';
			wb_stb_o <= '0';
			wb_cyc_o <= '0';
			rx_fifo_rd_en <= '0';
			tx_fifo_wr_en <= '0';
			rx_packet_type <= (others => '0');
			rx_packet_address <= (others => '0');
			rx_packet_data <= (others => '0');
			tx_packet_data <= (others => '0');
		elsif rising_edge(clk_i) then
			case (process_packet_state) is
			
				-- Wait for a data byte to be available on rx_fifo and read contents.
				--  Check if valid SOF character was received indicating start of packet
				when packet_idle =>
					rd_data_hi := '1';
					wr_data_hi := '1';
					tx_fifo_wr_en <= '0';
					tx_fifo_wr_en <= '0';
					
					if (rx_fifo_empty = '0' and rx_fifo_valid = '0') then
						rx_fifo_rd_en <= '1';
					else
						rx_fifo_rd_en <= '0';
					end if;

					if (rx_fifo_valid = '1') then
						if (rx_fifo_dout(7 downto 3) = BAZLINK_SOF) then
							rx_packet_type <= rx_fifo_dout(2 downto 0);
							process_packet_state <= get_packet_address;
						else
							process_packet_state <= packet_idle;
						end if;
					else
						process_packet_state <= packet_idle;
					end if;
				
				-- Wait for a data byte to be available on rx_fifo
				--  Store next byte to address				
				when get_packet_address =>
					if (rx_fifo_empty = '0' and rx_fifo_valid = '0') then
						rx_fifo_rd_en <= '1';
					else
						rx_fifo_rd_en <= '0';
					end if;
					
					if (rx_fifo_valid = '1') then
						rx_packet_address <= rx_fifo_dout;
						process_packet_state <= get_packet_data;
					else
						process_packet_state <= get_packet_address;
					end if;
					
				-- Wait for a data byte to be available on rx_fifo
				--  Store next two bytes to data							
				when get_packet_data =>
					if (rx_fifo_empty = '0' and rx_fifo_valid = '0') then
						rx_fifo_rd_en <= '1';
					else
						rx_fifo_rd_en <= '0';
					end if;
					
					if (rx_fifo_valid = '1') then
						if (rd_data_hi = '1') then
							rd_data_hi := '0';
							rx_packet_data(15 downto 8) <= rx_fifo_dout;
							process_packet_state <= get_packet_data;
						else
							rx_packet_data(7 downto 0) <= rx_fifo_dout;

							case rx_packet_type is
								when "000"	=> process_packet_state <= wb_master_wr; -- Master wb write
								when "001"	=> process_packet_state <= wb_master_rd; -- Master wb read
								when others => process_packet_state <= packet_idle; -- Invalid packet, return to idle
							end case;
						end if;
					else
						process_packet_state <= get_packet_data;
					end if;
				
				-- Wishbone write process. Master will send out data from processed packet
				--  to address decoded from packet on WB bus to slaves    		
				when wb_master_wr =>
					if (wb_ack_i = '1') then
						wb_wr_o <= '0';
						wb_stb_o <= '0';
						wb_cyc_o <= '0';
						process_packet_state <= packet_idle;
					else			
						wb_wr_o <= '1';
						wb_stb_o <= '1';
						wb_cyc_o <= '1';
						process_packet_state <= wb_master_wr;
					end if;

				-- Wishbone read process. Master will request data from slave based on
				--  address decoded from packet on WB bus to slaves    		
				when wb_master_rd =>
					if (wb_ack_i = '1') then
						wb_wr_o <= '0';
						wb_stb_o <= '0';
						wb_cyc_o <= '0';
						tx_packet_data <= wb_data_i;
						process_packet_state <= send_packet_header;
					else			
						wb_wr_o <= '0';
						wb_stb_o <= '1';
						wb_cyc_o <= '1';
						process_packet_state <= wb_master_rd;
					end if;

				-- Send packet header out com link	
				when send_packet_header =>
					if (tx_fifo_full = '0') then
						tx_fifo_wr_en <= '1';
						tx_fifo_din(7 downto 3) <= BAZLINK_SOF;
						tx_fifo_din(2 downto 0) <= "101";
						process_packet_state <= send_packet_address;
					else
						tx_fifo_wr_en <= '0';
						process_packet_state <= send_packet_header;
					end if;
					
			-- Send packet address out com link	
				when send_packet_address =>
					if (tx_fifo_full = '0') then
						tx_fifo_wr_en <= '1';
						tx_fifo_din <= rx_packet_address;
						process_packet_state <= send_packet_data;
					else
						tx_fifo_wr_en <= '0';
						process_packet_state <= send_packet_address;
					end if;
					
			-- Send packet data (2 bytes) out com link	
				when send_packet_data =>
					if (tx_fifo_full = '0') then
						tx_fifo_wr_en <= '1';
						if (wr_data_hi = '1') then
							wr_data_hi := '0';
							tx_fifo_din <= tx_packet_data(15 downto 8);
							process_packet_state <= send_packet_data;
						else
							tx_fifo_din <= tx_packet_data(7 downto 0);
							process_packet_state <= packet_idle;
						end if;
					else
						tx_fifo_wr_en <= '0';
						process_packet_state <= send_packet_data;
					end if;					
					
				-- if here then return to idle
				when others =>
					process_packet_state <= packet_idle;
		
			end case;
		end if;
	end process;


end rtl;

