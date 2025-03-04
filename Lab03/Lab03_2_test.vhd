library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab02_2_test is
    Port ( SW : in STD_LOGIC_VECTOR (1 downto 0);
           HEX3 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX2 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX1 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX0 : out STD_LOGIC_VECTOR (6 downto 0));
end Lab02_2_test;

architecture Behavioral of Lab02_2_test is
begin
    process(SW)
    begin
        case SW is
            when "00" =>  -- SW = 00, HEX3 shows 'd', others are blank
                HEX3 <= "0100001";
                HEX2 <= "1111111";
                HEX1 <= "1111111";
                HEX0 <= "1111111";
            when "01" =>  -- SW = 01, HEX2 shows 'E', others are blank
                HEX3 <= "1111111";
                HEX2 <= "0000110";
                HEX1 <= "1111111";
                HEX0 <= "1111111";
            when "10" =>  -- SW = 10, HEX1 shows '0', others are blank
                HEX3 <= "1111111";
                HEX2 <= "1111111";
                HEX1 <= "1000000";
                HEX0 <= "1111111";
            when others =>  -- SW = 11, all HEXs are blank
                HEX3 <= "1111111";
                HEX2 <= "1111111";
                HEX1 <= "1111111";
                HEX0 <= "1111111";
        end case;
    end process;
end Behavioral;
