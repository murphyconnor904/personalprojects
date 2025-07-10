--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk : in std_logic;
        reset : in std_logic;
        read_reg1 : in std_logic_vector(4 downto 0);
        read_reg2 : in std_logic_vector(4 downto 0);
        write_reg : in std_logic_vector(4 downto 0);
        write_data : in std_logic_vector(31 downto 0);
        reg_write : in std_logic;
		  jump_and_link : in std_logic;
        read_data1 : out std_logic_vector(31 downto 0);
        read_data2 : out std_logic_vector(31 downto 0)
    );
end register_file;

architecture behavioral of register_file is
    -- Define register array type (32 registers of 32 bits each)
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    
    -- Register array signal (initialized to all zeros)
    signal registers : reg_array := (others => (others => '0'));
    
begin
    -- Write process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all registers to 0
            for i in 0 to 31 loop
                registers(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            -- Write operation (make sure register 0 is always 0)
            if reg_write = '1' and unsigned(write_reg) /= 0 then
                registers(to_integer(unsigned(write_reg))) <= write_data;
            end if;
        end if;
    end process;
    
    -- Read operations (asynchronous)
    -- Read port 1
    read_data1 <= registers(to_integer(unsigned(read_reg1)));
    
    -- Read port 2
    read_data2 <= registers(to_integer(unsigned(read_reg2)));
    
end behavioral;