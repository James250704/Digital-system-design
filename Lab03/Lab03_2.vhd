library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Lab03_2 is
    Port ( SW : in STD_LOGIC_VECTOR (1 downto 0);
           HEX3 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX2 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX1 : out STD_LOGIC_VECTOR (6 downto 0);
           HEX0 : out STD_LOGIC_VECTOR (6 downto 0));
end Lab03_2;

architecture Behavioral of Lab03_2 is
    component Lab03_1
        Port ( SW : in STD_LOGIC_VECTOR (1 downto 0);
               HEX0 : out STD_LOGIC_VECTOR (6 downto 0));
    end component;
    
    signal HEX0_internal : STD_LOGIC_VECTOR (6 downto 0);
    constant BLANK : STD_LOGIC_VECTOR (6 downto 0) := "1111111";
begin
    U1: Lab03_1 port map (SW => SW, HEX0 => HEX0_internal);

    process(SW, HEX0_internal)
    begin
        case SW is
            when "00" =>  -- SW = 00, HEX3 shows 'd', others are blank
                HEX3 <= HEX0_internal;
                HEX2 <= BLANK;
                HEX1 <= BLANK;
                HEX0 <= BLANK;
            when "01" =>  -- SW = 01, HEX2 shows 'E', others are blank
                HEX3 <= BLANK;
                HEX2 <= HEX0_internal;
                HEX1 <= BLANK;
                HEX0 <= BLANK;
            when "10" =>  -- SW = 10, HEX1 shows '0', others are blank
                HEX3 <= BLANK;
                HEX2 <= BLANK;
                HEX1 <= HEX0_internal;
                HEX0 <= BLANK;
            when others =>  -- SW = 11, all HEXs are blank
                HEX3 <= BLANK;
                HEX2 <= BLANK;
                HEX1 <= BLANK;
                HEX0 <= BLANK;
        end case;
    end process;
end Behavioral;
