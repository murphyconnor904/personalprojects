--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_extend is
    port (
        input : in std_logic_vector(15 downto 0);
        is_signed : in std_logic;
        output : out std_logic_vector(31 downto 0)
    );
end sign_extend;

architecture behavioral of sign_extend is
begin
    process(input, is_signed)
    begin
        if is_signed = '1' then
            -- Perform sign extension
            output <= std_logic_vector(resize(signed(input), 32));
        else
            -- Perform zero extension
            output <= std_logic_vector(resize(unsigned(input), 32));
        end if;
    end process;
end behavioral;