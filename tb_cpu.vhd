library ieee;
use ieee.std_logic_1164.all;

entity tb_cpu is
end entity;

architecture tb of tb_cpu is
	constant addr_width : natural := 16;
	constant data_width : natural := 8;

	signal clock: std_logic := '0';
	signal halt: std_logic := '0';

	signal instruction_in: std_logic_vector(data_width - 1 downto 0);
	signal instruction_addr: std_logic_vector(addr_width - 1 downto 0);

	signal mem_data_read: std_logic := '0';
	signal mem_data_write: std_logic := '0';
	signal mem_data_addr: std_logic_vector(addr_width - 1 downto 0);
	signal mem_data_in: std_logic_vector(2*data_width - 1 downto 0);
	signal mem_data_out: std_logic_vector(4*data_width - 1 downto 0);

	signal codec_interrupt: std_logic;
	signal codec_read: std_logic;
	signal codec_write: std_logic;
	signal codec_valid: std_logic := '0';
	signal codec_data_out: std_logic_vector(7 downto 0);
	signal codec_data_in: std_logic_vector(7 downto 0);

begin

	ent: entity work.cpu(behavioral)
	generic map (
		addr_width => addr_width,
		data_width => data_width
	)
	port map (
		clock => clock,
		halt => halt,
		instruction_in => instruction_in,
		instruction_addr => instruction_addr,
		mem_data_read => mem_data_read,
		mem_data_write => mem_data_write,
		mem_data_addr => mem_data_addr,
		mem_data_in => mem_data_in,
		mem_data_out => mem_data_out,
		codec_interrupt => codec_interrupt,
		codec_read => codec_read,
		codec_write => codec_write,
		codec_valid => codec_valid,
		codec_data_out => codec_data_out,
		codec_data_in => codec_data_in
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

		-- TODO test

		report "Test ended successfully";
		halt <= '1';
		wait;
	end process;

end architecture;
