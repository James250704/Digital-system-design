library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

entity midterm04 is
    port (
        SW   : in STD_LOGIC_VECTOR(9 downto 0);
        KEY  : in STD_LOGIC_VECTOR(2 downto 1);
        HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
        HEX1 : out STD_LOGIC_VECTOR(6 downto 0);
        HEX2 : out STD_LOGIC_VECTOR(6 downto 0);
        HEX3 : out STD_LOGIC_VECTOR(6 downto 0)
    );
end midterm04;

architecture abc of midterm04 is
    signal input_num      : INTEGER range -128 to 255;
    signal display_num    : INTEGER range -128 to 255;
    signal is_negative    : STD_LOGIC;
    signal hundreds_digit : INTEGER range 0 to 2;
    signal tens_digit     : INTEGER range 0 to 9;
    signal ones_digit     : INTEGER range 0 to 9;

    -- 添加 decoder 元件宣告
    component decoder is
        port (
            digit : in STD_LOGIC_VECTOR(3 downto 0);
            seg   : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    -- 為每個七段顯示器添加連接訊號
    signal digit0     : STD_LOGIC_VECTOR(3 downto 0);
    signal digit1     : STD_LOGIC_VECTOR(3 downto 0);
    signal digit2     : STD_LOGIC_VECTOR(3 downto 0);
    signal digit3     : STD_LOGIC_VECTOR(3 downto 0);
    signal hex_enable : STD_LOGIC;

    -- 添加中間訊號用於解決多重驅動
    signal hex3_temp : STD_LOGIC_VECTOR(6 downto 0);

begin
    -- 將輸入轉換為整數
    input_num <= CONV_INTEGER(SIGNED(SW(7 downto 0))) when SW(9) = '1' and KEY(2) = '0' else
        CONV_INTEGER(UNSIGNED(SW(7 downto 0))) when SW(9) = '1' and KEY(1) = '0' else
        0;

    -- 判斷是否為負數
    is_negative <= '1' when input_num < 0 and SW(9) = '1' and KEY(2) = '0' else
        '0';

    -- 計算顯示的數字
    display_num <= - input_num when is_negative = '1' else
        input_num;

    -- 分離各位數
    hundreds_digit <= display_num / 100;
    tens_digit     <= (display_num / 10) mod 10;
    ones_digit     <= display_num mod 10;

    -- 決定是否啟用顯示
    hex_enable <= '1' when SW(9) = '1' and (KEY(2) = '0' or KEY(1) = '0') else
        '0';

    -- 準備要顯示的數字
    digit0 <= conv_std_logic_vector(ones_digit, 4) when hex_enable = '1' else
        "1111";
    digit1 <= conv_std_logic_vector(tens_digit, 4) when hex_enable = '1' else
        "1111";
    digit2 <= conv_std_logic_vector(hundreds_digit, 4) when hex_enable = '1' else
        "1111";
    digit3 <= "1111" when is_negative = '0' or hex_enable = '0' else
        "1010"; -- 1010用於顯示負號

    decoder0 : decoder
    port map(
        digit => digit0,
        seg   => HEX0
    );

    decoder1 : decoder
    port map(
        digit => digit1,
        seg   => HEX1
    );

    decoder2 : decoder
    port map(
        digit => digit2,
        seg   => HEX2
    );

    decoder3 : decoder
    port map(
        digit => digit3,
        seg   => hex3_temp -- 改為連接到中間訊號
    );

    -- 確定 HEX3 的最終值
    process (digit3, hex3_temp)
    begin
        if digit3 = "1010" then
            HEX3 <= "0111111"; -- 負號
        else
            HEX3 <= hex3_temp; -- 使用解碼器的輸出
        end if;
    end process;
end abc;
