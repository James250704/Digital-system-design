library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Lab06_2 is
    port (
        KEY  : in STD_LOGIC_VECTOR(2 downto 1);
        SW   : in STD_LOGIC_VECTOR(7 downto 0);
        LEDG : out STD_LOGIC_VECTOR(9 downto 0)
    );
end Lab06_2;

architecture Behavioral of Lab06_2 is
    signal temp_reg     : signed(7 downto 0) := (others => '0');
    signal acc_reg      : signed(7 downto 0) := (others => '0');
    signal overflow_reg : STD_LOGIC          := '0';
begin

    process (KEY(2), KEY(1))
        variable sum : signed(7 downto 0);
    begin
        if (KEY(1) = '0') then
            temp_reg     <= (others => '0');
            acc_reg      <= (others => '0');
            overflow_reg <= '0';
        elsif rising_edge(KEY(2)) then
            sum := acc_reg + temp_reg;
            acc_reg  <= sum;
            temp_reg <= signed(SW);
            if (acc_reg(7) = temp_reg(7)) and (sum(7) /= acc_reg(7)) then
                overflow_reg <= '1';
            else
                overflow_reg <= '0';
            end if;
        end if;
    end process;

    LEDG(7 downto 0) <= STD_LOGIC_VECTOR(acc_reg);
    LEDG(9)          <= overflow_reg;
    LEDG(8)          <= '0';

end Behavioral;
