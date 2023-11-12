library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
	generic (
		addr_width: natural := 16; -- Memory Address Width (in bits)
		data_width: natural := 8 -- Data Width (in bits)
	);
	port (
		clock: in std_logic; -- Clock signal; Write on Falling-Edge
		data_read: in std_logic; -- When '1', read data from memory
		data_write: in std_logic; -- When '1', write data to memory
		-- Data address given to memory
		data_addr: in std_logic_vector(addr_width - 1 downto 0);
		-- Data sent to memory when data_read = '0' and data_write = '1'
		data_in: in std_logic_vector(2*data_width - 1 downto 0);
		-- Data sent from memory when data_read = '1' and data_write = '0'
		data_out: out std_logic_vector(4*data_width - 1 downto 0)
	);
end entity;

architecture ram of memory is

	subtype mem_row is std_logic_vector(data_width-1 downto 0);
	type mem_array is array (natural range<>) of mem_row;

	-- -3 accomodates for overrun if first byte is read
	-- +1 accomodates for overrun if last byte is written to
	signal mem: mem_array(-3 to 2**addr_width -1 +1) := (others => (-3 to -1 => 'U', others => '0'));
	signal data_addr_int: natural;
begin

	data_addr_int <= to_integer(unsigned(data_addr));

	dr: process (clock)
	begin
		if rising_edge(clock) and data_read = '1' then

			data_out <= mem(data_addr_int)
			          & mem(data_addr_int - 1)
			          & mem(data_addr_int - 2)
			          & mem(data_addr_int - 3);
		end if;
	end process;

	dw: process (clock)
	begin
		if falling_edge(clock) and data_write = '1' then
			mem(data_addr_int + 1) <= data_in(2*data_width - 1 downto data_width);
			mem(data_addr_int)     <= data_in(data_width - 1 downto 0);
		end if;
	end process;

end architecture;
