library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 定義名為 Lab07_1 的實體
entity Lab07_1 is
    port (
        -- 50MHz 時鐘輸入
        CLOCK_50 : in STD_LOGIC;
        -- 按鍵輸入，僅使用 KEY(1)
        KEY : in STD_LOGIC_VECTOR(1 downto 1);
        -- 8 位元 LED 指示燈輸出
        LEDG : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity Lab07_1;

-- Lab07_1 實體的行為架構
architecture behavior of Lab07_1 is
    -- 分頻計數器，範圍為 0 到 DIVIDER
    signal CLOCK_1Hz : INTEGER range 0 to 24999999 := 0;
    -- 1Hz 時鐘信號
    signal clock_enable : STD_LOGIC := '0';

    -- 主計數器（3 位元寬度，初始化為 7）
    signal counter : unsigned(2 downto 0) := "111";
begin
    -- 分頻過程 (更精確的 1Hz 生成)
    -- 時鐘分頻處理過程，將 50MHz 轉換為 1Hz 時鐘
    process (CLOCK_50, KEY(1))
    begin
        -- 如果 KEY(1) 被按下（低電平有效），則重置分頻器和時鐘
        if KEY(1) = '0' then
            CLOCK_1Hz    <= 0;
            clock_enable <= '0';
            -- 偵測 50MHz 時鐘的上升沿
        elsif rising_edge(CLOCK_50) then
            -- 當計數器達到分頻值時
            if CLOCK_1Hz = 24999999 then
                CLOCK_1Hz    <= 0; -- 重置計數器
                clock_enable <= '1';
            else
                CLOCK_1Hz    <= CLOCK_1Hz + 1; -- 否則計數器加 1
                clock_enable <= '0';
            end if;
        end if;
    end process;

    -- 倒數計數器過程 (使用 clock_1Hz 的上升沿)
    -- 使用 1Hz 時鐘的倒數計數器
    process (CLOCK_50, KEY(1))
    begin
        -- 如果 KEY(1) 被按下，重置計數器為 7
        if KEY(1) = '0' then
            counter <= "111";
            -- 偵測 1Hz 時鐘的上升沿
        elsif rising_edge(CLOCK_50) then
            if clock_enable = '1' then
                -- 如果計數器已經到 0，則重新設置為 7
                if counter = "000" then
                    counter <= "111";
                else
                    counter <= counter - 1; -- 否則計數器減 1
                end if;
            end if;
        end if;
    end process;

    -- LED 解碼過程 (改為組合邏輯)
    -- 將計數器值解碼為 LED 顯示格式（組合邏輯）
    -- 根據 counter 的當前值，點亮對應的 LED
    LEDG <= "00000001" when counter = "000" else -- 當 counter=0，點亮最低位 LED
        "00000010" when counter = "001" else         -- counter=1，第二位 LED
        "00000100" when counter = "010" else         -- counter=2，第三位 LED
        "00001000" when counter = "011" else         -- counter=3，第四位 LED
        "00010000" when counter = "100" else         -- counter=4，第五位 LED
        "00100000" when counter = "101" else         -- counter=5，第六位 LED
        "01000000" when counter = "110" else         -- counter=6，第七位 LED
        "10000000" when counter = "111" else         -- counter=7，最高位 LED
        "00000000";                                  -- 預設情況，熄滅所有 LED
end architecture behavior;
