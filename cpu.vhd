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
	reset: in std_logic; -- Halt processor execution when '1'

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

	-- One word's worth of padding
	constant padding: std_logic_vector(data_width - 1 downto 0) := (others => '0');

	-- Aliases to improve readability

	alias slv is std_logic_vector;
	alias opcode: std_logic_vector(3 downto 0) is instruction_in(7 downto 4);
	alias immediate: std_logic_vector(3 downto 0) is instruction_in(3 downto 0);
	alias stack_top is mem_data_out(data_width - 1 downto 0);
	alias stack_2nd is mem_data_out(2*data_width - 1 downto data_width);
	alias stack_3rd is mem_data_out(3*data_width - 1 downto 2*data_width);
	alias stack_4th is mem_data_out(4*data_width - 1 downto 3*data_width);

	-- Auxiliaries to set initial values on control signals

	signal codec_inter_aux: std_logic := '0';
	signal codec_read_aux: std_logic := '0';
	signal codec_write_aux: std_logic := '0';
	signal mem_data_read_aux: std_logic := '0';
	signal mem_data_write_aux: std_logic := '0';

	-- Registers

	signal IP: unsigned(addr_width - 1 downto 0) := (others => '0');
	signal SP: unsigned(addr_width - 1 downto 0) := (others => '0');

	-- Operator overloads to improve readability

	function "+" (v1: slv; v2: slv) return slv is
	begin
		return slv(unsigned(v1) + unsigned(v2));
	end function;

	function "-" (v1: slv; v2: slv) return slv is
	begin
		return slv(unsigned(v1) - unsigned(v2));
	end function;

	function "<" (v1: slv; v2: slv) return slv is
		variable result: slv(data_width - 1 downto 0) := (others => '0');
	begin
		if unsigned(v1) < unsigned(v2) then
			result(0) := '1';
		end if;
		return result;
	end function;

	function "sll" (v1: slv; v2: slv) return slv is
	begin
		return slv(unsigned(v1) sll to_integer(unsigned(v2)));
	end function;

	function "srl" (v1: slv; v2: slv) return slv is
	begin
		return slv(unsigned(v1) srl to_integer(unsigned(v2)));
	end function;

begin

	-- Avoid undefined values on control signals
	codec_interrupt <= codec_inter_aux;
	codec_read <= codec_read_aux;
	codec_write <= codec_write_aux;
	mem_data_read <= mem_data_read_aux;
	mem_data_write <= mem_data_write_aux;
	instruction_addr <= slv(IP) when reset = '0' else (others => 'Z');

	exc: process is
	begin
		wait until rising_edge(clock) and reset = '0';

		case opcode is

			when "0000" =>  -- hlt
				-- Update registers
				IP <= (others => '0');
				SP <= (others => '0');

			when "0001" =>  -- in
				-- Read from input
				codec_read_aux <= '1';
				codec_inter_aux <= '1';
				wait on codec_inter_aux'transaction;
				codec_inter_aux <= '0';
				wait until falling_edge(codec_valid);
				codec_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP);
				mem_data_in <= slv(resize(unsigned(codec_data_out), data_width)) & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP + 1;

			when "0010" =>  -- out
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Write to output
				codec_data_in <= stack_top;
				codec_write_aux <= '1';
				codec_inter_aux <= '1';
				wait on codec_inter_aux'transaction;
				codec_inter_aux <= '0';
				wait until falling_edge(codec_valid);
				codec_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "0011" =>  -- puship
				-- Push onto stack
				mem_data_addr <= slv(SP);
				mem_data_in <= slv(IP);
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP + 2;

			when "0100" =>  -- push
				-- Push onto stack
				mem_data_addr <= slv(SP);
				mem_data_in <= slv(resize(unsigned(immediate), data_width)) & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP + 1;

			when "0101" =>  -- drop
				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "0110" =>  -- dup
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_in <= stack_top & stack_top;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP + 1;

			when "0111" =>  -- swp
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= stack_top & stack_2nd;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;

			when "1000" =>  -- add
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= stack_top + stack_2nd & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "1001" =>  -- sub
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= stack_top - stack_2nd & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "1010" =>  -- nand
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= (stack_top nand stack_2nd) & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "1011" =>  -- slt
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= (stack_top < stack_2nd) & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "1100" =>  -- shl
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= (stack_top sll stack_2nd) & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "1101" =>  -- shr
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Push onto stack
				mem_data_addr <= slv(SP - 2);
				mem_data_in <= (stack_top srl stack_2nd) & padding;
				mem_data_write_aux <= '1';
				wait until falling_edge(clock);
				mem_data_write_aux <= '0';

				-- Update registers
				IP <= IP + 1;
				SP <= SP - 1;

			when "1110" =>  -- beq
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Update registers
				if stack_top = stack_2nd then
					IP <= IP + unsigned(stack_4th & stack_3rd);
				else
					IP <= IP + 1;
				end if;
				SP <= SP - 4;

			when "1111" =>  -- jmp
				-- Pop from stack
				mem_data_addr <= slv(SP - 1);
				mem_data_read_aux <= '1';
				wait on mem_data_out'transaction;
				mem_data_read_aux <= '0';

				-- Update registers
				IP <= unsigned(stack_2nd & stack_top);
				SP <= SP - 2;

			when others =>
				report "Instruction decode error (opcode " &
					std_logic'image(opcode(3)) & std_logic'image(opcode(2)) &
					std_logic'image(opcode(1)) & std_logic'image(opcode(0)) & ")"
					severity failure;

		end case;
	end process;

end architecture;
