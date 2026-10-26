library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity Lab04_1 is
    port (
        SW   : in STD_LOGIC_VECTOR(3 downto 0);
        HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
        HEX1 : out STD_LOGIC_VECTOR(6 downto 0)
    );
end Lab04_1;

architecture Behavioral of Lab04_1 is
    constant BLANK : STD_LOGIC_VECTOR(6 downto 0) := "1111111";
begin
    process (SW)
    begin
        case SW is
            when "0000" => HEX0 <= "1000000"; --0
            when "0001" => HEX0 <= "1111001"; --1
            when "0010" => HEX0 <= "0100100"; --2
            when "0011" => HEX0 <= "0110000"; --3
            when "0100" => HEX0 <= "0011001"; --4
            when "0101" => HEX0 <= "0010010"; --5
            when "0110" => HEX0 <= "0000010"; --6
            when "0111" => HEX0 <= "1111000"; --7
            when "1000" => HEX0 <= "0000000"; --8
            when "1001" => HEX0 <= "0010000"; --9
            when "1010" => HEX0 <= "1000000"; --10
            when "1011" => HEX0 <= "1111001"; --11
            when "1100" => HEX0 <= "0100100"; --12
            when "1101" => HEX0 <= "0110000"; --13
            when "1110" => HEX0 <= "0011001"; --14
            when "1111" => HEX0 <= "0010010"; --15
            when others => HEX0 <= BLANK;
        end case;
    end process;

    process (SW)
    begin
        if SW >= "1010" then
            HEX1 <= "1111001"; --10 to 15
        else
            HEX1 <= BLANK; --0 to 9
        end if;
    end process;

end Behavioral;
