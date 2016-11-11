----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:00:00 09/06/2013 
-- Design Name: 
-- Module Name:    gigabit_mac - RTL 
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
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VCOMPONENTS.ALL;

library work;
use work.constants.all;

entity gigabit_mac is
	Port 
	( 
-- Sys con interface
		clk_i 		: in std_logic;
		rst_i 		: in std_logic;
		clk_gtx		: in  std_logic;
		
-- Wishbone Interface
		wb_cyc_i 	: in std_logic;
		wb_stb_i 	: in std_logic;	
		--wb_sel_i 	: in std_logic;
		wb_wr_i 		: in std_logic;
		wb_addr_i 	: in std_logic_vector (1 downto 0);
		wb_data_i 	: in std_logic_vector (15 downto 0);
		
		wb_data_o 	: out std_logic_vector (15 downto 0);
		wb_ack_o 	: out std_logic;		

-- GMII phy interface
		gmii_tx_clk	: out std_logic;
		gmii_tx_en	: out std_logic;
		gmii_txd		: out std_logic_vector(7 downto 0);
		gmii_tx_er	: out std_logic;

		gmii_rx_clk	: in  std_logic;
		gmii_rx_dv	: in  std_logic;
		gmii_rxd		: in  std_logic_vector(7 downto 0);
		gmii_rx_er	: in  std_logic

	);
end gigabit_mac;

architecture rtl of gigabit_mac is

	component bram_tdp_2000d_16wr_8rd
	port (
		clka 	: in std_logic;
		rsta 	: in std_logic;
		ena 	: in std_logic;
		wea 	: in std_logic_vector(0 downto 0);
		addra : in std_logic_vector(9 downto 0);
		dina 	: in std_logic_vector(15 downto 0);
		douta : out std_logic_vector(15 downto 0);
		clkb 	: in std_logic;
		rstb 	: in std_logic;
		enb 	: in std_logic;
		web 	: in std_logic_vector(0 downto 0);
		addrb : in std_logic_vector(10 downto 0);
		dinb 	: in std_logic_vector(7 downto 0);
		doutb : out std_logic_vector(7 downto 0)
	);
	end component;
	
--	component bram_sdp_2000d_8wr_16rd
--	port (
--		clka 	: in std_logic;
--		ena 	: in std_logic;
--		wea 	: in std_logic_vector(0 downto 0);
--		addra : in std_logic_vector(10 downto 0);
--		dina 	: in std_logic_vector(7 downto 0);
--		clkb 	: in std_logic;
--		rstb 	: in std_logic;
--		enb 	: in std_logic;
--		addrb : in std_logic_vector(9 downto 0);
--		doutb : out std_logic_vector(15 downto 0)
--	);
--	end component;
	
	component gmii_if
	port(
	tx_reset 		: in std_logic;
	rx_reset 		: in std_logic;
	gmii_rxd 		: in std_logic_vector(7 downto 0);
	gmii_rx_dv 		: in std_logic;
	gmii_rx_er 		: in std_logic;
	gmii_rx_clk 	: in std_logic;
	txd_from_mac 	: in std_logic_vector(7 downto 0);
	tx_en_from_mac	: in std_logic;
	tx_er_from_mac : in std_logic;
	tx_clk 			: in std_logic;          
	gmii_txd 		: out std_logic_vector(7 downto 0);
	gmii_tx_en 		: out std_logic;
	gmii_tx_er 		: out std_logic;
	gmii_tx_clk 	: out std_logic;
	rxd_to_mac 		: out std_logic_vector(7 downto 0);
	rx_dv_to_mac 	: out std_logic;
	rx_er_to_mac 	: out std_logic;
	rx_clk 			: out std_logic
	);
	end component;
	

-- Wishbone signals
	signal wb_rd_req			: std_logic := '0'; 
   signal wb_wr_req			: std_logic := '0';
	signal wb_int_ack_o		: std_logic := '0';

-- Core internal registers
	signal reg_ctrl			: std_logic_vector(15 downto 0) := (others => '0'); 
	signal reg_cntr			: std_logic_vector(15 downto 0) := (others => '0'); 
	
-- Gigabit MAC internal signals
	signal tx_bram_ena		: std_logic := '0';
	signal tx_bram_wra		: std_logic_vector(0 downto 0) := (others => '0'); 	
	signal tx_bram_addra		: std_logic_vector(9 downto 0) := (others => '0'); 
	signal tx_bram_dina		: std_logic_vector(15 downto 0) := (others => '0'); 
	signal tx_bram_douta		: std_logic_vector(15 downto 0) := (others => '0'); 
	signal tx_bram_enb		: std_logic := '0';
	signal tx_bram_addrb		: std_logic_vector(10 downto 0) := (others => '0'); 
	signal tx_bram_doutb		: std_logic_vector(7 downto 0) := (others => '0'); 

	signal gb_tx_packet_generator_en			: std_logic := '0';
	signal gb_tx_packet_generator_en_dly	: std_logic := '0';
	signal gb_tx_max_send_packets				: std_logic_vector(15 downto 0) := (others => '0');
	signal gb_tx_packets_sent					: std_logic_vector(63 downto 0) := (others => '0');
	signal gb_tx_packet_length					: std_logic_vector(9 downto 0) := (others => '0');
	signal gb_tx_ifg_length						: std_logic_vector(15 downto 0) := (others => '0');

	signal tx_en_from_mac	: std_logic := '0'; 
	signal txd_from_mac		: std_logic_vector(7 downto 0) := (others => '0'); 	
	signal rx_clk				: std_logic := '0'; 
	signal rx_dv_to_mac		: std_logic := '0'; 
	signal rxd_to_mac			: std_logic_vector(7 downto 0) := (others => '0'); 		

   type gb_tx_state_type is (st0_idle, st1_send_data, st2_wait_ifg); 
	signal gb_tx_state		: gb_tx_state_type := st0_idle;


begin
	
	TX_BRAM_DATA : bram_tdp_2000d_16wr_8rd
	port map (
		clka 	=> clk_i,
		rsta 	=> rst_i,
		ena 	=> tx_bram_ena,
		wea 	=> tx_bram_wra,
		addra => tx_bram_addra,
		dina 	=> tx_bram_dina,
		douta => tx_bram_douta,
		clkb 	=> clk_gtx,
		rstb 	=> rst_i,
		enb 	=> tx_bram_enb,
		web 	=> (others => '0'), -- not used
		addrb => tx_bram_addrb,
		dinb 	=> (others => '0'), -- not used
		doutb => tx_bram_doutb
	);

--	RX_BRAM_DATA : bram_sdp_2000d_8wr_16rd
--	port map (
--		clka 	=> clka,
--		ena 	=> ena,
--		wea 	=> wea,
--		addra => addra,
--		dina 	=> dina,
--		clkb 	=> clkb,
--		rstb 	=> rstb,
--		enb	=> enb,
--		addrb => addrb,
--		doutb => doutb
--	);	


	GB_PHY_GMII: gmii_if
	port map(
		tx_reset => rst_i,
		rx_reset => rst_i,
		gmii_txd => gmii_txd,
		gmii_tx_en => gmii_tx_en,
		gmii_tx_er => gmii_tx_er,
		gmii_tx_clk => gmii_tx_clk,
		gmii_rxd => gmii_rxd,
		gmii_rx_dv => gmii_rx_dv,
		gmii_rx_er => gmii_rx_er,
		gmii_rx_clk => gmii_rx_clk,
		txd_from_mac => txd_from_mac,
		tx_en_from_mac => tx_en_from_mac,
		tx_er_from_mac => '0', -- function not used
		tx_clk => clk_gtx,
		rxd_to_mac => rxd_to_mac,
		rx_dv_to_mac => rx_dv_to_mac,
		rx_er_to_mac => open, -- function not used
		rx_clk => rx_clk 
	);	
	

-- Wishbone bus slave interface --------------------------------------------------

	-- Generate read and write request signals for Wishbone interface processes
	wb_rd_req <= '1' when (wb_stb_i = '1' and wb_cyc_i = '1' and wb_wr_i = '0') else '0';
	wb_wr_req <= '1' when (wb_stb_i = '1' and wb_cyc_i = '1' and wb_wr_i = '1') else '0';
	
	wb_ack_o <= wb_int_ack_o;
	
	-- Wishbone ACK process. Slave will ACK master when STB and CYC signals go high. ACK will last one cycle then
	--	 reset low.
	WB_ACK: process (clk_i, rst_i)
   begin
		if (rst_i = '1') then
			wb_int_ack_o <= '0';
      elsif rising_edge(clk_i) then
			wb_int_ack_o <= wb_stb_i and wb_cyc_i and not(wb_int_ack_o);
      end if;
   end process;

	-- Wishbone read process. Slave will output internal registers based on address requested from Master
	WB_READ: process (clk_i, rst_i)
   begin
		if (rst_i = '1') then
			wb_data_o <= (others => '0');
      elsif rising_edge(clk_i) then
			if (wb_rd_req = '1' and wb_int_ack_o = '0') then
				case wb_addr_i(1 downto 0) is
					when "00" 	=> wb_data_o	<= reg_ctrl;
					when "01"	=> wb_data_o	<= reg_cntr;
					when others	=> wb_data_o 	<= (others => '0');
				end case;
			end if;     
      end if;
   end process;
	
	-- Wishbone write process. Slave will store data to internal registers based on address/data from master	
	WB_WRITE: process (clk_i, rst_i)
   begin
		if (rst_i = '1') then
			reg_ctrl <= (others => '0');
      elsif rising_edge(clk_i) then
         if (wb_wr_req = '1' and wb_int_ack_o = '0') then
				case wb_addr_i(1 downto 0) is
					when "00" 	=> reg_ctrl	<= wb_data_i;
					when others	=> null;
				end case;
			end if;
      end if;
   end process;



-- Gigabit MAC  ------------------------------------------------------------------



---- GB PHY interface to RX bram (sends data)
--rx_bram_addra
--rx_bram_ena
--rx_bram_wra
--rx_bram_dina
--
---- Wishbone interface to RX bram (receives data)
--rx_bram_addrb
--rx_bram_doutb
--rx_bram_enb
--
--gb_rx_packet_receiver_en
--gb_rx_packets_received



-- Since reg_crtl(0) signal is a derived clock twice as slow as the clk_gtx (62.5MHz --> 125 MHz) 
--  a synchronizer is not needed
	

-- Gigabit TX FSM: When enable packet generation is set then MAC sends out data from BRAM and then repeats
--  until packet generation is disabled.

	tx_en_from_mac <= tx_bram_enb;
	txd_from_mac <= tx_bram_doutb;
	

	GB_TX_FSM: process (clk_gtx, rst_i)
		variable tx_bytepos			: integer range 0 to 999;
		variable ifg_bytepos			: integer range 0 to (2**16)-1;
		variable addr_offset			: integer range 0 to 1999;
		variable packets_sent 		: integer range 0 to (2**64)-1;
	begin
		if (rst_i = '1') then
			tx_bytepos := 0;
			ifg_bytepos := 0;
			addr_offset := 0;
			packets_sent := 0;
			tx_bram_addrb <= (others => '0');
			tx_bram_enb <= '0';
			gb_tx_state <= st0_idle;
		elsif rising_edge(clk_gtx) then
			gb_tx_packet_generator_en_dly <= gb_tx_packet_generator_en;
		
			-- Defaults to avoid latches and register outputs
			tx_bram_enb <= '0';
			tx_bram_addrb <= std_logic_vector(TO_UNSIGNED(addr_offset, tx_bram_addrb'length));

			case gb_tx_state is

				when st0_idle => 
					tx_bytepos := 0;
					ifg_bytepos := 0;
					addr_offset := 0;
					packets_sent := 0;
					gb_tx_state <= st0_idle;
					
					if (gb_tx_packet_generator_en = '1' and gb_tx_packet_generator_en_dly = '0') then -- Only start on a 0->1 transistion
						 gb_tx_state <= st1_send_data;
					end if;

				when st1_send_data  => 
					if (tx_bytepos = TO_INTEGER(UNSIGNED(gb_tx_packet_length))) then
						tx_bram_enb <= '0';
						addr_offset := addr_offset + tx_bytepos;
						tx_bytepos := 0;
						gb_tx_state <= st2_wait_ifg;    
					else
						tx_bram_enb <= '1';
						tx_bytepos := tx_bytepos + 1;
						gb_tx_state <= st1_send_data;
					end if;

				when st2_wait_ifg   =>
					if (ifg_bytepos = TO_INTEGER(UNSIGNED(gb_tx_ifg_length))) then
						ifg_bytepos := 0;
						packets_sent := packets_sent + 1;

						if (gb_tx_packet_generator_en = '0') then
							gb_tx_state <= st0_idle;
						elsif (TO_INTEGER(UNSIGNED(gb_tx_max_send_packets)) = 0) then-- loop forever or until disabled
							gb_tx_state <= st1_send_data;
						elsif (packets_sent = TO_INTEGER(UNSIGNED(gb_tx_max_send_packets))) then -- loop until desired amount of frames
							gb_tx_state <= st0_idle;
						else
							gb_tx_state <= st1_send_data;
						end if;
					else
						ifg_bytepos := ifg_bytepos + 1;
						gb_tx_state <= st2_wait_ifg;
					end if;
					
				when others =>
					gb_tx_state <= st0_idle;
					
			end case;               
		end if;
	end process;


---- Gigabit Packet FSM: When enable packet generation is set then MAC sends out data from BRAM and then repeats
----  until packet generation is disabled.
--	GIGABIT_LINK_FSM: process (clk_gtx, rst_i)
--		variable bytepos				: integer range 0 to 31;
--	   variable ifg					: integer range 0 to 15;
--		variable mac_packet_cntr	: integer range 0 to 65535;
--   begin
--		if (rst_i = '1') then
--			bytepos := 0;
--			ifg := 0;
--			tx_en_from_mac <= '0';
--			txd_from_mac <= (others => '0'); 
--			packet_addr <= (others => '0');
--			mac_packet_cntr := 0;	
--			gigabit_state <= st0_idle;
--      elsif rising_edge(clk_gtx) then
--		
--			case gigabit_state is
--			
--				when st0_idle => 
--					bytepos := 0;
--					ifg := 0;
--					packet_addr <= (others => '0');
--					tx_en_from_mac <= '0';
--					txd_from_mac <= (others => '0');
--					gigabit_state <= st0_idle;
--					
--					if (packet_start = '1') then
--						bytepos := bytepos + 1;
--						mac_packet_cntr := 0;
--						gigabit_state <= st1_pipe0;
--					end if;
--				
--				when st1_pipe0	=> 
--					packet_addr <= std_logic_vector(to_unsigned(bytepos, 8));
--					bytepos := bytepos + 1;
--					gigabit_state <= st2_pipe1;
--					
--				when st2_pipe1	=> 
--					packet_addr <= std_logic_vector(to_unsigned(bytepos, 8));
--					bytepos := bytepos + 1;
--					gigabit_state <= st3_pipe2;
--
--				when st3_pipe2	=> 
--					if (bytepos <= GIGABIT_PACKET_LEN + 3) then -- add two for pipeline
--						packet_addr <= std_logic_vector(to_unsigned(bytepos, 8));
--						bytepos := bytepos + 1;
--						tx_en_from_mac <= '1';
--					   txd_from_mac <= packet_data;     
--						gigabit_state <= st3_pipe2;
--					else
--						bytepos := 0;
--						ifg := 0;
--						packet_addr <= (others => '0');
--						tx_en_from_mac <= '0';
--					   txd_from_mac <= (others => '0');
--						mac_packet_cntr := mac_packet_cntr + 1;
--						gigabit_state <= st4_ifg;	
--					end if;
--					
--				when st4_ifg	=> 
--					gigabit_state <= st4_ifg;	
--				
--					if (ifg = IFG_TIMEOUT) then
--						if (packet_start = '1') then
--							ifg := 0;
--							bytepos := bytepos + 1;
--							gigabit_state <= st1_pipe0;
--						else
--							gigabit_state <= st0_idle;
--						end if;
--					else
--						ifg := ifg + 1;
--					end if;
--					
--				when others =>
--					gigabit_state <= st0_idle;	
--					
--			end case;				
--		end if;
--		
--		reg_cntr <= std_logic_vector(to_unsigned(mac_packet_cntr, 16));
--	end process;


end rtl;

