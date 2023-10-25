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

	clock <= not clock after 1 ns;

	stimulus: process is
	begin
		report "Test started";

		data_read <= '0';
		data_write <= '1';
		data_addr <= "0000000000000000";
		data_in <=   "1111111111111111";

		wait until falling_edge(clock);

		data_addr <= "0000000000000010";
		data_in <=   "1010101010101010";

		wait until falling_edge(clock);

		data_read <= '1';
		data_write <= '0';
		data_addr <= "0000000000000000";

		wait until falling_edge(clock);

		assert data_out = "11111111111111111010101010101010" report "Error";

		wait for 10 ns;

		assert false report "Test ended successfully" severity failure;

	end process;

end architecture;
