library ieee;
use ieee.std_logic_1164.all;

entity tb_memory is
	generic (
		addr_width: natural := 16;
		data_width: natural := 8
	);
end entity;

architecture tb of tb_memory is

	signal clock: std_logic := '0';
	signal data_read: std_logic := '0';
	signal data_write: std_logic := '0';
	signal data_addr: std_logic_vector(addr_width - 1 downto 0) := (others => '0');
	signal data_in: std_logic_vector(2*data_width - 1 downto 0) := (others => '0');
	signal data_out: std_logic_vector(4*data_width - 1 downto 0) := (others => '0');
	signal halt : std_logic := '0';

begin

	ent: entity work.memory(ram)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => clock,
		data_read => data_read,
		data_write => data_write,
		data_addr => data_addr,
		data_in => data_in,
		data_out => data_out
	);

	clk: process is
	begin
		while halt = '0' loop
			clock <= not clock;
			wait on halt for 1 ns;
		end loop;
		wait;
	end process;

	stimulus: process is
	begin
		report "Test started";

		wait until rising_edge(clock);

		data_read <= '0';
		data_write <= '1';
		data_addr <= x"0000";
		data_in <= x"89AB";

		wait until rising_edge(clock);

		data_addr <= x"0002";
		data_in <= x"CDEF";

		wait until falling_edge(clock);

		data_read <= '1';
		data_write <= '0';
		data_addr <= x"0000";

		wait until falling_edge(clock);

		assert data_out = x"89ABCDEF" report "Data read not the same as data written";

		data_read <= '0';

		report "Test ended successfully";
		halt <= '1';
		wait;
	end process;

end architecture;
