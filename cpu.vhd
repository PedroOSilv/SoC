library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
generic (
	addr_width: natural := 16; -- Memory Address Width (in bits)
	data_width: natural := 8 -- Data Width (in bits)
);
port (
	clock: in std_logic;
	halt: in std_logic; -- Halt processor execution when '1'

	---- Begin Memory Signals ---
	-- Instruction byte received from memory
	instruction_in: in std_logic_vector(data_width - 1 downto 0);
	-- Instruction address given to memory
	instruction_addr: out std_logic_vector(addr_width - 1 downto 0);

	mem_data_read: out std_logic; -- When '1', read data from memory
	mem_data_write: out std_logic; -- When '1', write data to memory
	-- Data address given to memory
	mem_data_addr: out std_logic_vector(addr_width - 1 downto 0);
	-- Data sent to memory when data_read = '0' and data_write = '1'
	mem_data_in: out std_logic_vector(2*data_width - 1 downto 0);
	-- Data sent from memory when data_read = '1' and data_write = '0'
	mem_data_out: in std_logic_vector(4*data_width - 1 downto 0);
	---- End Memory Signals ---

	---- Begin Codec Signals ---
	codec_interrupt: out std_logic; -- Interrupt signal
	codec_read: out std_logic; -- Read signal
	codec_write: out std_logic; -- Write signal
	codec_valid: in std_logic; -- Valid signal

	-- Byte written to codec
	codec_data_out: in std_logic_vector(7 downto 0);
	-- Byte read from codec
	codec_data_in: out std_logic_vector(7 downto 0)
	---- End Codec Signals ---
);
end entity;

architecture behavioral of cpu is

	alias slv is std_logic_vector;
	alias opcode: std_logic_vector(3 downto 0) is instruction_in(7 downto 4);
	alias immediate: std_logic_vector(3 downto 0) is instruction_in(3 downto 0);

begin

	process
		variable SP: unsigned(addr_width - 1 downto 0) := (others => '0');
		variable IP: unsigned(addr_width - 1 downto 0) := (others => '0');
	begin
		wait until rising_edge(clock);

		case opcode is

			when "0000" =>  -- hlt

			when "0001" =>  -- in

			when "0010" =>  -- out

			when "0011" =>  -- puship

			when "0100" =>  -- push

			when "0101" =>  -- drop

			when "0110" =>  -- dup

			when "1000" =>  -- add

			when "1001" =>  -- sub

			when "1010" =>  -- nand

			when "1011" =>  -- slt

			when "1100" =>  -- shl

			when "1101" =>  -- shr

			when "1110" =>  -- jeq

			when "1111" =>  -- jmp

			when others =>
				-- report "Illegal instruction (opcode '" & integer'image(to_integer(unsigned(opcode))) & "')";
				report "Illegal instruction (opcode '" &
					std_logic'image(opcode(3)) & std_logic'image(opcode(2)) &
					std_logic'image(opcode(1)) & std_logic'image(opcode(0)) & "')"
					severity failure;

		end case;

	end process;

end architecture;
