--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_2to1 is
    generic (WIDTH : positive := 32);
    port (
        sel : in std_logic;
        in0 : in std_logic_vector(WIDTH-1 downto 0);
        in1 : in std_logic_vector(WIDTH-1 downto 0);
        output : out std_logic_vector(WIDTH-1 downto 0)
    );
end mux_2to1;

architecture behavioral of mux_2to1 is
begin
    output <= in0 when sel = '0' else in1;
end behavioral;