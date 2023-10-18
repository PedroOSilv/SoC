library ieee, std;
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

	-- Input
	process (interrupt) is
		variable datum_vec: bit_vector(7 downto 0);
		variable datum_str: line;
		variable good: boolean;
	begin
		if rising_edge(interrupt) and read_signal = '1' then
			if endfile(input) then
				codec_data_out <= "UUUUUUUU";
			else
				readline(input, datum_str);
				read(datum_str, datum_vec, good);
				if good then
					codec_data_out <= to_stdlogicvector(datum_vec);
					pulse_valid <= '1';
				else
					codec_data_out <= "XXXXXXXX";
				end if;
			end if;
		end if;
	end process;

	-- Output
	process (interrupt)
		variable datum_vec: bit_vector(7 downto 0);
		variable datum_str: line;
	begin
		if rising_edge(interrupt) and write_signal = '1' then
			datum_vec := to_bitvector(codec_data_in);
			write(datum_str, datum_vec);
			writeline(output, datum_str);
			pulse_valid <= '1';
		end if;
	end process;

	-- Pulse the signal `valid` without a clock
	process
	begin
		while true loop
			wait until pulse_valid = '1';
			valid <= '1';
			pulse_valid <= '0';
			wait until pulse_valid = '0';
			valid <= '0';
		end loop;
	end process;

end architecture;
