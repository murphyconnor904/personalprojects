--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_module is
    port (
        clk          : in std_logic;
        reset        : in std_logic;
        -- Memory interface
        addr         : in std_logic_vector(31 downto 0);
        data_in      : in std_logic_vector(31 downto 0);
        data_out     : out std_logic_vector(31 downto 0);
        mem_read     : in std_logic;
        mem_write    : in std_logic;
        -- Input port 0 interface
        inport0_in   : in std_logic_vector(31 downto 0);
        inport0_en   : in std_logic;
        -- Input port 1 interface
        inport1_in   : in std_logic_vector(31 downto 0);
        inport1_en   : in std_logic;
        -- Output port interface
        outport      : out std_logic_vector(31 downto 0)
    );
end memory_module;

architecture behavioral of memory_module is
    -- Constants for memory-mapped I/O addresses
    constant INPORT0_ADDR : std_logic_vector(31 downto 0) := x"0000FFF8";
    constant INPORT1_ADDR : std_logic_vector(31 downto 0) := x"0000FFFC";
    constant OUTPORT_ADDR : std_logic_vector(31 downto 0) := x"0000FFFC";
    
    -- Registers for I/O ports
    signal inport0_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal inport1_reg : std_logic_vector(31 downto 0) := (others => '0');
    signal outport_reg : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Signals for RAM interface
    signal ram_data_out : std_logic_vector(31 downto 0);
    signal ram_wren     : std_logic;
    
    -- Address decoding signals
    signal is_ram      : std_logic;
    signal is_inport0  : std_logic;
    signal is_inport1  : std_logic;
    signal is_outport  : std_logic;
    
begin

    --Output RAM Component
    ram_inst: entity work.RAM
    port map (
        address => addr(9 downto 2),
        clock => clk,
        data => data_in,
        wren => ram_wren,
        q => ram_data_out
    );
    
    -- Address decoding logic
    -- RAM is mapped to first 1KB (256 words * 4 bytes)
    is_ram <= '1' when unsigned(addr) < 1024 else '0';
    is_inport0 <= '1' when addr = INPORT0_ADDR else '0';
    is_inport1 <= '1' when addr = INPORT1_ADDR else '0';
    is_outport <= '1' when addr = OUTPORT_ADDR else '0';
    
    -- Write enable for RAM
    ram_wren <= mem_write and is_ram;
    
    -- Process to handle I/O ports
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset output register but NOT input ports
            outport_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Input port 0 register
            if inport0_en = '1' then
                inport0_reg <= inport0_in;
            end if;
            
            -- Input port 1 register
            if inport1_en = '1' then
                inport1_reg <= inport1_in;
            end if;
            
            -- Output port register (write from CPU to output port)
            if mem_write = '1' and is_outport = '1' then
                outport_reg <= data_in;
            end if;
        end if;
    end process;
    
    -- Output multiplexer for memory reads
    process(mem_read, is_ram, is_inport0, is_inport1, ram_data_out, inport0_reg, inport1_reg)
    begin
        -- Default output
        data_out <= (others => '0');
        
        if mem_read = '1' then
            if is_ram = '1' then
                data_out <= ram_data_out;
            elsif is_inport0 = '1' then
                data_out <= inport0_reg;
            elsif is_inport1 = '1' then
                data_out <= inport1_reg;
            end if;
        end if;
    end process;
    
    -- Connect output port register to output
    outport <= outport_reg;
    
end behavioral;