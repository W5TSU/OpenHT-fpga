-------------------------------------------------------------
-- Serial FIR channel filter
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity fir_channel_12_5 is
	generic(
		TAPS_NUM	: integer := 81;
		SAMP_WIDTH	: integer := 16
	);
	port(
		clk_i		: in std_logic;											-- fast clock in
		data_i		: in signed(SAMP_WIDTH-1 downto 0);						-- data in
		data_o		: out signed(SAMP_WIDTH-1 downto 0) := (others => '0');	-- data out
		trig_i		: in std_logic;											-- trigger in
		drdy_o		: out std_logic := '0'									-- data ready out
	);
end fir_channel_12_5;

architecture magic of fir_channel_12_5 is
	type arr_sig_t is array(integer range 0 to TAPS_NUM-1) of signed(SAMP_WIDTH-1 downto 0);
	constant taps : arr_sig_t := (
		x"FF10", x"0248", x"0199", x"00D0",
		x"FFA2", x"FE9F", x"FE85", x"FF92",
		x"012D", x"0230", x"01B3", x"FFCD",
		x"FDB3", x"FCFD", x"FE78", x"0164",
		x"03C3", x"03AA", x"00BC", x"FCBB",
		x"FA87", x"FC23", x"0101", x"05FC",
		x"0747", x"0334", x"FBDA", x"F639",
		x"F704", x"FF07", x"09BA", x"0F77",
		x"0A65", x"FB3E", x"EA93", x"E51E",
		x"F4AF", x"19A0", x"48F2", x"7092",
		x"7FFF", x"7092", x"48F2", x"19A0",
		x"F4AF", x"E51E", x"EA93", x"FB3E",
		x"0A65", x"0F77", x"09BA", x"FF07",
		x"F704", x"F639", x"FBDA", x"0334",
		x"0747", x"05FC", x"0101", x"FC23",
		x"FA87", x"FCBB", x"00BC", x"03AA",
		x"03C3", x"0164", x"FE78", x"FCFD",
		x"FDB3", x"FFCD", x"01B3", x"0230",
		x"012D", x"FF92", x"FE85", x"FE9F",
		x"FFA2", x"00D0", x"0199", x"0248",
		x"FF10"
	);
	
	signal dline : arr_sig_t := (others => (others => '0'));

	signal p_trig, pp_trig : std_logic := '0';
	signal busy : std_logic := '0';
	signal mac : signed(integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH-1 downto 0) := (others => '0');
	signal mul : signed(2*SAMP_WIDTH-1 downto 0) := (others => '0');
begin
	process(clk_i)
		variable counter : integer range 0 to TAPS_NUM+1 := 0;
	begin
		if rising_edge(clk_i) then
			p_trig <= trig_i;
			pp_trig <= p_trig;

			-- detect rising edge at the trig input
			if pp_trig='0' and p_trig='1' then
				-- update data register
				dline <= dline(1 to TAPS_NUM-1) & data_i;
				-- zero all stuff
				counter := 0;
				mul <= (others => '0');
				mac <= resize(data_i * taps(TAPS_NUM-1), integer(ceil(log2(real(TAPS_NUM))))+2*SAMP_WIDTH);
				-- assert busy flag
				busy <= '1';
			end if;

			if busy='1' then
				if counter=TAPS_NUM then
					-- output result
					data_o <= mac(2*SAMP_WIDTH-1 downto SAMP_WIDTH);
					-- deassert busy flag
					busy <= '0';
					-- zero the counter
					counter := 0;
				else
					-- perform some arithmetic
					mul <= dline(counter) * taps(counter);
					mac <= mac + mul;
					-- update the counter
					counter := counter + 1;
				end if;
			end if;
		end if;
	end process;

	drdy_o <= not busy;
end magic;
