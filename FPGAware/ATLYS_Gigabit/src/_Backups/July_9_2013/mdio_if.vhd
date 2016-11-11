----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:28:20 11/03/2012 
-- Design Name: 
-- Module Name:    mdio_if - RTL 
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

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library work;
use work.constants.all;

entity mdio_if is
	Port 
	( 
-- Wishbone Interface
		clk_i 		: in std_logic;
		rst_i 		: in std_logic;

		wb_cyc_i 	: in std_logic;
		wb_stb_i 	: in std_logic;	
		--wb_sel_i 	: in std_logic;
		wb_wr_i 		: in std_logic;
		wb_addr_i 	: in std_logic_vector (1 downto 0);
		wb_data_i 	: in std_logic_vector (15 downto 0);
		
		wb_data_o 	: out std_logic_vector (15 downto 0);
		wb_ack_o 	: out std_logic;		

-- MDIO interface
		pad_mdc	 	: out std_logic;
		pad_mdio		: inout std_logic
	);
end mdio_if;

architecture rtl of mdio_if is

-- Wishbone signals
	signal wb_rd_req			: std_logic := '0'; 
   signal wb_wr_req			: std_logic := '0';
	signal wb_int_ack_o		: std_logic := '0';

	-- Core internal registers
	signal reg_ctrl			: std_logic_vector(0 downto 0) := (others => '0'); 
	signal reg_addr			: std_logic_vector(10 downto 0) := (others => '0');
	signal reg_wr_data		: std_logic_vector(15 downto 0) := (others => '0'); 
	signal reg_rd_data		: std_logic_vector(15 downto 0) := (others => '0'); 
	
-- MDIO interface signals
   signal mdio_clk_int		: std_logic := '0';
   signal not_mdio_clk_int	: std_logic := '0';
   signal mdio_clk_int_dly	: std_logic := '0';
	signal mdio_start			: std_logic := '0';
	--signal mdio_enable		: std_logic := '0';
	signal mdio_busy			: std_logic := '0';
	signal mdio_int_i			: std_logic := '0';
	signal mdio_int_o			: std_logic := '0';
	signal mdio_sel			: std_logic := '0';
	
	signal mdio_wr_req		: std_logic := '0'; --_vector(1 downto 0) := (others => '0');
	signal mdio_opcode		: std_logic_vector(1 downto 0) := (others => '0');
	signal mdio_phy_addr		: std_logic_vector(4 downto 0) := (others => '0');
	signal mdio_reg_addr		: std_logic_vector(4 downto 0) := (others => '0');
	signal mdio_ctrl_packet	: std_logic_vector(13 downto 0) := (others => '0');
	signal mdio_wr_data		: std_logic_vector(16 downto 0) := (others => '0'); -- 16 bits + 1 turnaround bit
	signal mdio_rd_data		: std_logic_vector(16 downto 0) := (others => '0'); -- 16 bits + 1 turnaround bit
	
   type mdio_state_type is (st0_idle, st1_sendctrlpacket, st2_senddatapacket, st3_receivedatapacket); 
	signal mdio_state			: mdio_state_type := st0_idle;

begin

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
					when "00" 	=> wb_data_o	<= "000000000000000" & reg_ctrl;
					when "01" 	=> wb_data_o	<= "00000" & reg_addr;
					when "10" 	=> wb_data_o	<= reg_wr_data;
					when "11" 	=> wb_data_o	<= reg_rd_data;
					when others	=> wb_data_o 					<= (others => '0');
				end case;
			end if;     
      end if;
   end process;
	
	-- Wishbone write process. Slave will store data to internal registers based on address/data from master	
	WB_WRITE: process (clk_i, rst_i)
   begin
		if (rst_i = '1') then
			--reg_ctrl(10 downto 0) <= (others => '0');
			reg_addr <= (others => '0');
			reg_wr_data <= (others => '0');
			mdio_start <= '0';
      elsif rising_edge(clk_i) then
         if (wb_wr_req = '1' and wb_int_ack_o = '0' and mdio_busy = '0') then
				case wb_addr_i(1 downto 0) is
					--when "00" 	=> reg_ctrl(0)	<= wb_data_i(0); -- d.1 is not writable
					when "01" 	=> reg_addr		<= wb_data_i(10 downto 0);
										mdio_start 	<= '1'; -- writing to the address reg will trigger a read/write
					when "10" 	=> reg_wr_data	<= wb_data_i(15 downto 0);
					when others	=> null;
				end case;
			else
				mdio_start <= '0';
			end if;
      end if;
   end process;



-- MDIO Interface ----------------------------------------------------------------

	-- Register decoding
	reg_ctrl(0) <= mdio_busy;
	mdio_wr_req <= reg_addr(10);
	mdio_phy_addr <= reg_addr(9 downto 5);
	mdio_reg_addr <= reg_addr(4 downto 0);
	
	
	-- MDIO packet structure (sof, preamble, and turnaround are defined in signal declerations section)
	mdio_opcode <= "01" when (mdio_wr_req = '1') else "10";
	mdio_ctrl_packet <= MDIO_SOF & mdio_opcode & mdio_phy_addr & mdio_reg_addr;
	mdio_wr_data <= '0' & reg_wr_data; -- second turnaround bit plus data to write
	reg_rd_data <= mdio_rd_data(15 downto 0);
	
	-- MDIO physical routing
	pad_mdio <= mdio_int_o when mdio_sel = '1' else 'Z';
	mdio_int_i <= pad_mdio;
	
	-- Since MDC is a clock it is always better to output clocks from the FPGa with a ODDR
	not_mdio_clk_int <= not(mdio_clk_int);

	MDC_ODDR2 : oddr2
	generic map
	(
		ddr_alignment => "none",
		init => '0',
		srtype => "sync"
	)
	port map 
	(
		q => pad_mdc,
		c0 => mdio_clk_int,
		c1 => not_mdio_clk_int,
		ce => '1',
		d0 => '0',
		d1 => '1',
		r => rst_i,
		s => open
	);
	
	-- MDIO divide process. This process divides down the bus clk for MDIO interface clock. The 
	--  process has an enable which can be used to update the clock divide ratio. 
	MDIO_CLK_DIVIDE: process(clk_i, rst_i)
		constant oversample_value	: integer := (CLOCK_RATE/(MDIO_RATE));
		variable cnt					: integer range 0 to oversample_value := 0;
	begin
		if rst_i = '1' then
			cnt := 0;
			mdio_clk_int <= '0';
		elsif rising_edge(clk_i) then
			if (cnt = oversample_value) then
				mdio_clk_int <= not(mdio_clk_int);
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;
	
	-- MDIO state machine
	MDIO_INTERFACE: process (clk_i, rst_i)
		variable packet_end	: std_logic;
		variable bitpos		: integer range 0 to 31;
   begin
		if (rst_i = '1') then
			bitpos := 0;
			packet_end := '0';
			mdio_busy <= '0';
			mdio_sel <= '0';
			mdio_int_o <= '0';
			mdio_state <= st0_idle;
      elsif rising_edge(clk_i) then
			mdio_clk_int_dly <= mdio_clk_int;
			
			if (mdio_start = '1' or mdio_busy = '1') then
				
				mdio_busy <= '1';

				if (mdio_clk_int = '1' and mdio_clk_int_dly = '0') then
					case (mdio_state) is
						-- Idle (we need at least one idle time between transfers)
						when st0_idle =>
							bitpos := 0;
							packet_end := '0';
							mdio_sel <= '0';
							mdio_int_o <= '0';
							
							if (mdio_busy = '1') then
								mdio_state <= st1_sendctrlpacket;
							else
								mdio_state <= st0_idle;
							end if;
							
						-- Send out control packet serially to MDIO interface
						when st1_sendctrlpacket =>
							if (packet_end = '1') then
								packet_end := '0';
								if (mdio_wr_req = '1') then
									mdio_int_o <= '1'; -- First turnaround bit
									mdio_sel <= '1';
									mdio_state <= st2_senddatapacket;
								else
									mdio_int_o <= '0'; -- First turnaround bit
									mdio_sel <= '0';
									mdio_state <= st3_receivedatapacket;
								end if;
							else
								if (bitpos = MDIO_WR_CTRL_LEN) then
									bitpos := 0;
									packet_end := '1';
									mdio_int_o <= mdio_ctrl_packet(0); -- write the last bit
									mdio_state <= st1_sendctrlpacket;
								else
									mdio_int_o <= mdio_ctrl_packet(MDIO_WR_CTRL_LEN - bitpos);
									mdio_sel <= '1';
									bitpos := bitpos + 1;
									mdio_state <= st1_sendctrlpacket;
								end if;
							end if;
							
						-- Send out data packet serially to MDIO interface
						when st2_senddatapacket =>
							if (packet_end = '1') then
								packet_end := '0';
								mdio_int_o <= '0';
								mdio_sel <= '0';
								mdio_busy <= '0';
								mdio_state <= st0_idle;
							else
								if (bitpos = MDIO_WR_DATA_LEN) then
									bitpos := 0;
									packet_end := '1';
									mdio_int_o <= mdio_wr_data(0); -- write the last bit
									mdio_sel <= '1';
									mdio_state <= st2_senddatapacket;
								else
									mdio_int_o <= mdio_wr_data(MDIO_WR_DATA_LEN - bitpos);
									mdio_sel <= '1';
									bitpos := bitpos + 1;
									mdio_state <= st2_senddatapacket;
								end if;
							end if;						
							
						-- Receive data packet serially from MDIO interface
						when st3_receivedatapacket =>	
							if (packet_end = '1') then
								packet_end := '0';
								mdio_int_o <= '0';
								mdio_sel <= '0';
								mdio_busy <= '0';
								mdio_state <= st0_idle;
							else
								if (bitpos = MDIO_RD_DATA_LEN) then
									bitpos := 0;
									packet_end := '1';
									mdio_rd_data(0) <= mdio_int_i; -- read last bit
									mdio_sel <= '0';
									mdio_state <= st3_receivedatapacket;
								else
									mdio_rd_data(MDIO_RD_DATA_LEN - bitpos) <= mdio_int_i;
									mdio_sel <= '0';
									bitpos := bitpos + 1;
									mdio_state <= st3_receivedatapacket;
								end if;
							end if;	

						-- Default --
						when others =>
							mdio_int_o <= '0';
							mdio_sel <= '0';
							mdio_busy <= '0';
							bitpos := 0;
							packet_end := '0';
							mdio_state <= st0_idle;
					end case;
				end if;
			end if;
      end if;
   end process;

end rtl;

