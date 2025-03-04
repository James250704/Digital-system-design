library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab03_3 is
    Port ( SW : in STD_LOGIC_VECTOR (1 downto 0);
           HEX3 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX2 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX1 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX0 : out STD_LOGIC_VECTOR (6 downto 0));
end Lab03_3;

architecture Behavioral of Lab03_3 is
    constant BLANK : STD_LOGIC_VECTOR (6 downto 0) := "1111111";
    signal HEX3_sig, HEX2_sig, HEX1_sig, HEX0_sig : STD_LOGIC_VECTOR (6 downto 0);
begin
    with SW select
        HEX3_sig <= "0100001" when "00",  -- SW = 00, HEX3 shows 'd'
                    BLANK when others;
                    
    with SW select
        HEX2_sig <= "0000110" when "01",  -- SW = 01, HEX2 shows 'E'
                    BLANK when others;
                    
    with SW select
        HEX1_sig <= "1000000" when "10",  -- SW = 10, HEX1 shows '0'
                    BLANK when others;
                    
    with SW select
        HEX0_sig <= BLANK when others;  -- SW = 11, all HEXs are blank

    HEX3 <= HEX3_sig;
    HEX2 <= HEX2_sig;
    HEX1 <= HEX1_sig;
    HEX0 <= HEX0_sig;
end Behavioral;
