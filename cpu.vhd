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
				wait until falling_edge(halt);
				IP := (others => '0');
				SP := (others => '0');

			when "0001" =>  -- in
				-- Read byte from input
				codec_interrupt <= '1';
				wait until falling_edge(clock);
				codec_interrupt <= '0';
				codec_read <= '1';
				codec_write <= '0';
				wait until falling_edge(codec_valid);

				-- Push byte onto stack
				mem_data_read <= '0';
				mem_data_write <= '1';
				mem_data_in <= slv(resize(unsigned(codec_data_out), data_width))
				             & (data_width-1 downto 0 => '0');
				mem_data_addr <= slv(SP);

				SP := SP + 1;
				IP := IP + 1;

			when "0010" =>  -- out
				-- Pop byte from stack
				mem_data_read <= '1';
				mem_data_write <= '0';
				mem_data_addr <= slv(SP);

				-- Write byte to output
				codec_interrupt <= '1';
				wait until falling_edge(clock);
				codec_interrupt <= '0';
				codec_read <= '0';
				codec_write <= '1';
				codec_data_in <= mem_data_out(4*data_width-1 downto 3*data_width);
				wait until falling_edge(codec_valid);

				SP := SP - 1;
				IP := IP + 1;

			when "0011" =>  -- puship
				mem_data_read <= '0';
				mem_data_write <= '1';
				mem_data_in <= slv(IP);
				mem_data_addr <= slv(SP);

				SP := SP + 2;
				IP := IP + 1;

			when "0100" =>  -- push
				mem_data_read <= '0';
				mem_data_write <= '1';
				mem_data_in <= slv(resize(unsigned(immediate), data_width))
				             & (data_width-1 downto 0 => '0');
				mem_data_addr <= slv(SP);

				SP := SP + 1;
				IP := IP + 1;

			when "0101" =>  -- drop
				SP := SP - 1;
				IP := IP + 1;

			when "0110" =>  -- dup
				mem_data_read <= '1';
				mem_data_write <= '0';
				mem_data_addr <= slv(SP - 1);
				wait until falling_edge(clock);
				mem_data_read <= '0';
				mem_data_write <= '1';
				mem_data_addr <= slv(SP - 1);
				mem_data_in <= mem_data_out(4*data_width - 1 downto 3*data_width)
				             & mem_data_out(4*data_width - 1 downto 3*data_width);

				SP := SP + 1;
				IP := IP + 1;

			when "1000" =>  -- add
				IP := IP + 1;

			when "1001" =>  -- sub
				IP := IP + 1;

			when "1010" =>  -- nand
				IP := IP + 1;

			when "1011" =>  -- slt
				IP := IP + 1;

			when "1100" =>  -- shl
				IP := IP + 1;

			when "1101" =>  -- shr
				IP := IP + 1;

			when "1110" =>  -- jeq
				-- IP := ...

			when "1111" =>  -- jmp
				mem_data_read <= '1';
				mem_data_write <= '0';
				mem_data_addr <= slv(SP - 1);

				SP := SP - 2;
				IP := unsigned(mem_data_out(4*data_width - 1 downto 2*data_width));

			when others =>
				-- report "Illegal instruction (opcode '" & integer'image(to_integer(unsigned(opcode))) & "')";
				report "Illegal instruction (opcode '" &
					std_logic'image(opcode(3)) & std_logic'image(opcode(2)) &
					std_logic'image(opcode(1)) & std_logic'image(opcode(0)) & "')"
					severity failure;

		end case;

	end process;

end architecture;
