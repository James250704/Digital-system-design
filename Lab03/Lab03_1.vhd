library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab03_1 is
    Port ( SW : in STD_LOGIC_VECTOR (1 downto 0);
           HEX0 : out STD_LOGIC_VECTOR (6 downto 0));
end Lab03_1;

architecture Behavioral of Lab03_1 is
begin
    process(SW)
    begin
        case SW is
            when "00" =>  -- Display character for SW = 00 d
                HEX0 <= "0100001";
            when "01" =>  -- Display character for SW = 01 E
                HEX0 <= "0000110";
            when "10" =>  -- Display character for SW = 10 0
                HEX0 <= "1000000";
            when others =>  -- Display blank for SW = 11
                HEX0 <= "1111111";
        end case;
    end process;
end Behavioral;