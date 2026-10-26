library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Lab04_2 is
    port (
        SW   : in STD_LOGIC_VECTOR (5 downto 0);
        KEY  : in STD_LOGIC_VECTOR (1 downto 0);
        LEDG : out STD_LOGIC_VECTOR (3 downto 0);
        HEX0 : out STD_LOGIC_VECTOR (6 downto 0);
        HEX1 : out STD_LOGIC_VECTOR (6 downto 0)
    );
end entity;

architecture Behavioral of Lab04_2 is
    signal A   : unsigned (2 downto 0);
    signal B   : unsigned (2 downto 0);
    signal SUM : unsigned (3 downto 0);

    constant BLANK : STD_LOGIC_VECTOR (6 downto 0) := "1111111";

begin
    A   <= unsigned(SW(5 downto 3));
    B   <= unsigned(SW(2 downto 0));
    SUM <= ('0' & A) + ('0' & B);

    process (KEY)
    begin
        if KEY = "11" then
            LEDG <= "0000";
            HEX0 <= BLANK;
            HEX1 <= BLANK;

        elsif KEY = "10" then -- Button0 pressed
            LEDG <= "0000";

            case SUM is
                when "0000" => HEX0 <= "1000000"; HEX1 <= BLANK;     --0
                when "0001" => HEX0 <= "1111001"; HEX1 <= BLANK;     --1
                when "0010" => HEX0 <= "0100100"; HEX1 <= BLANK;     --2
                when "0011" => HEX0 <= "0110000"; HEX1 <= BLANK;     --3
                when "0100" => HEX0 <= "0011001"; HEX1 <= BLANK;     --4
                when "0101" => HEX0 <= "0010010"; HEX1 <= BLANK;     --5
                when "0110" => HEX0 <= "0000010"; HEX1 <= BLANK;     --6
                when "0111" => HEX0 <= "1111000"; HEX1 <= BLANK;     --7
                when "1000" => HEX0 <= "0000000"; HEX1 <= BLANK;     --8
                when "1001" => HEX0 <= "0010000"; HEX1 <= BLANK;     --9
                when "1010" => HEX0 <= "1000000"; HEX1 <= "1111001"; --10
                when "1011" => HEX0 <= "1111001"; HEX1 <= "1111001"; --11
                when "1100" => HEX0 <= "0100100"; HEX1 <= "1111001"; --12
                when "1101" => HEX0 <= "0110000"; HEX1 <= "1111001"; --13
                when "1110" => HEX0 <= "0011001"; HEX1 <= "1111001"; --14
                when others => HEX0 <= BLANK; HEX1 <= BLANK;
            end case;

        elsif KEY = "01" then -- Button1 pressed
            LEDG <= STD_LOGIC_VECTOR(SUM);
            HEX0 <= BLANK;
            HEX1 <= BLANK;

        else
            LEDG <= "0000";
            HEX0 <= BLANK;
            HEX1 <= BLANK;
        end if;

    end process;

end architecture;
