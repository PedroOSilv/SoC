library ieee;
use ieee.std_logic_1164.all;

entity tb_soc is
end entity;

architecture tb of tb_soc is
	constant cycles_boot: positive := 6;  -- Length of firmware
	constant cycles_run: positive := 5;  -- Expected run time

	signal end_test: std_logic := '0';
	signal started: std_logic := '0';
	signal clock: std_logic := '0';
	signal nflips: natural := 0;

begin

	ent: entity work.soc(mixed)
	generic map (
		firmware_filename => "firmware.bin"
	)
	port map (
		clock => clock,
		started => started
	);

	clk: process is
	begin
		while end_test = '0' loop
			clock <= not clock;
			nflips <= nflips + 1;
			wait for 500 ps;
		end loop;
		wait;
	end process;

	ctl: process is
	begin
		report "Test started";

		report "Bootup phase";
		wait until nflips/2 >= cycles_boot;

		wait until rising_edge(clock);
		started <= '1';
		report "Execution phase";
		wait until nflips/2 >= cycles_boot + cycles_run;

		wait until falling_edge(clock);
		started <= '0';
		end_test <= '1';
		report "Test ended successfully";
		wait;
	end process;

end architecture;
