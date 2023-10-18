library ieee, std;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_codec is
end entity;

architecture tb of tb_codec is
	signal interrupt: std_logic := '0';
	signal read_signal: std_logic := '0';
	signal write_signal: std_logic := '0';
	signal valid: std_logic := '0';
	signal codec_data: std_logic_vector(7 downto 0);
begin

	ent: entity work.codec(behavioral)
	port map (
		interrupt => interrupt,
		read_signal => read_signal,
		write_signal => write_signal,
		valid => valid,
		codec_data_in => codec_data,
		codec_data_out => codec_data
	);

	-- This test will copy the input to the output
	stimulus: process is
	begin
		while true loop

			-- Read from input
			read_signal <= '1';
			write_signal <= '0';
			interrupt <= '1', '0' after 1 ns;

			wait on valid, codec_data;

			assert codec_data /= "XXXXXXXX"
				report "Invalid data received from input";

			if codec_data = "UUUUUUUU" then
				exit;
			end if;

			-- Write to output
			read_signal <= '0';
			write_signal <= '1';
			interrupt <= '1', '0' after 1 ns;

			wait until falling_edge(valid);
		end loop;
	end process;

end architecture;
