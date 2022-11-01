library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity awg is
    generic(
        phase_acc_width :   integer := 22;
        rom_data_width  :   integer := 12;
        rom_addr_with   :   integer := 16
    );
    port (
        clk             :   in      std_logic;
        n_rst           :   in      std_logic;
        enable_dds      :   in      std_logic;
        enable_ftw      :   in      std_logic;
        ftw             :   in      unsigned(phase_acc_width - 1 downto 0);
        data            :   out     unsigned(rom_data_width - 1 downto 0)
    );
end entity awg;

architecture rtl of awg is

    -- Build a 2-D array type for the ROM
	subtype word_t is std_logic_vector(rom_data_width - 1 downto 0);
	type memory_t is array(2**rom_addr_with - 1 downto 0) of word_t;

    -- Function to init tho ROM
    function init_rom return memory_t is 
		variable tmp : memory_t := (others => (others => '0'));
	begin 
		for addr_pos in 0 to 2**rom_addr_with - 1 loop 
			-- Initialize each address with the address itself
			tmp(addr_pos) := std_logic_vector(to_unsigned(addr_pos, rom_data_width));
		end loop;
		return tmp;
	end init_rom;

    -- Signals
    signal phase_acc    :   unsigned(phase_acc_width - 1 downto 0);
    signal frequency    :   unsigned(phase_acc_width - 1 downto 0);
    signal rom          :   memory_t := init_rom;
    signal rom_addr     :   
    
begin

    -- frequency register
    freq_reg: process(clk, n_rst)
    begin
         if n_rst = '0' then
            frequency <= (others => '0');
         elsif rising_edge(clk) then
            if enable_ftw = '1' then
                frequency <= ftw;
            end if;
         end if;
    end process freq_reg;
    
    -- Phase Accumulator
    phase_accumulator: process(clk, n_rst)
    begin
        if n_rst = '0' then
            phase_acc <= (others => '0');
        elsif rising_edge(clk) then
            if enable_dds = '1' then
                phase_acc <= phase_acc + ftw;
            end if;
        end if;
    end process phase_acc;

    rom_process: process(clk)
        begin
            if rising_edge(clk) then
                data <= rom(to_integer(phase_acc()));
            end if;
        end process rom_process;
    
end architecture rtl;