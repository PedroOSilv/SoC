library ieee;
use ieee.std_logic_1164.all;

entity tb_memory is
	generic (
		addr_width : natural := 16;
		data_width : natural := 8
	);
end entity;

architecture tb of tb_memory is
	signal clock: std_logic := '0';
	signal data_read: std_logic := '0';
	signal data_write: std_logic := '0';
	signal data_addr: std_logic_vector(addr_width - 1 downto 0) := (others => '0');
	signal data_in: std_logic_vector((2*data_width) - 1 downto 0) := (others => '0');
	signal data_out: std_logic_vector((4*data_width) - 1 downto 0) := (others => '0');
begin

	ent: entity work.codec(ram)
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

	stimulus: process 
	begin

	end process;

end architecture;
