library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_processor_tb is
end mips_processor_tb;

architecture behavioral of mips_processor_tb is
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
    -- Component declaration for the Unit Under Test (UUT)
    component del4_top_level
        port (
            clk              : in std_logic;
            reset            : in std_logic;
            InPort0_en       : in std_logic;
            InPort1_en       : in std_logic;
            InPort0_in       : in std_logic_vector(9 downto 0);
            InPort1_in       : in std_logic_vector(9 downto 0);
            OutPort_out      : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal InPort0_en : std_logic := '0';
    signal InPort1_en : std_logic := '0';
    signal InPort0_in : std_logic_vector(9 downto 0) := (others => '0');
    signal InPort1_in : std_logic_vector(9 downto 0) := (others => '0');
    
    -- Outputs
    signal OutPort_out : std_logic_vector(31 downto 0);
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: del4_top_level
        port map (
            clk => clk,
            reset => reset,
            InPort0_en => InPort0_en,
            InPort1_en => InPort1_en,
            InPort0_in => InPort0_in,
            InPort1_in => InPort1_in,
            OutPort_out => OutPort_out
        );
    
    -- Clock process definitions
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state for 20 ns
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        
        -- Modify input values to test processor response
        InPort0_in <= "0111111111";  -- 0x1FF
        InPort0_en <= '1';
        wait for clk_period;
        InPort0_en <= '0';

        -- Wait for processor to execute program
        wait for 1000 ns;
        
        -- Continue simulation
        wait for 1000 ns;
        
        -- End simulation
        assert false report "Simulation ended" severity failure;
    end process;
end behavioral;