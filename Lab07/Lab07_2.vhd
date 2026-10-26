library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Lab07_2 is
    port (
        CLOCK_50 : in STD_LOGIC;
        KEY      : in STD_LOGIC_VECTOR(1 downto 1);
        HEX2     : out STD_LOGIC_VECTOR(6 downto 0);
        HEX3     : out STD_LOGIC_VECTOR(6 downto 0)
    );
end Lab07_2;

architecture Behavioral of Lab07_2 is
    component decoder
        port (
            digit : in STD_LOGIC_VECTOR(3 downto 0);
            seg   : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    signal clk_5Hz     : STD_LOGIC                    := '0';
    signal DIVIDER     : INTEGER                      := 4999999;
    signal counter_5Hz : INTEGER range 0 to DIVIDER   := 0;
    signal bcd_lsb     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal bcd_msb     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal reset_sync  : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal reset       : STD_LOGIC;
begin
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            reset_sync <= reset_sync(0) & KEY(1);
        end if;
    end process;

    reset <= not reset_sync(1);

    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset = '1' then
                counter_5Hz <= 0;
                clk_5Hz     <= '0';
            else
                if counter_5Hz = DIVIDER then
                    counter_5Hz <= 0;
                    clk_5Hz     <= not clk_5Hz;
                else
                    counter_5Hz <= counter_5Hz + 1;
                end if;
            end if;
        end if;
    end process;

    process (clk_5Hz, reset)
    begin
        if reset = '1' then
            bcd_lsb <= "0000";
            bcd_msb <= "0000";
        elsif rising_edge(clk_5Hz) then
            if bcd_lsb = "1001" then
                bcd_lsb <= "0000";
                if bcd_msb = "1001" then
                    bcd_msb <= "0000";
                else
                    bcd_msb <= STD_LOGIC_VECTOR(unsigned(bcd_msb) + 1);
                end if;
            else
                bcd_lsb <= STD_LOGIC_VECTOR(unsigned(bcd_lsb) + 1);
            end if;
        end if;
    end process;

    Decoder_LSB : decoder
    port map(
        digit => bcd_lsb,
        seg   => HEX2
    );

    Decoder_MSB : decoder
    port map(
        digit => bcd_msb,
        seg   => HEX3
    );
end Behavioral;
