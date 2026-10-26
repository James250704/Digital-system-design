library IEEE;                -- 導入IEEE標準庫
use IEEE.STD_LOGIC_1164.all; -- 使用STD_LOGIC_1164包中的所有內容，處理標準邏輯信號
use IEEE.NUMERIC_STD.all;    -- 使用NUMERIC_STD包中的所有內容，處理數值運算

entity Lab07_2 is -- 定義實體Lab07_2
    port (
        CLOCK_50 : in STD_LOGIC;                     -- 50MHz時鐘輸入
        KEY      : in STD_LOGIC_VECTOR(1 downto 1);  -- 按鍵輸入，只使用KEY(1)
        HEX2     : out STD_LOGIC_VECTOR(6 downto 0); -- 七段顯示器HEX2的控制信號
        HEX3     : out STD_LOGIC_VECTOR(6 downto 0)  -- 七段顯示器HEX3的控制信號
    );
end Lab07_2; -- 實體定義結束

architecture Behavioral of Lab07_2 is -- 定義行為架構
    component decoder                     -- 宣告解碼器元件
        port (
            digit : in STD_LOGIC_VECTOR(3 downto 0); -- 4位BCD數字輸入
            seg   : out STD_LOGIC_VECTOR(6 downto 0) -- 七段顯示器段碼輸出
        );
    end component; -- 元件宣告結束

    signal clk_5Hz     : STD_LOGIC                    := '0';    -- 5Hz時鐘信號，初始值為0
    signal counter_5Hz : INTEGER range 0 to 4999999   := 0;      -- 5Hz分頻計數器，範圍0-4999999
    signal bcd_lsb     : STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- BCD碼最低有效位，初始0
    signal bcd_msb     : STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- BCD碼最高有效位，初始0
    signal reset_sync  : STD_LOGIC_VECTOR(1 downto 0) := "00";   -- 同步復位信號緩存，初始00
    signal reset       : STD_LOGIC;                              -- 復位信號
begin                                                        -- 架構實現開始
    process (CLOCK_50)                                           -- 同步復位處理進程
    begin
        if rising_edge(CLOCK_50) then         -- 在CLOCK_50上升沿觸發
            reset_sync <= reset_sync(0) & KEY(1); -- 同步按鍵輸入，防止亞穩態
        end if;
    end process;

    reset <= not reset_sync(1); -- 復位信號為同步後的KEY(1)取反

    process (CLOCK_50) -- 5Hz時鐘生成進程
    begin
        if rising_edge(CLOCK_50) then -- 在CLOCK_50上升沿觸發
            if reset = '1' then           -- 如果復位信號有效
                counter_5Hz <= 0;             -- 重置計數器
                clk_5Hz     <= '0';           -- 重置5Hz時鐘
            else
                if counter_5Hz = 4999999 then -- 計數達到4999999(50MHz/10Hz/2=5MHz)
                    counter_5Hz <= 0;             -- 重置計數器
                    clk_5Hz     <= not clk_5Hz;   -- 反轉5Hz時鐘信號
                else
                    counter_5Hz <= counter_5Hz + 1; -- 計數器加1
                end if;
            end if;
        end if;
    end process;

    process (clk_5Hz, reset) -- BCD計數器進程
    begin
        if reset = '1' then             -- 如果復位信號有效
            bcd_lsb <= "0000";              -- 重置最低有效位
            bcd_msb <= "0000";              -- 重置最高有效位
        elsif rising_edge(clk_5Hz) then -- 在5Hz時鐘上升沿觸發
            if bcd_lsb = "1001" then        -- 如果最低有效位達到9
                bcd_lsb <= "0000";              -- 重置最低有效位
                if bcd_msb = "1001" then        -- 如果最高有效位也達到9
                    bcd_msb <= "0000";              -- 重置最高有效位
                else
                    bcd_msb <= STD_LOGIC_VECTOR(unsigned(bcd_msb) + 1); -- 最高有效位加1
                end if;
            else
                bcd_lsb <= STD_LOGIC_VECTOR(unsigned(bcd_lsb) + 1); -- 最低有效位加1
            end if;
        end if;
    end process;

    Decoder_LSB : decoder -- 最低有效位解碼器實例
    port map(
        digit => bcd_lsb, -- 連接最低有效位BCD碼
        seg   => HEX2     -- 連接HEX2七段顯示器
    );

    Decoder_MSB : decoder -- 最高有效位解碼器實例
    port map(
        digit => bcd_msb, -- 連接最高有效位BCD碼
        seg   => HEX3     -- 連接HEX3七段顯示器
    );
end Behavioral; -- 架構實現結束
