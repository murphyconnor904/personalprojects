--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_4to1 is
    generic (WIDTH : positive := 32);
    port (
        sel : in std_logic_vector(1 downto 0);
        in0 : in std_logic_vector(WIDTH-1 downto 0);
        in1 : in std_logic_vector(WIDTH-1 downto 0);
        in2 : in std_logic_vector(WIDTH-1 downto 0);
        in3 : in std_logic_vector(WIDTH-1 downto 0);
        output : out std_logic_vector(WIDTH-1 downto 0)
    );
end mux_4to1;

architecture behavioral of mux_4to1 is
begin
    with sel select
        output <= in0 when "00",
                in1 when "01",
                in2 when "10",
                in3 when "11";
end behavioral;