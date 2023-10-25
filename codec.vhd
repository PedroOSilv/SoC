library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity codec is
	port (
		interrupt: in std_logic; -- Interrupt signal
		read_signal: in std_logic; -- Read signal
		write_signal: in std_logic; -- Write signal
		valid: out std_logic; -- Valid signal

		-- Byte written to codec
		codec_data_in: in std_logic_vector(7 downto 0);
		-- Byte read from codec
		codec_data_out: out std_logic_vector(7 downto 0)
	);
end entity;

architecture behavioral of codec is

	file input: text open read_mode is "input.txt";
	file output: text open write_mode is "output.txt";
	signal pulse_valid: std_logic := '0';

begin

	valid <= pulse_valid;

	process

		variable datum_vec: bit_vector(7 downto 0);
		variable datum_str: line;
		variable good: boolean;

	begin

		wait until falling_edge(interrupt);

		-- Input
		if read_signal = '1' and write_signal = '0' then
			if endfile(input) then
				codec_data_out <= "UUUUUUUU";
			else
				readline(input, datum_str);
				read(datum_str, datum_vec, good);
				if good then
					codec_data_out <= to_stdlogicvector(datum_vec);
					pulse_valid <= '1', '0' after 1 ns;
				else
					codec_data_out <= "XXXXXXXX";
				end if;
			end if;
		-- Output
		elsif read_signal = '0' and write_signal = '1' then
			datum_vec := to_bitvector(codec_data_in);
			write(datum_str, datum_vec);
			writeline(output, datum_str);
			pulse_valid <= '1', '0' after 1 ns;
		end if;

	end process;

end architecture;
