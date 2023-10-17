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
	file firmware: text;
begin

	read_data: process is
		variable instruction: line;
		variable logvec: std_logic_vector(7 downto 0);
	begin
		file_open(firmware, firmware_filename, read_mode);

		while not endfile(firmware) loop
			readline(firmware, instruction);
			for i in logvec'range loop
				if instruction(i) = '1' then
					logvec(i) := '1';
				elsif instruction(i) = '0' then
					logvec(i) := '0';
				end if;
				codec_data_out <= logvec;
			end loop;
		end loop;

		wait;
	end process;

end architecture;
