library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab02_2 is
    Port ( 
        SW : in STD_LOGIC_VECTOR (3 downto 0);
        LEDG0 : out STD_LOGIC_VECTOR (0 to 0);
        HEX0 : out STD_LOGIC_VECTOR (6 downto 0)
    );
end Lab02_2;

architecture Behavioral of Lab02_2 is
begin
    process(SW)
    begin
        case SW is
            when "0010" => LEDG0 <= '1'; 
            when "0011" => LEDG0 <= '1'; 
            when "0101" => LEDG0 <= '1'; 
            when "0111" => LEDG0 <= '1'; 
            when "1011" => LEDG0 <= '1'; 
            when "1101" => LEDG0 <= '1'; 
            when others => LEDG0 <= '0'; 
        end case;
        
        case SW is
            when "0000" => HEX0 <= "1000000"; -- 0
            when "0001" => HEX0 <= "1111001"; -- 1
            when "0010" => HEX0 <= "0100100"; -- 2
            when "0011" => HEX0 <= "0110000"; -- 3
            when "0100" => HEX0 <= "0011001"; -- 4
            when "0101" => HEX0 <= "0010010"; -- 5
            when "0110" => HEX0 <= "0000010"; -- 6
            when "0111" => HEX0 <= "1111000"; -- 7
            when "1000" => HEX0 <= "0000000"; -- 8
            when "1001" => HEX0 <= "0010000"; -- 9
            when "1010" => HEX0 <= "0001000"; -- 10
            when "1011" => HEX0 <= "0000011"; -- 11
            when "1100" => HEX0 <= "1000110"; -- 12
            when "1101" => HEX0 <= "0100001"; -- 13
            when "1110" => HEX0 <= "0000110"; -- 14
            when "1111" => HEX0 <= "0001110"; -- 15
            when others => HEX0 <= "1111111"; -- Error
        end case;
    end process;
end Behavioral;