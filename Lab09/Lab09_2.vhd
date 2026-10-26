-- 本代碼實現了一個8x8 LED矩陣小綠人動畫功能，按鍵控制動畫播放與暫停

-- 引入標準庫
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- 定義實體，包含輸入輸出端口
entity Lab09_2 is
    port (
        CLOCK_50 : in STD_LOGIC;                      -- 50MHz時鐘輸入
        KEY      : in STD_LOGIC_VECTOR(2 downto 0);   -- 按鍵輸入(3個按鍵)
        GPIO_0   : out STD_LOGIC_VECTOR(21 downto 9); -- 連接到8x8 LED背面的引腳(16-9)
        GPIO_1   : out STD_LOGIC_VECTOR(21 downto 9)  -- 連接到8x8 LED正面的引腳(1-8)
    );
end Lab09_2;

-- 定義架構
architecture arch of Lab09_2 is
    -- 定義8x8 LED矩陣類型，每個數組存儲一行的模式
    type LED8x8_type is array (1 to 8) of STD_LOGIC_VECTOR(1 to 8);

    -- 定義小綠人動畫ROM數據，8幀圖案
    type GREEN_ROM_type is array (1 to 8) of LED8x8_type;
    constant GREEN_ROM : GREEN_ROM_type := (
        1 => ("00111000", "00110000", "00011000", "00011000", "00011000", "00001000", "00010100", "00010100"),
        2 => ("00111000", "00110000", "00011000", "00011100", "00111000", "00010100", "00010100", "00100100"),
        3 => ("00111000", "00110000", "00011100", "00111010", "00001000", "00010100", "00100100", "00100010"),
        4 => ("00111000", "00110000", "00011100", "00111010", "01001001", "00010100", "00100010", "00100010"),
        5 => ("00111000", "00110000", "00011110", "00111001", "01001000", "00010100", "00100010", "01000010"),
        6 => ("00111000", "00110000", "00011100", "00111010", "01001001", "00010100", "00100010", "00100010"),
        7 => ("00111000", "00110000", "00011100", "00111010", "00001000", "00010100", "00100100", "00100010"),
        8 => ("00111000", "00110000", "00011000", "00011100", "00111000", "00010100", "00010100", "00100100")
    );

    constant divisor : INTEGER := 50000; -- 分頻系數

    -- 定義信號
    signal CLK, reset_n                 : STD_LOGIC;
    signal btn_toggle, btn_toggle_prev  : STD_LOGIC                := '1';
    signal toggle_state                 : STD_LOGIC                := '1';
    signal frame_index                  : INTEGER range 1 to 8     := 1;
    signal count_1khz, count_1hz        : INTEGER range 0 to 25000 := 0; -- 計數器
    signal CLK_1khz, CLK_10hz, SCAN_CLK : STD_LOGIC;                     -- 時鐘信號
    signal SCANLINE                     : INTEGER range 0 to 7;          -- 掃描線
    signal ROW, COL                     : STD_LOGIC_VECTOR(1 to 8);      -- 行和列信號
    signal LED8x8map                    : LED8x8_type;                   -- LED矩陣映射
    signal display_enable               : STD_LOGIC := '1';

begin
    -- 時鐘和按鍵信號分配
    CLK        <= CLOCK_50;
    reset_n    <= '1';
    btn_toggle <= KEY(2);

    -- 1kHz分頻器
    process (CLK)
    begin
        if CLK'event and CLK = '1' then
            if count_1khz < divisor/2 - 1 then
                count_1khz <= count_1khz + 1;
            else
                count_1khz <= 0;
                CLK_1khz   <= not CLK_1khz; -- 反轉時鐘信號
            end if;
        end if;
    end process;

    -- 10Hz分頻器
    process (CLK_1khz)
    begin
        if CLK_1khz'event and CLK_1khz = '1' then
            if count_1hz < 249 then
                count_1hz <= count_1hz + 1;
            else
                count_1hz <= 0;
                CLK_10hz  <= not CLK_10hz; -- 反轉時鐘信號
            end if;
        end if;
    end process;

    -- 動畫控制(2Hz時鐘)
    process (CLK_10hz)
    begin
        if rising_edge(CLK_10hz) then
            if toggle_state = '1' then
                if frame_index = 8 then
                    frame_index <= 1;
                else
                    frame_index <= frame_index + 1;
                end if;
            end if;
        end if;
    end process;

    -- 按鍵防彈跳與切換邏輯
    process (CLK_1khz)
    begin
        if rising_edge(CLK_1khz) then
            btn_toggle_prev <= btn_toggle;
            if btn_toggle = '1' and btn_toggle_prev = '0' then
                toggle_state <= not toggle_state;
            end if;
        end if;
    end process;

    -- 掃描時鐘分配
    SCAN_CLK <= CLK_1khz;

    -- 掃描電路
    process (SCAN_CLK, reset_n)
    begin
        if reset_n = '0' then
            SCANLINE <= 0; -- 復位時掃描線為0
        elsif SCAN_CLK'event and SCAN_CLK = '1' then
            if SCANLINE = 7 then
                SCANLINE <= 0; -- 掃描線循環
            else
                SCANLINE <= SCANLINE + 1; -- 掃描線遞增
            end if;
        end if;
    end process;

    -- 顯示電路，根據掃描線與顯示使能選擇行信號
    process (SCANLINE, display_enable)
    begin
        if display_enable = '0' then
            ROW <= (others => '1');
        else
            case SCANLINE is
                when 0      => ROW      <= "01111111";
                when 1      => ROW      <= "10111111";
                when 2      => ROW      <= "11011111";
                when 3      => ROW      <= "11101111";
                when 4      => ROW      <= "11110111";
                when 5      => ROW      <= "11111011";
                when 6      => ROW      <= "11111101";
                when 7      => ROW      <= "11111110";
                when others => ROW <= "11111111";
            end case;
        end if;
    end process;

    -- 顯示電路，根據掃描線與顯示使能選擇列信號
    process (SCANLINE, display_enable, LED8x8map)
    begin
        if display_enable = '0' then
            COL <= (others => '0');
        else
            case SCANLINE is
                when 0 => COL      <= LED8x8map(1);
                when 1 => COL      <= LED8x8map(2);
                when 2 => COL      <= LED8x8map(3);
                when 3 => COL      <= LED8x8map(4);
                when 4 => COL      <= LED8x8map(5);
                when 5 => COL      <= LED8x8map(6);
                when 6 => COL      <= LED8x8map(7);
                when 7 => COL      <= LED8x8map(8);
                when others => COL <= (others => '0');
            end case;
        end if;
    end process;

    -- 取代骰子圖案設定為動畫幀
    LED8x8map <= GREEN_ROM(frame_index);

    -- 背面引腳連接
    GPIO_0(21) <= COL(8); GPIO_0(19) <= COL(7); GPIO_0(17) <= ROW(2); GPIO_0(15) <= COL(1);
    GPIO_0(14) <= ROW(4); GPIO_0(13) <= COL(6); GPIO_0(11) <= COL(4); GPIO_0(9) <= ROW(1);
    -- 正面引腳連接
    GPIO_1(21) <= ROW(5); GPIO_1(19) <= ROW(7); GPIO_1(17) <= COL(2); GPIO_1(15) <= COL(3);
    GPIO_1(14) <= ROW(8); GPIO_1(13) <= COL(5); GPIO_1(11) <= ROW(6); GPIO_1(9) <= ROW(3);

end arch;
