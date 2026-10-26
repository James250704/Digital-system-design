library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab07_1 is
    port (
        CLOCK_50 : in STD_LOGIC;
        KEY      : in STD_LOGIC_VECTOR(1 downto 1);
        LEDG     : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity Lab07_1;

architecture behavior of Lab07_1 is
    -- 分頻器設定 (50MHz → 1Hz)
    constant DIVIDER : INTEGER                    := 24999999;
    signal prescaler : INTEGER range 0 to DIVIDER := 0;
    signal clock_1Hz : STD_LOGIC                  := '0';

    -- 主計數器
    signal counter : unsigned(2 downto 0) := "111";
begin
    -- 分頻過程 (更精確的1Hz生成)
    process (CLOCK_50, KEY(1))
    begin
        if KEY(1) = '0' then
            prescaler <= 0;
            clock_1Hz <= '0';
        elsif rising_edge(CLOCK_50) then
            if prescaler = DIVIDER then
                prescaler <= 0;
                clock_1Hz <= not clock_1Hz;
            else
                prescaler <= prescaler + 1;
            end if;
        end if;
    end process;

    -- 下數計數器過程 (使用clock_1Hz的上升沿)
    process (clock_1Hz, KEY(1))
    begin
        if KEY(1) = '0' then
            counter <= "111";
        elsif rising_edge(clock_1Hz) then
            if counter = "000" then
                counter <= "111";
            else
                counter <= counter - 1;
            end if;
        end if;
    end process;

    -- LED解碼過程 (改為組合邏輯)
    LEDG <= "00000001" when counter = "000" else
        "00000010" when counter = "001" else
        "00000100" when counter = "010" else
        "00001000" when counter = "011" else
        "00010000" when counter = "100" else
        "00100000" when counter = "101" else
        "01000000" when counter = "110" else
        "10000000" when counter = "111" else
        "00000000";
end architecture behavior;
