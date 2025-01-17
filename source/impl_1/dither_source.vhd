-------------------------------------------------------------
-- LSFR-based dither source for an NCO in FM mode
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dither_source is
    port(
        clk_i	: in  std_logic;
		ena		: in std_logic;
		trig_i	: in std_logic;
        out_o	: out signed(15 downto 0) := (others => '0')
    );
end entity;

architecture magic of dither_source is
	signal dline : std_logic_vector(15 downto 0) := x"1717";
	signal feedback : std_logic := '0';
begin
	feedback <= dline(15) xor dline(13) xor dline(12) xor dline(10);

	process(trig_i)
	begin
		if rising_edge(trig_i) then
			dline <= dline(14 downto 0) & feedback; -- rotate left and update
		end if;
	end process;
	
	process(clk_i)
	begin
		if ena='1' then
			if rising_edge(clk_i) then
				out_o <= resize(signed(dline(7 downto 0)), 16);
			end if;
		else
			out_o <= (others => '0');
		end if;
	end process;
end architecture;

-- old architecture
-------------------------------------------------------------
-- Dither source for an NCO in FM mode
--
-- x[0] = seed
-- x[n+1] = (m * x[n] + p) mod 0xFFFF
-- (p = 7)
--
-- This approach gives uniform probability density
-- of the generated numbers sequence
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

--entity dither_source is
    --port(
        --clk_i		: in  std_logic;
		--ena		: in std_logic;
		--trig_i	: in std_logic;
        --out_o		: out signed(15 downto 0) := (others => '0')
    --);
--end entity;

--architecture magic of dither_source is
	--constant m		: unsigned(7 downto 0) := x"2F";
	--signal tmp1		: unsigned(15 downto 0) := x"0080"; --seed
	--signal tmp2		: unsigned(15+8 downto 0) := x"000080"; --seed
	--signal ptrg		: std_logic := '0';
	--signal pptrg	: std_logic := '0';
--begin
	--process(clk_i)
	--begin
		--if rising_edge(clk_i) then
			--ptrg <= trig_i;
			--pptrg <= ptrg;

			--if (pptrg='0' and ptrg='1') or (pptrg='1' and ptrg='0') then
				--tmp2 <= m * tmp1 + 7;
				--tmp1 <= tmp2(15 downto 0);
			--end if;
		--end if;
	--end process;

	--process(trig_i, ena)
	--begin
		--if ena='1' then
			--if rising_edge(trig_i) then
				--out_o <= resize(signed(tmp1(15 downto 8)), 16);
			--end if;
		--else
			--out_o <= (others => '0');
		--end if;
	--end process;
--end architecture;
