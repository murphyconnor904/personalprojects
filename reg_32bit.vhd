--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_32bit is
    port (
        clk : in std_logic;
        reset : in std_logic;
        enable : in std_logic;
        d : in std_logic_vector(31 downto 0);
        q : out std_logic_vector(31 downto 0)
    );
end reg_32bit;

architecture behavioral of reg_32bit is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                q <= d;
            end if;
        end if;
    end process;
end behavioral;