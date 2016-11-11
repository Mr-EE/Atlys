----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:44:06 05/10/2013 
-- Design Name: 
-- Module Name:    Top - RTL 
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

library UNISIM;
use UNISIM.VComponents.all;

entity top is
	port(
	
-- System Control
		clk_in 		: in  std_logic;
		hard_rst 	: in  std_logic;
		
-- GPIO
		leds 			: out  std_logic_vector(7 downto 0);				
		btns 			: in  std_logic_vector(4 downto 0);
		switches 	: in  std_logic_vector(7 downto 0);
		
-- Marvell 88E1111 Gigabit PHY
		phy_rst		: out  std_logic;
		phy_mdc		: out  std_logic;
		phy_mdio		: inout  std_logic;
		
		phy_gmii_txc		: out  std_logic;
		phy_gmii_tx_ctl	: out  std_logic;
		phy_gmii_tx_er		: out  std_logic;
		phy_gmii_txd		: out  std_logic_vector(7 downto 0);
		
		phy_gmii_rxc		: in  std_logic;
		phy_gmii_rx_dv		: in  std_logic;
		phy_gmii_rx_er		: in  std_logic;
		phy_gmii_rxd		: in  std_logic_vector(7 downto 0);	

-- Uart
		uart_rx 		: in  std_logic;
		uart_tx 		: out  std_logic
		);
end top;

architecture rtl of top is

	component dsm_clk_in_100
	port(
		clk_in			: in     std_logic;
		clk_out_62_5	: out    std_logic;
		clk_out_125		: out    std_logic;
		rst				: in     std_logic;
		locked			: out    std_logic
	);
	end component;
	
	component sync_reset
	port(
		clk_i			: in std_logic;
		locked_i		: in std_logic;          
		sync_rst_o	: out std_logic
	);
	end component;

	component bazlink
	port(
		clk_i			: in std_logic;
		rst_i			: in std_logic;
		wb_data_i	: in std_logic_vector(15 downto 0);
		wb_ack_i		: in std_logic;
		sdi			: in std_logic;          
		wb_cyc_o		: out std_logic;
		wb_stb_o		: out std_logic;
		wb_wr_o		: out std_logic;
		wb_addr_o	: out std_logic_vector(7 downto 0);
		wb_data_o	: out std_logic_vector(15 downto 0);
		sdo			: out std_logic
	);
	end component;
	
	component gpio
	port(
		clk_i			: in std_logic;
		rst_i			: in std_logic;
		wb_cyc_i		: in std_logic;
		wb_stb_i		: in std_logic;
		wb_wr_i		: in std_logic;
		wb_addr_i	: in std_logic_vector(1 downto 0); 
		wb_data_i	: in std_logic_vector(6 downto 0);          
		wb_ack_o		: out std_logic;
		wb_data_o	: out std_logic_vector(7 downto 0);   
		leds			: out std_logic_vector(6 downto 0);
		btns			: in std_logic_vector(4 downto 0);
		switches		: in std_logic_vector(7 downto 0)
	);
	end component;
	
	component led_blink
	port(
		clk_i	: in std_logic;
		rst_i	: in std_logic;          
		led	: out std_logic
	);
	end component;
	
	component mdio_if
	port(
		clk_i			: in std_logic;
		rst_i			: in std_logic;
		wb_cyc_i		: in std_logic;
		wb_stb_i		: in std_logic;
		wb_wr_i		: in std_logic;
		wb_addr_i	: in std_logic_vector(1 downto 0);
		wb_data_i	: in std_logic_vector(15 downto 0);    
		pad_mdio		: inout std_logic;      
		wb_data_o	: out std_logic_vector(15 downto 0);
		wb_ack_o		: out std_logic;
		pad_mdc		: out std_logic
	);
	end component;
	
	component gigabit_mac
	port(
		clk_i 		: in std_logic;
		rst_i 		: in std_logic;
		clk_gtx 		: in std_logic;
		wb_cyc_i 	: in std_logic;
		wb_stb_i 	: in std_logic;
		wb_wr_i 		: in std_logic;
		wb_addr_i 	: in std_logic_vector(4 downto 0);
		wb_data_i 	: in std_logic_vector(15 downto 0);
		gmii_rx_clk : in std_logic;
		gmii_rx_dv 	: in std_logic;
		gmii_rxd 	: in std_logic_vector(7 downto 0);
		gmii_rx_er 	: in std_logic;          
		wb_data_o 	: out std_logic_vector(15 downto 0);
		wb_ack_o 	: out std_logic;
		gmii_tx_clk : out std_logic;
		gmii_tx_en 	: out std_logic;
		gmii_txd 	: out std_logic_vector(7 downto 0);
		gmii_tx_er 	: out std_logic
	);
	end component;	
-----------------------------------------------------
-- internal signals
-----------------------------------------------------		

-- Sys con signals
	signal clk_i				: std_logic := '0';
	signal clk_gtx				: std_logic := '0'; 
	signal rst_i				: std_logic := '0';
	signal rst_glb				: std_logic := '0';
	signal locked_state		: std_logic := '0';
	
-- Wishbone master bus signals
	signal master_wb_cyc_o	: std_logic := '0';
	signal master_wb_stb_o	: std_logic := '0';
	signal master_wb_wr_o	: std_logic := '0';
	signal master_wb_addr_o	: std_logic_vector(7 downto 0) := (others => '0');
	signal master_wb_data_o	: std_logic_vector(15 downto 0) := (others => '0');
	signal master_wb_data_i	: std_logic_vector(15 downto 0) := (others => '0');
	signal master_wb_ack_i	: std_logic := '0';
	
-- Wishbone salve bus signals [GPIO]
	signal gpio_en				: std_logic := '0';
	signal gpio_sel			: std_logic := '0';
	signal gpio_addr			: std_logic_vector(1 downto 0) := (others => '0');
	signal gpio_wb_ack_o		: std_logic := '0';
	signal gpio_wb_data_o	: std_logic_vector(7 downto 0) := (others => '0');
	
-- Wishbone salve bus signals [GB PHY MDIO]
	signal gb_phy_mdio_en	: std_logic := '0';
	signal gb_phy_mdio_sel	: std_logic := '0';
	signal gb_phy_mdio_addr	: std_logic_vector(1 downto 0) := (others => '0');
	signal gb_phy_wb_ack_o	: std_logic := '0';
	signal gb_phy_wb_data_o	: std_logic_vector(15 downto 0) := (others => '0');

-- Wishbone salve bus signals [GB MAC]
	signal gb_mac_en			: std_logic := '0';
	signal gb_mac_sel			: std_logic := '0';
	signal gb_mac_addr		: std_logic_vector(4 downto 0) := (others => '0');
	signal gb_mac_wb_ack_o	: std_logic := '0';
	signal gb_mac_wb_data_o	: std_logic_vector(15 downto 0) := (others => '0');
		
begin
	
	rst_glb <= not(hard_rst);
	
	phy_rst <= not(rst_i);
	
	DSM0 : dsm_clk_in_100
	port map
	(
	clk_in			=> clk_in,
	clk_out_62_5	=> clk_i,
	clk_out_125		=> clk_gtx,
	rst				=> rst_glb,
	locked			=> locked_state
	);
	
	SYNC_RST: sync_reset 
	port map(
		clk_i			=> clk_i,
		locked_i		=> locked_state,
		sync_rst_o	=> rst_i
	);
	
	UART_LINK: bazlink 
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		wb_cyc_o		=> master_wb_cyc_o,
		wb_stb_o		=> master_wb_stb_o,
		wb_wr_o		=> master_wb_wr_o,
		wb_addr_o	=> master_wb_addr_o,
		wb_data_o	=> master_wb_data_o,
		wb_data_i	=> master_wb_data_i,
		wb_ack_i		=> master_wb_ack_i,
		sdo			=> uart_tx,
		sdi			=> uart_rx
	);
	
	GPIO_MODULE: gpio 
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		wb_cyc_i		=> master_wb_cyc_o,
		wb_stb_i		=> gpio_en,
		wb_wr_i		=> master_wb_wr_o,
		wb_addr_i	=> gpio_addr,
		wb_data_i	=> master_wb_data_o(6 downto 0),
		wb_ack_o		=> gpio_wb_ack_o,
		wb_data_o	=> gpio_wb_data_o,
		leds			=> leds(6 downto 0),
		btns			=> btns,
		switches		=> switches
	);
	
	LED_BLINK_MODULE: led_blink 
	port map(
		clk_i	=> clk_i,
		rst_i	=> rst_i,
		led	=> leds(7)
	);
	
	GB_PHY_MDIO: mdio_if 
	port map(
		clk_i			=> clk_i,
		rst_i			=> rst_i,
		wb_cyc_i		=> master_wb_cyc_o,
		wb_stb_i		=> gb_phy_mdio_en,
		wb_wr_i		=> master_wb_wr_o,
		wb_addr_i	=> gb_phy_mdio_addr,
		wb_data_i	=> master_wb_data_o,
		wb_data_o	=> gb_phy_wb_data_o,
		wb_ack_o		=> gb_phy_wb_ack_o,
		pad_mdc		=> phy_mdc,
		pad_mdio		=> phy_mdio
	);	
	
	GB_MAC: gigabit_mac 
	port map(
		clk_i 		=> clk_i,
		rst_i 		=> rst_i,
		clk_gtx 		=> clk_gtx,
		wb_cyc_i 	=> master_wb_cyc_o,
		wb_stb_i 	=> gb_mac_en,
		wb_wr_i 		=> master_wb_wr_o,
		wb_addr_i 	=> gb_mac_addr,
		wb_data_i	=> master_wb_data_o,
		wb_data_o 	=> gb_mac_wb_data_o,
		wb_ack_o		=> gb_mac_wb_ack_o,
		gmii_tx_clk => phy_gmii_txc,
		gmii_tx_en 	=> phy_gmii_tx_ctl,
		gmii_txd 	=> phy_gmii_txd,
		gmii_tx_er 	=> phy_gmii_tx_er,
		gmii_rx_clk => phy_gmii_rxc,
		gmii_rx_dv 	=> phy_gmii_rx_dv,
		gmii_rxd 	=> phy_gmii_rxd,
		gmii_rx_er 	=> phy_gmii_rx_er
	);	
		
	
	master_wb_data_i <= "00000000" & gpio_wb_data_o when (gpio_sel = '1') else
							  gb_phy_wb_data_o when (gb_phy_mdio_sel = '1') else
							  gb_mac_wb_data_o when (gb_mac_sel = '1') else
							  (others=>'0');
							  
	master_wb_ack_i  <= gpio_wb_ack_o when (gpio_sel = '1') else
							  gb_phy_wb_ack_o when (gb_phy_mdio_sel = '1') else
							  gb_mac_wb_ack_o when (gb_mac_sel = '1') else
							  '0';							  
	
	
-- Address decoder
	-- GPIO slave decode
	gpio_sel <= '1' when (master_wb_addr_o(7 downto 2) = "000000") else '0';
	gpio_en <= master_wb_stb_o and gpio_sel;
	gpio_addr <= master_wb_addr_o(1 downto 0);
	
	-- PHY MDIO decode
	gb_phy_mdio_sel <= '1' when (master_wb_addr_o(7 downto 2) = "000001") else '0';
	gb_phy_mdio_en <= master_wb_stb_o and gb_phy_mdio_sel;
	gb_phy_mdio_addr <= master_wb_addr_o(1 downto 0);
	
	-- GB MAC decode
	gb_mac_sel <= '1' when ((master_wb_addr_o(7 downto 3) = "00001") or (master_wb_addr_o(7 downto 3) = "00010")) else '0';
	gb_mac_en <= master_wb_stb_o and gb_mac_sel;
	gb_mac_addr <= master_wb_addr_o(4 downto 0);
	

end rtl;

