--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity memory_module_tb is
end memory_module_tb;

architecture behavioral of memory_module_tb is
    -- Component Declaration for the Memory Module
    component memory_module
        port (
            clk          : in std_logic;
            reset        : in std_logic;
            addr         : in std_logic_vector(31 downto 0);
            data_in      : in std_logic_vector(31 downto 0);
            data_out     : out std_logic_vector(31 downto 0);
            mem_read     : in std_logic;
            mem_write    : in std_logic;
            inport0_in   : in std_logic_vector(31 downto 0);
            inport0_en   : in std_logic;
            inport1_in   : in std_logic_vector(31 downto 0);
            inport1_en   : in std_logic;
            outport      : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Test Bench Signals
    constant CLK_PERIOD : time := 10 ns;
    
    -- Inputs
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal data_in      : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_read     : std_logic := '0';
    signal mem_write    : std_logic := '0';
    signal inport0_in   : std_logic_vector(31 downto 0) := (others => '0');
    signal inport0_en   : std_logic := '0';
    signal inport1_in   : std_logic_vector(31 downto 0) := (others => '0');
    signal inport1_en   : std_logic := '0';
    
    -- Outputs
    signal data_out     : std_logic_vector(31 downto 0);
    signal outport      : std_logic_vector(31 downto 0);
    
    -- Helper function to convert std_logic_vector to hex string
    function to_hex_string(signal_in : std_logic_vector) return string is
        variable hex_val : string(1 to signal_in'length/4);
        variable val : std_logic_vector(3 downto 0);
        variable index : integer := 1;
    begin
        for i in (signal_in'length/4) downto 1 loop
            val := signal_in(4*i-1 downto 4*i-4);
            case val is
                when "0000" => hex_val(index) := '0';
                when "0001" => hex_val(index) := '1';
                when "0010" => hex_val(index) := '2';
                when "0011" => hex_val(index) := '3';
                when "0100" => hex_val(index) := '4';
                when "0101" => hex_val(index) := '5';
                when "0110" => hex_val(index) := '6';
                when "0111" => hex_val(index) := '7';
                when "1000" => hex_val(index) := '8';
                when "1001" => hex_val(index) := '9';
                when "1010" => hex_val(index) := 'A';
                when "1011" => hex_val(index) := 'B';
                when "1100" => hex_val(index) := 'C';
                when "1101" => hex_val(index) := 'D';
                when "1110" => hex_val(index) := 'E';
                when "1111" => hex_val(index) := 'F';
                when others => hex_val(index) := 'X';
            end case;
            index := index + 1;
        end loop;
        return hex_val;
    end function;
    
    -- Helper Procedure for Printing Results
    procedure print_test_case(test_name : string) is
    begin
        report "------------------------------------------------------";
        report "Test Case: " & test_name;
        report "Address: 0x" & to_hex_string(addr);
        if mem_read = '1' then
            report "Data Out: 0x" & to_hex_string(data_out);
        end if;
        if mem_write = '1' then
            report "Data In: 0x" & to_hex_string(data_in);
        end if;
        report "------------------------------------------------------";
    end procedure;
    
    -- Memory-mapped I/O addresses
    constant INPORT0_ADDR : std_logic_vector(31 downto 0) := x"0000FFF8";
    constant INPORT1_ADDR : std_logic_vector(31 downto 0) := x"0000FFFC";
    constant OUTPORT_ADDR : std_logic_vector(31 downto 0) := x"0000FFFC";
    
begin
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Instantiate the Unit Under Test (UUT)
    uut: memory_module
        port map (
            clk => clk,
            reset => reset,
            addr => addr,
            data_in => data_in,
            data_out => data_out,
            mem_read => mem_read,
            mem_write => mem_write,
            inport0_in => inport0_in,
            inport0_en => inport0_en,
            inport1_in => inport1_in,
            inport1_en => inport1_en,
            outport => outport
        );
        
    -- Stimulus process
    stimulus_proc: process
    begin
        -- Initialize with reset
        reset <= '1';
        wait for CLK_PERIOD*2;
        reset <= '0';
        -- Wait a bit longer for RAM operations to complete
        wait for CLK_PERIOD;
        
        -- 1. Write 0x0A0A0A0A to byte address 0x00000000
        addr <= x"00000000";
        data_in <= x"0A0A0A0A";
        mem_write <= '1';
        mem_read <= '0';
        wait for CLK_PERIOD;
        print_test_case("Write 0x0A0A0A0A to address 0x00000000");
        mem_write <= '0';
        wait for CLK_PERIOD;
        
        -- 2. Write 0xF0F0F0F0 to byte address 0x00000004
        addr <= x"00000004";
        data_in <= x"F0F0F0F0";
        mem_write <= '1';
        mem_read <= '0';
        wait for CLK_PERIOD;
        print_test_case("Write 0xF0F0F0F0 to address 0x00000004");
        mem_write <= '0';
        wait for CLK_PERIOD;
        
        -- 3. Read from byte address 0x00000000
        addr <= x"00000000";
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        print_test_case("Read from address 0x00000000");
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- 4. Read from byte address 0x00000001 (should read same as 0x00000000 due to word alignment)
        addr <= x"00000001";
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        print_test_case("Read from address 0x00000001");
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- 5. Read from byte address 0x00000004
        addr <= x"00000004";
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        print_test_case("Read from address 0x00000004");
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- 6. Read from byte address 0x00000005 (should read same as 0x00000004 due to word alignment)
        addr <= x"00000005";
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        print_test_case("Read from address 0x00000005");
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- 7. Write 0x00001111 to the outport
        addr <= OUTPORT_ADDR;
        data_in <= x"00001111";
        mem_write <= '1';
        mem_read <= '0';
        wait for CLK_PERIOD;
        print_test_case("Write 0x00001111 to outport");
        mem_write <= '0';
        wait for CLK_PERIOD;
        report "Outport value: 0x" & to_hex_string(outport);
        
        -- 8. Load 0x00010000 into inport 0
        inport0_in <= x"00010000";
        inport0_en <= '1';
        wait for CLK_PERIOD;
        print_test_case("Load 0x00010000 into inport 0");
        inport0_en <= '0';
        wait for CLK_PERIOD;
        
        -- 9. Load 0x00000001 into inport 1
        inport1_in <= x"00000001";
        inport1_en <= '1';
        wait for CLK_PERIOD;
        print_test_case("Load 0x00000001 into inport 1");
        inport1_en <= '0';
        wait for CLK_PERIOD;
        
        -- 10. Read from inport 0
        addr <= INPORT0_ADDR;
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        print_test_case("Read from inport 0");
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- 11. Read from inport 1
        addr <= INPORT1_ADDR;
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        print_test_case("Read from inport 1");
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- End simulation
        report "Simulation completed successfully";
        wait;
    end process stimulus_proc;
end behavioral;