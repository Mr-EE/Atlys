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
		wb_addr_i 	: in std_logic_vector (4 downto 0);
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
	
	component bram_sdp_2000d_8wr_16rd
	port (
		clka 	: in std_logic;
		ena 	: in std_logic;
		wea 	: in std_logic_vector(0 downto 0);
		addra : in std_logic_vector(10 downto 0);
		dina 	: in std_logic_vector(7 downto 0);
		clkb 	: in std_logic;
		rstb 	: in std_logic;
		enb 	: in std_logic;
		addrb : in std_logic_vector(9 downto 0);
		doutb : out std_logic_vector(15 downto 0)
	);
	end component;

	component bram_sdp_1024d_16wr_16rd
	port (
		clka 	: in std_logic;
		ena 	: in std_logic;
		wea 	: in std_logic_vector(0 downto 0);
		addra : in std_logic_vector(9 downto 0);
		dina 	: in std_logic_vector(15 downto 0);
		clkb 	: in std_logic;
		rstb 	: in std_logic;
		enb 	: in std_logic;
		addrb : in std_logic_vector(9 downto 0);
		doutb : out std_logic_vector(15 downto 0)
	);
	end component;

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
	signal reg_mac_cntrl		: std_logic_vector(5 downto 0) := (others => '0'); 
	signal reg_bram_address	: std_logic_vector(9 downto 0) := (others => '0'); 
	signal reg_bram_wr_data	: std_logic_vector(15 downto 0) := (others => '0'); 	
	signal reg_bram_rd_data	: std_logic_vector(15 downto 0) := (others => '0');

-- TX/RX BRAM control signals
	signal bram_access			: std_logic := '0';
	signal bram_access_wr_rd	: std_logic := '0';
	signal bram_access_sel		: std_logic_vector(1 downto 0) := (others => '0');
	signal bram_access_busy		: std_logic := '0';
	
   type bram_access_state_type is (	st0_idle, st1a_tx_bram_wr0, 
												st2a_tx_bram_rd0, st3a_tx_bram_rd1, st4a_tx_bram_rd2, 
												st1b_rx_bram_rd0, st2b_rx_bram_rd1, st3b_rx_bram_rd2,
												st1c_rx_ifg_bram_rd0, st2c_rx_ifg_bram_rd1, st3c_rx_ifg_bram_rd2); 
	signal bram_access_state		: bram_access_state_type := st0_idle;
	
-- Gigabit MAC internal signals
	signal tx_packet_generator_en			: std_logic := '0';
	signal tx_packet_generator_en_dly	: std_logic := '0';
	signal tx_packet_length					: std_logic_vector(9 downto 0) := (others => '0');
	signal tx_ifg_length						: std_logic_vector(15 downto 0) := (others => '0');
	signal tx_max_send_packets				: std_logic_vector(15 downto 0) := (others => '0');
	signal tx_packets_sent					: std_logic_vector(63 downto 0) := (others => '0');
	
	signal tx_bram_ena		: std_logic := '0';
	signal tx_bram_wra		: std_logic_vector(0 downto 0) := (others => '0'); 	
	signal tx_bram_addra		: std_logic_vector(9 downto 0) := (others => '0'); 
	signal tx_bram_dina		: std_logic_vector(15 downto 0) := (others => '0'); 
	signal tx_bram_douta		: std_logic_vector(15 downto 0) := (others => '0'); 
	signal tx_bram_enb		: std_logic := '0';
	signal tx_bram_addrb		: std_logic_vector(10 downto 0) := (others => '0'); 
	signal tx_bram_doutb		: std_logic_vector(7 downto 0) := (others => '0'); 
	
	signal tx_en_from_mac_pipe	: std_logic_vector(2 downto 0);
	signal tx_en_from_mac		: std_logic := '0'; 
	signal txd_from_mac			: std_logic_vector(7 downto 0) := (others => '0'); 
	
   type tx_state_type is (st0_idle, st1_send_data, st2_wait_ifg); 
	signal tx_state		: tx_state_type := st0_idle;


	signal rx_packet_generator_en			: std_logic := '0';
	signal rx_packet_generator_en_dly	: std_logic := '0';
	signal rx_packets_received				: std_logic_vector(63 downto 0) := (others => '0');
	
	signal rx_bram_ena		: std_logic := '0';
	signal rx_bram_wra		: std_logic_vector(0 downto 0) := (others => '0'); 	
	signal rx_bram_addra		: std_logic_vector(10 downto 0) := (others => '0'); 
	signal rx_bram_dina		: std_logic_vector(7 downto 0) := (others => '0'); 
	signal rx_bram_enb		: std_logic := '0';
	signal rx_bram_addrb		: std_logic_vector(9 downto 0) := (others => '0'); 
	signal rx_bram_doutb		: std_logic_vector(15 downto 0) := (others => '0');
	
	signal rx_ifg_bram_ena		: std_logic := '0';
	signal rx_ifg_bram_wra		: std_logic_vector(0 downto 0) := (others => '0'); 	
	signal rx_ifg_bram_addra	: std_logic_vector(9 downto 0) := (others => '0'); 
	signal rx_ifg_bram_dina		: std_logic_vector(15 downto 0) := (others => '0'); 
	signal rx_ifg_bram_enb		: std_logic := '0';
	signal rx_ifg_bram_addrb	: std_logic_vector(9 downto 0) := (others => '0'); 
	signal rx_ifg_bram_doutb	: std_logic_vector(15 downto 0) := (others => '0'); 
	
	signal rx_clk					: std_logic := '0'; 
	signal rx_dv_to_mac			: std_logic := '0'; 
	signal rxd_to_mac				: std_logic_vector(7 downto 0) := (others => '0'); 		
	
	type rx_state_type is (st0_idle, st1_check_rx_state, st2_wait_for_data, st3_receive_data); 
	signal rx_state		: rx_state_type := st0_idle;

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

	RX_BRAM_DATA : bram_sdp_2000d_8wr_16rd
	port map (
		clka 	=> rx_clk,
		ena 	=> rx_bram_ena,
		wea 	=> rx_bram_wra,
		addra => rx_bram_addra,
		dina 	=> rx_bram_dina,
		clkb 	=> clk_i,
		rstb 	=> rst_i,
		enb	=> rx_bram_enb,
		addrb => rx_bram_addrb,
		doutb => rx_bram_doutb
	);
	
	RX_IFG_BRAM_DATA : bram_sdp_1024d_16wr_16rd
	port map (
		clka 	=> rx_clk,
		ena 	=> rx_ifg_bram_ena,
		wea 	=> rx_ifg_bram_wra,
		addra => rx_ifg_bram_addra,
		dina 	=> rx_ifg_bram_dina,
		clkb 	=> clk_i,
		rstb 	=> rst_i,
		enb	=> rx_ifg_bram_enb,
		addrb => rx_ifg_bram_addrb,
		doutb => rx_ifg_bram_doutb
	);
  
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
				case wb_addr_i is
					when "01000" 	=> wb_data_o	<= "00000000000000" & reg_mac_cntrl(1 downto 0);
					when "01001"	=> wb_data_o	<= "000000" & tx_packet_length;
					when "01010" 	=> wb_data_o	<= tx_ifg_length;
					when "01011"	=> wb_data_o	<= tx_max_send_packets;		
					when "01100" 	=> wb_data_o	<= tx_packets_sent(15 downto 0);
					when "01101" 	=> wb_data_o	<= tx_packets_sent(31 downto 16);
					when "01110" 	=> wb_data_o	<= tx_packets_sent(47 downto 32);
					when "01111" 	=> wb_data_o	<= tx_packets_sent(63 downto 48);
					when "10000" 	=> wb_data_o	<= rx_packets_received(15 downto 0);
					when "10001" 	=> wb_data_o	<= rx_packets_received(31 downto 16);
					when "10010" 	=> wb_data_o	<= rx_packets_received(47 downto 32);
					when "10011" 	=> wb_data_o	<= rx_packets_received(63 downto 48);
					when "10100" 	=> wb_data_o	<= reg_mac_cntrl(5 downto 2) & "00" & reg_bram_address;
					when "10101" 	=> wb_data_o	<= reg_bram_wr_data;
					when "10110" 	=> wb_data_o	<= reg_bram_rd_data;					
					when others	=> wb_data_o 	<= (others => '0');
				end case;
			end if;     
      end if;
   end process;
	
	-- Wishbone write process. Slave will store data to internal registers based on address/data from master	
	WB_WRITE: process (clk_i, rst_i)
   begin
		if (rst_i = '1') then
			bram_access <= '0';
			reg_mac_cntrl(4 downto 3) <= (others => '0');
			reg_mac_cntrl(1 downto 0) <= (others => '0');
			tx_packet_length <= (others => '0');
			tx_ifg_length <= (others => '0');
			tx_max_send_packets <= (others => '0');
			reg_bram_address <= (others => '0');
			reg_mac_cntrl(4 downto 3) <= (others => '0');
			reg_bram_wr_data <= (others => '0');
      elsif rising_edge(clk_i) then
			bram_access <= '0';
			
         if (wb_wr_req = '1' and wb_int_ack_o = '0') then
				case wb_addr_i is
					when "01000" 	=> reg_mac_cntrl(1 downto 0)	<= wb_data_i(1 downto 0);
					when "01001" 	=> tx_packet_length				<= wb_data_i(9 downto 0);
					when "01010" 	=> tx_ifg_length					<= wb_data_i;
					when "01011" 	=> tx_max_send_packets			<= wb_data_i;
					when "10100" 	=> reg_mac_cntrl(5 downto 3)	<= wb_data_i(15 downto 13);	
											reg_bram_address				<= wb_data_i(9 downto 0);
											bram_access <= '1'; -- Pulse bram access signal for one clock cycle to start bram wr/rd access in seperate process
					when "10101" 	=> reg_bram_wr_data				<= wb_data_i;	
					when others	=> null;
				end case;
			end if;
      end if;
   end process;


-- Bram Control  ------------------------------------------------------------------

	-- Signal mapping
	bram_access_wr_rd <= reg_mac_cntrl(5);
	bram_access_sel <= reg_mac_cntrl(4 downto 3);
	reg_mac_cntrl(2) <= bram_access_busy;
	
	-- Performs a one clock cycle write and a two clock cycle read for both tx and rx brams (rx bram has only read access)
	BRAM_ACCESS_CNTRL: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			bram_access_busy <= '0';
			tx_bram_ena <= '0';
			tx_bram_wra	 <= "0";		
			tx_bram_addra <= (others => '0');	
			tx_bram_dina <= (others => '0');
			reg_bram_rd_data <= (others => '0');
			rx_bram_enb <= '0';
			rx_bram_addrb <= (others => '0');
			rx_ifg_bram_enb <= '0';
			rx_ifg_bram_addrb <= (others => '0');
		elsif rising_edge(clk_i) then
			
			-- Defaults to avoid latches and register outputs
			tx_bram_ena <= '0';
			tx_bram_wra	 <= "0";		
			tx_bram_addra <= reg_bram_address;	
			tx_bram_dina <= reg_bram_wr_data;

			rx_bram_enb <= '0';
			rx_bram_addrb <= reg_bram_address;
			
			rx_ifg_bram_enb <= '0';
			rx_ifg_bram_addrb <= reg_bram_address;
			
			--reg_bram_rd_data <= tx_bram_douta; -- This register has multiple sources, but defaults to tx_bram
		
			case bram_access_state is

				when st0_idle =>
					bram_access_busy <= '0';
					
					if (bram_access = '1') then -- A wr or rd command for the bram data has been issued
						bram_access_busy <= '1';
						
						if (bram_access_sel = "00" and bram_access_wr_rd = '0') then
							bram_access_state <= st1b_rx_bram_rd0;
							rx_bram_enb <= '1';
						elsif (bram_access_sel ="01" and bram_access_wr_rd = '1') then
							bram_access_state <= st1a_tx_bram_wr0;						
						elsif (bram_access_sel = "01" and bram_access_wr_rd = '0') then
							bram_access_state <= st2a_tx_bram_rd0;
							tx_bram_ena <= '1';	
						elsif (bram_access_sel = "10" and bram_access_wr_rd = '0') then
							bram_access_state <= st1c_rx_ifg_bram_rd0;
							rx_ifg_bram_enb <= '1';
						else
							bram_access_state <= st0_idle;
						end if;
					else
						bram_access_state <= st0_idle;
					end if;
					
				-- Write access TX BRAM data
				when st1a_tx_bram_wr0 =>
					tx_bram_ena <= '1';
					tx_bram_wra <= "1";
					bram_access_state <= st0_idle;
				
				-- Read access TX BRAM data
				when st2a_tx_bram_rd0 => 
					tx_bram_ena <= '1';
					bram_access_state <= st3a_tx_bram_rd1;
				
				when st3a_tx_bram_rd1 => 
					tx_bram_ena <= '1';
					bram_access_state <= st4a_tx_bram_rd2;

				when st4a_tx_bram_rd2 => 
					reg_bram_rd_data <= tx_bram_douta;
					bram_access_state <= st0_idle;
				
				-- Read access RX BRAM data		
				when st1b_rx_bram_rd0 => 
					rx_bram_enb <= '1';
					bram_access_state <= st2b_rx_bram_rd1;
					
				when st2b_rx_bram_rd1 => 
					rx_bram_enb <= '1';
					bram_access_state <= st3b_rx_bram_rd2;

				when st3b_rx_bram_rd2 => 
					reg_bram_rd_data <= rx_bram_doutb;
					bram_access_state <= st0_idle;
				
				-- Read access RX IFG BRAM
				when st1c_rx_ifg_bram_rd0 => 
					rx_ifg_bram_enb <= '1';
					bram_access_state <= st2c_rx_ifg_bram_rd1;
					
				when st2c_rx_ifg_bram_rd1 => 
					rx_ifg_bram_enb <= '1';
					bram_access_state <= st3c_rx_ifg_bram_rd2;

				when st3c_rx_ifg_bram_rd2 => 
					reg_bram_rd_data <= rx_ifg_bram_doutb;
					bram_access_state <= st0_idle;
					
				when others =>
					bram_access_state <= st0_idle;
					
			end case;
		end if;
	end process;


-- Gigabit MAC  ------------------------------------------------------------------

-- Since reg_mac_cntrl signals is a derived clock twice as slow as the clk_gtx (62.5MHz --> 125 MHz) 
--  a synchronizer is not needed
	tx_packet_generator_en <= reg_mac_cntrl(0);
	rx_packet_generator_en <= reg_mac_cntrl(1);


-- Gigabit TX FSM: When enable packet generation is set then MAC sends out data from BRAM and then repeats
--  until packet generation is disabled.	
	GB_TX_FSM: process (clk_gtx, rst_i)
		variable tx_bytepos			: integer range 0 to 999;
		variable tx_ifgpos			: integer range 0 to (2**16)-1;
		variable tx_addr				: integer range 0 to 1999;
		variable packets_sent 		: UNSIGNED(63 downto 0);
	begin
		if (rst_i = '1') then
			tx_bytepos := 0;
			tx_ifgpos := 0;
			tx_addr := 0;
			packets_sent := (others => '0');
			tx_packet_generator_en_dly <= '0';
			tx_packets_sent <= (others => '0');
			tx_bram_addrb <= (others => '0');
			txd_from_mac <= (others => '0');
			--tx_en_from_mac <= '0';
			tx_en_from_mac_pipe <= (others => '0');
			tx_bram_enb <= '0';
			tx_state <= st0_idle;
		elsif rising_edge(clk_gtx) then
			tx_packet_generator_en_dly <= tx_packet_generator_en;
					
			-- Defaults to avoid latches and register outputs
			tx_packets_sent <=std_logic_vector(packets_sent);--TO_UNSIGNED(packets_sent, tx_packets_sent'length));
			tx_bram_enb <= '0';
			tx_bram_addrb <= std_logic_vector(TO_UNSIGNED(tx_addr, tx_bram_addrb'length));
			txd_from_mac <= tx_bram_doutb;
			
			-- Create a 3 stage pipeline delay on the enable signal to match up with txd pipeline delays 
			--  (2 clock delays for bram read + output register)
			tx_en_from_mac_pipe(0) <= '0';
			tx_en_from_mac_pipe(1) <= tx_en_from_mac_pipe(0);
			tx_en_from_mac_pipe(2) <= tx_en_from_mac_pipe(1);
			tx_en_from_mac <= tx_en_from_mac_pipe(2);

			case tx_state is

				when st0_idle => 
					tx_bytepos := 0; -- Reset byte position counter
					tx_addr := 0; -- Reset address counter
					tx_ifgpos := 0; -- Reset IFG wait counter
					tx_state <= st0_idle;
					
					if (tx_packet_generator_en = '1' and tx_packet_generator_en_dly = '0') then -- Only start on a 0->1 transistion
						 packets_sent := (others => '0'); -- Reset packet counter
						 tx_state <= st1_send_data;
					end if;

				when st1_send_data  =>
					if (tx_bytepos = TO_INTEGER(UNSIGNED(tx_packet_length)) + 1) then -- extra cycle to handle delayed bram enable
						-- bram enable needs to be one clock cycle longer to allow memory to register on output; therefore,
						--  tx_bram_enb will go low on next state
						tx_bram_enb <= '1'; 
						tx_en_from_mac_pipe(0) <= '0';
						tx_bytepos := 0;
						tx_state <= st2_wait_ifg;    
					else
						tx_bram_enb <= '1';
						tx_en_from_mac_pipe(0) <= '1';
						tx_bytepos := tx_bytepos + 1;
						tx_addr := tx_addr + 1;
						tx_state <= st1_send_data;
					end if;
				
				when st2_wait_ifg   =>
					
					if (tx_ifgpos = TO_INTEGER(UNSIGNED(tx_ifg_length))) then
						tx_ifgpos := 0;
						packets_sent := packets_sent + 1;

						if (tx_packet_generator_en = '0') then
							tx_state <= st0_idle;
						elsif (TO_INTEGER(UNSIGNED(tx_max_send_packets)) = 0) then-- loop forever or until disabled
							tx_state <= st1_send_data;
						elsif (packets_sent = UNSIGNED(tx_max_send_packets)) then -- loop until desired amount of frames
							tx_state <= st0_idle;
						else
							tx_state <= st1_send_data;
						end if;
					else
						tx_ifgpos := tx_ifgpos + 1;
						tx_state <= st2_wait_ifg;
					end if;
					
				when others =>
					tx_state <= st0_idle;
					
			end case;               
		end if;
	end process;


-- Gigabit RX FSM: When enable packet generation is set then MAC receives a packet and stores into BRAM and then repeats
--  until packet generation is disabled. 
	GB_RX_FSM: process (rx_clk, rst_i)
		variable rx_addr				: integer range 0 to 1999;
		variable rx_ifg_cnt			: integer range 0 to (2**16)-1;
		variable packets_received 	: UNSIGNED(63 downto 0);
	begin
		if (rst_i = '1') then
			rx_addr := 0;
			rx_ifg_cnt := 0;
			packets_received := (others => '0');
			rx_bram_ena <= '0';
			rx_bram_wra <= "0";
			rx_packet_generator_en_dly <= '0';
			rx_packets_received <= (others => '0');
			rx_bram_addra <= (others => '0');
			rx_bram_dina <= (others => '0');
			rx_state <= st0_idle;
		elsif rising_edge(rx_clk) then
		
			-- Delay en signal by one clock to detect 0-->1 transition
			rx_packet_generator_en_dly <= rx_packet_generator_en;
			
			-- Defaults to avoid latches and register outputs
			rx_packets_received <= std_logic_vector(packets_received);--TO_UNSIGNED(packets_received, rx_packets_received'length));
			
			rx_bram_ena <= '0';
			rx_bram_wra <= "0";
			rx_bram_addra <= std_logic_vector(TO_UNSIGNED(rx_addr, rx_bram_addra'length));
			rx_bram_dina <= rxd_to_mac;
			
			rx_ifg_bram_ena <= '0';
			rx_ifg_bram_wra <= "0";
			rx_ifg_bram_addra <= std_logic_vector(packets_received(9 downto 0)); -- only look at first 10 bits
			rx_ifg_bram_dina <= std_logic_vector(TO_UNSIGNED(rx_ifg_cnt, rx_ifg_bram_dina'length));
			
			case rx_state is

				when st0_idle => 
					rx_addr := 0; -- Reset address counter
					rx_bram_ena <= '0'; -- Disable rx_bram
					rx_ifg_cnt := 0; -- Reset ifg counter
					rx_state <= st0_idle;
					
					if (rx_packet_generator_en = '1' and rx_packet_generator_en_dly = '0') then -- Only start on a 0->1 transistion
						 packets_received := (others => '0'); -- Reset packet counter
						 rx_state <= st1_check_rx_state;
					end if;
				
				when st1_check_rx_state  => 
					if (rx_dv_to_mac = '1') then -- Check to see if a packet is already being sent
						rx_state <= st1_check_rx_state; -- Wait for current data transaction to finish up
					else
						rx_state <= st2_wait_for_data; -- Advance to next state to wait for a new data transaction
					end if;
				
				when st2_wait_for_data  => 
					if (rx_dv_to_mac = '1') then
						rx_bram_ena <= '1';
						rx_bram_wra <= "1";
						rx_addr := rx_addr + 1;
						-- Write ifg wait count to bram
						rx_ifg_bram_ena <= '1';
						rx_ifg_bram_wra <= "1";
						rx_ifg_cnt := 0;
						rx_state <= st3_receive_data;
					else
						rx_ifg_cnt := rx_ifg_cnt + 1;
						rx_state <= st2_wait_for_data;
					end if;

				when st3_receive_data  => 
					if (rx_dv_to_mac = '1') then
						rx_bram_ena <= '1';
						rx_bram_wra <= "1";
						rx_addr := rx_addr + 1;
						rx_state <= st3_receive_data;
					else
						rx_bram_ena <= '0';
						rx_bram_wra <= "0";
						rx_ifg_cnt := rx_ifg_cnt + 1;
												
						packets_received := packets_received + 1; -- Increment packet counter
						
						-- Check to see if packet generator receive function is still enabled
						if (rx_packet_generator_en = '0') then
							rx_state <= st0_idle;
						else 
							rx_state <= st2_wait_for_data;
						end if;
					end if;
					
				when others =>
					rx_state <= st0_idle;
					
			end case;               
		end if;
	end process;

end rtl;