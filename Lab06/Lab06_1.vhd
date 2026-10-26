library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Lab06_1 is
    port (
        KEY  : in STD_LOGIC_VECTOR(2 downto 1);
        HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
        HEX3 : out STD_LOGIC_VECTOR(6 downto 0)
    );
end Lab06_1;

architecture Behavioral of Lab06_1 is
    signal count_signal  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal count_var_sig : STD_LOGIC_VECTOR(3 downto 0) := "0000";

    component decoder is
        port (
            digit : in STD_LOGIC_VECTOR(3 downto 0);
            seg   : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
begin
    process (KEY(2), KEY(1))
        variable count_var : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    begin
        if KEY(1) = '0' then
            count_signal <= "0000";
            count_var := "0000";
            count_var_sig <= "0000";
        elsif rising_edge(KEY(2)) then
            if count_signal = "1001" then
                count_signal <= "0000";
            else
                count_signal <= STD_LOGIC_VECTOR(unsigned(count_signal) + 1);
            end if;
            if count_var = "1001" then
                count_var := "0000";
            else
                count_var := STD_LOGIC_VECTOR(unsigned(count_var) + 1);
            end if;
            count_var_sig <= count_var;
        end if;
    end process;

    dec_inst1 : decoder port map(
        digit => count_signal,
        seg   => HEX0
    );

    dec_inst2 : decoder port map(
        digit => count_var_sig,
        seg   => HEX3
    );
end Behavioral;

