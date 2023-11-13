library ieee;
use ieee.std_logic_1164.all;

entity soc is
	generic (
		firmware_filename: string := "firmware.bin";
		addr_width: natural := 16;
		data_width: natural := 8
	);
	port (
		clock: in std_logic; -- Clock signal
		started: in std_logic -- Start execution when '1'
	);
end entity;

architecture mixed of soc is

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

	-- signal imem_read: std_logic := '0';   -- soc -> imem
	signal imem_write: std_logic := '0';  -- soc -> imem
	signal imem_addr: std_logic_vector(addr_width - 1 downto 0);  -- cpu -> imem
	signal imem_in: std_logic_vector(data_width - 1 downto 0);    -- soc -> imem
	signal imem_out: std_logic_vector(data_width - 1 downto 0);   -- imem -> cpu

begin

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
		clock => clock,
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
		data_in => imem_in,
		data_out => imem_out
	);

	cpu: entity work.cpu(behavioral)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => clock,
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
	begin
		wait until rising_edge(started);

		-- TODO load firmware to imem

		wait;
	end process;

end architecture;
