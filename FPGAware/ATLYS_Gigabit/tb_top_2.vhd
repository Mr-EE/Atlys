--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:22:43 07/13/2013
-- Design Name:   
-- Module Name:   E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/tb_top_2.vhd
-- Project Name:  ATLYS_Gigabit
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_top_2 IS
END tb_top_2;
 
ARCHITECTURE behavior OF tb_top_2 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         clk_in : IN  std_logic;
         hard_rst : IN  std_logic;
         leds : OUT  std_logic_vector(7 downto 0);
         btns : IN  std_logic_vector(4 downto 0);
         switches : IN  std_logic_vector(7 downto 0);
         phy_rst : OUT  std_logic;
         phy_mdc : OUT  std_logic;
         phy_mdio : INOUT  std_logic;
         phy_gmii_txc : OUT  std_logic;
         phy_gmii_tx_ctl : OUT  std_logic;
         phy_gmii_tx_er : OUT  std_logic;
         phy_gmii_txd : OUT  std_logic_vector(7 downto 0);
         phy_gmii_rxc : IN  std_logic;
         phy_gmii_rx_dv : IN  std_logic;
         phy_gmii_rx_er : IN  std_logic;
         phy_gmii_rxd : IN  std_logic_vector(7 downto 0);
         uart_rx : IN  std_logic;
         uart_tx : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_in : std_logic := '0';
   signal hard_rst : std_logic := '0';
   signal btns : std_logic_vector(4 downto 0) := (others => '0');
   signal switches : std_logic_vector(7 downto 0) := (others => '0');
   signal phy_gmii_rxc : std_logic := '0';
   signal phy_gmii_rx_dv : std_logic := '0';
   signal phy_gmii_rx_er : std_logic := '0';
   signal phy_gmii_rxd : std_logic_vector(7 downto 0) := (others => '0');
   signal uart_rx : std_logic := '0';

	--BiDirs
   signal phy_mdio : std_logic;

 	--Outputs
   signal leds : std_logic_vector(7 downto 0);
   signal phy_rst : std_logic;
   signal phy_mdc : std_logic;
   signal phy_gmii_txc : std_logic;
   signal phy_gmii_tx_ctl : std_logic;
   signal phy_gmii_tx_er : std_logic;
   signal phy_gmii_txd : std_logic_vector(7 downto 0);
   signal uart_tx : std_logic;

   -- Clock period definitions
   constant clk_in_period : time := 10 ns;
	constant phy_gmii_rxc_period : time := 8 ns;
	
	constant uart_bit_period : time := 7.8125 us;
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk_in => clk_in,
          hard_rst => hard_rst,
          leds => leds,
          btns => btns,
          switches => switches,
          phy_rst => phy_rst,
          phy_mdc => phy_mdc,
          phy_mdio => phy_mdio,
          phy_gmii_txc => phy_gmii_txc,
          phy_gmii_tx_ctl => phy_gmii_tx_ctl,
          phy_gmii_tx_er => phy_gmii_tx_er,
          phy_gmii_txd => phy_gmii_txd,
          phy_gmii_rxc => phy_gmii_rxc,
          phy_gmii_rx_dv => phy_gmii_rx_dv,
          phy_gmii_rx_er => phy_gmii_rx_er,
          phy_gmii_rxd => phy_gmii_rxd,
          uart_rx => uart_rx,
          uart_tx => uart_tx
        );

   -- Clock process definitions
   clk_in_process :process
   begin
		clk_in <= '0';
		wait for clk_in_period/2;
		clk_in <= '1';
		wait for clk_in_period/2;
   end process;
	
   phy_gmii_rxc_process :process
   begin
		phy_gmii_rxc <= '0';
		wait for phy_gmii_rxc_period/2;
		phy_gmii_rxc <= '1';
		wait for phy_gmii_rxc_period/2;
   end process;

	
   -- Stimulus process
   stim_proc: process
	
		procedure uart_wr(data: in std_logic_vector(7 downto 0)) is
		begin
			-- Start bit
			uart_rx <= '0';
			wait for uart_bit_period;
			
			-- Data
			uart_rx <= data(0);
			wait for uart_bit_period;
			uart_rx <= data(1);
			wait for uart_bit_period;
			uart_rx <= data(2);
			wait for uart_bit_period;
			uart_rx <= data(3);
			wait for uart_bit_period;
			uart_rx <= data(4);
			wait for uart_bit_period;
			uart_rx <= data(5);
			wait for uart_bit_period;
			uart_rx <= data(6);
			wait for uart_bit_period;
			uart_rx <= data(7);
			wait for uart_bit_period;
			
			-- Stop bit
			uart_rx <= '1';		
			wait for uart_bit_period;
		end procedure uart_wr;
		
		
		procedure baz_link_packet(	wr_rd	: in std_logic;
											address	: in std_logic_vector(7 downto 0); 
											data		: in std_logic_vector(15 downto 0)
											) is
			variable sof_type	: std_logic_vector(7 downto 0) := (others => '0');
		begin
			if (wr_rd = '1') then
				sof_type := "11001000"; -- SOF and wr_reg
			else
				sof_type := "11001001"; -- SOF and rd_reg
			end if;
			
			uart_wr(sof_type);
			uart_wr(address);
			uart_wr(data(15 downto 8));
			uart_wr(data(7 downto 0));

		end procedure baz_link_packet;
		
		procedure gmii_rx_packet(data : in integer) is
		begin
			for I in 0 to 9 loop
				wait until rising_edge(phy_gmii_rxc);
				phy_gmii_rx_dv <= '1';
				phy_gmii_rxd <= std_logic_vector(TO_UNSIGNED(data + I, phy_gmii_rxd'length));
			end loop;
			
			wait until rising_edge(phy_gmii_rxc);
			phy_gmii_rx_dv <= '0';
			phy_gmii_rxd <= X"00";

		end procedure gmii_rx_packet;
		
	
	
   begin		
		hard_rst <= '0';
	   wait for 400ns;
		hard_rst <= '1';
	   wait for 1000ns;
		
	   baz_link_packet('1', "00001001", X"000A"); -- Packet length
		baz_link_packet('1', "00001010", X"0008"); -- IFG length
		baz_link_packet('1', "00001011", X"0003"); -- Max packets to send
		baz_link_packet('1', "00001000", X"0003"); -- Enable TX and RX generation/reception

		wait for 100ns;
		
		-- Simulate transactions on the receive end
		gmii_rx_packet(0);
		wait for phy_gmii_rxc_period*8;
		gmii_rx_packet(16);
		wait for phy_gmii_rxc_period*8;
		gmii_rx_packet(32);
		wait for phy_gmii_rxc_period*8;
		gmii_rx_packet(48);
		wait for phy_gmii_rxc_period*8;
		gmii_rx_packet(64);
		wait for phy_gmii_rxc_period*8;
		
		wait for 100ns;
		
		baz_link_packet('1', "00001000", X"0000"); -- Disable TX and RX generation/reception
		
		baz_link_packet('1', "00010100", X"0002"); -- Set RX BRAM address to 2 and read RX bram
		baz_link_packet('0', "00010110", X"0000"); -- Read RX BRAM address 2
		baz_link_packet('1', "00010100", X"000F"); -- Set RX BRAM address to 15 and read RX bram
		baz_link_packet('0', "00010110", X"0000"); -- Read RX BRAM address 15
		
		baz_link_packet('1', "00010100", "0100000000000000"); -- Set RX IFG BRAM address to 0 and read RX ifg bram
		baz_link_packet('0', "00010110", X"0000"); -- Read RX ifg BRAM address 0
		baz_link_packet('1', "00010100", "0100000000000001"); -- Set RX IFG BRAM address to 1 and read RX ifg bram
		baz_link_packet('0', "00010110", X"0000"); -- Read RX ifg BRAM address 1
		baz_link_packet('1', "00010100", "0100000000000010"); -- Set RX IFG BRAM address to 2 and read RX ifg bram
		baz_link_packet('0', "00010110", X"0000"); -- Read RX ifg BRAM address 2
		
		baz_link_packet('1', "00010101", X"9876"); -- Set TX BRAM data to 0x9876
		baz_link_packet('1', "00010100", "1010000000000000"); -- Set TX BRAM address to 0 and write to TX bram
		
		baz_link_packet('1', "00001000", X"0001"); -- Enable TX generation
		
		
      wait;
   end process;

END;
