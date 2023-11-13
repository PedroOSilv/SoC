library ieee;
use ieee.std_logic_1164.all;

entity tb_soc is
end entity;

architecture tb of tb_soc is
	constant addr_width: natural := 16;
	constant data_width: natural := 8;

	signal clock: std_logic := '0';
	signal started : std_logic := '0';

begin

	ent: entity work.soc(mixed)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => clock,
		started => started
	);

	clk: process is
	begin
		wait until started = '1';

		while started = '1' loop
			clock <= not clock;
			wait on started for 1 ns;
		end loop;
		wait;
	end process;

	stimulus: process is
	begin
		report "Test started";

		-- TODO

		report "Test ended successfully";
		started <= '0';
		wait;
	end process;

end architecture;
