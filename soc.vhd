library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity soc is
	generic (
		firmware_filename: string := "firmware.bin"
	);
	port (
		clock: in std_logic; -- Clock signal
		started: in std_logic -- Start execution when '1'
	);
end entity;

architecture mixed of soc is

	constant addr_width: natural := 16;
	constant data_width: natural := 8;

	signal ctrl_clock: std_logic;

	signal codec_inter: std_logic := '0';  -- cpu -> codec
	signal codec_read: std_logic := '0';   -- cpu -> codec
	signal codec_write: std_logic := '0';  -- cpu -> codec
	signal codec_valid: std_logic := '0';  -- codec -> cpu
	signal codec_data_in: std_logic_vector(7 downto 0);   -- cpu -> codec
	signal codec_data_out: std_logic_vector(7 downto 0);  -- codec -> cpu

	signal dmem_read: std_logic := '0';   -- cpu -> dmem
	signal dmem_write: std_logic := '0';  -- cpu -> dmem
	signal dmem_addr: std_logic_vector(addr_width - 1 downto 0);   -- cpu -> dmem
	signal dmem_in: std_logic_vector(2*data_width - 1 downto 0);   -- cpu -> dmem
	signal dmem_out: std_logic_vector(4*data_width - 1 downto 0);  -- dmem -> cpu

	signal imem_write: std_logic := '0';  -- soc -> imem
	signal imem_addr: std_logic_vector(addr_width - 1 downto 0);  -- soc,cpu -> imem
	signal imem_in: std_logic_vector(data_width - 1 downto 0);    -- soc -> imem
	signal imem_out: std_logic_vector(data_width - 1 downto 0);   -- imem -> cpu

begin

	ctrl_clock <= clock and started;

	codec: entity work.codec(behavioral)
	port map (
		interrupt => codec_inter,
		read_signal => codec_read,
		write_signal => codec_write,
		valid => codec_valid,
		codec_data_in => codec_data_in,
		codec_data_out => codec_data_out
	);

	dmem: entity work.memory(ram)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => ctrl_clock,
		data_read => dmem_read,
		data_write => dmem_write,
		data_addr => dmem_addr,
		data_in => dmem_in,
		data_out => dmem_out
	);

	imem: entity work.memory(ram)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => clock,
		data_read => clock,
		data_write => imem_write,
		data_addr => imem_addr,
		data_in(2*data_width - 1 downto data_width) => (others => '0'),
		data_in(data_width - 1 downto 0) => imem_in,
		data_out(4*data_width - 1 downto 3*data_width) => imem_out
	);

	cpu: entity work.cpu(behavioral)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => ctrl_clock,
		halt => "not"(started),
		codec_interrupt => codec_inter,
		codec_read => codec_read,
		codec_write => codec_write,
		codec_valid => codec_valid,
		codec_data_out => codec_data_out,
		codec_data_in => codec_data_in,
		mem_data_read => dmem_read,
		mem_data_write => dmem_write,
		mem_data_addr => dmem_addr,
		mem_data_in => dmem_in,
		mem_data_out => dmem_out,
		instruction_in => imem_out,
		instruction_addr => imem_addr
	);

	load: process is
		file firmware: text open read_mode is firmware_filename;
		variable instruction_str: line;
		variable instruction_bv: bit_vector(data_width - 1 downto 0);
		variable address: unsigned(addr_width - 1 downto 0) := (others => '0');
		variable good: boolean;
	begin

		while not endfile(firmware) loop
			readline(firmware, instruction_str);
			read(instruction_str, instruction_bv, good);
			assert good
				report "Failed to read firmware at address " & integer'image(to_integer(address))
				severity failure;

			wait until rising_edge(clock);

			imem_write <= '1';
			imem_addr <= std_logic_vector(address);
			imem_in <= to_stdlogicvector(instruction_bv);

			wait until falling_edge(clock);

			address := address + 1;
		end loop;

		wait;
	end process;

end architecture;
