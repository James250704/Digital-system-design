library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab03_4 is
    Port ( SW : in STD_LOGIC_VECTOR (1 downto 0);
           HEX3 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX2 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX1 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX0 : out STD_LOGIC_VECTOR (6 downto 0));
end Lab03_4;

architecture Behavioral of Lab03_4 is
    constant BLANK : STD_LOGIC_VECTOR (6 downto 0) := "1111111";
begin
    HEX3 <= "0100001" when SW = "00" else BLANK;  -- SW = 00, HEX3 shows 'd'
    HEX2 <= "0000110" when SW = "01" else BLANK;  -- SW = 01, HEX2 shows 'E'
    HEX1 <= "1000000" when SW = "10" else BLANK;  -- SW = 10, HEX1 shows '0'
    HEX0 <= BLANK;  -- SW = 11, all HEXs are blank
end Behavioral;
