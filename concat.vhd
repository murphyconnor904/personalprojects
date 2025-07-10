--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity concat is
    port (
        input1 : in std_logic_vector(27 downto 0);
		  input2 : in std_logic_vector(3 downto 0);
        output : out std_logic_vector(31 downto 0)
    );
end concat;

architecture behavioral of concat is
    -- Placeholder
begin
    -- Placeholder
end behavioral;