library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Lab06_2 is
    port (
        KEY  : in STD_LOGIC_VECTOR(2 downto 1); -- KEY(1): active-low asynchronous reset, KEY(2): manual clock
        SW   : in STD_LOGIC_VECTOR(7 downto 0); -- 8-bit input
        LEDG : out STD_LOGIC_VECTOR(9 downto 0) -- LEDG(7 downto 0): output sum, LEDG(9): overflow
    );
end Lab06_2;

architecture Behavioral of Lab06_2 is
    -- 暫存器：用來存儲第一次或上一次的輸入值
    signal temp_reg : signed(7 downto 0) := (others => '0');
    -- 累加暫存器：用來累加輸出
    signal acc_reg : signed(7 downto 0) := (others => '0');
    -- 溢位鎖存器
    signal overflow_reg : STD_LOGIC := '0';
    -- 狀態控制：0 = 尚未存入, 1 = 已存入等待輸出, 2 = 累加運算中
    signal state : INTEGER range 0 to 2 := 0;
begin

    process (KEY(2), KEY(1))
        variable sum : signed(7 downto 0);
    begin
        if (KEY(1) = '0') then
            -- 非同步重置：清除所有暫存器與狀態
            temp_reg     <= (others => '0');
            acc_reg      <= (others => '0');
            overflow_reg <= '0';
            state        <= 0;
        elsif rising_edge(KEY(2)) then
            if state = 0 then
                -- 第一次按下：將 SW 輸入存入暫存器
                temp_reg <= signed(SW);
                state    <= 1;
            elsif state = 1 then
                -- 第二次按下：輸出暫存器的值到累加器
                acc_reg <= temp_reg;
                state   <= 2;
            else
                -- 第三次及之後：將目前累加值與暫存器中的值相加
                sum := acc_reg + temp_reg;
                acc_reg <= sum;
                -- 有號加法溢位判斷：
                if (acc_reg(7) = temp_reg(7)) and (sum(7) /= acc_reg(7)) then
                    overflow_reg <= '1';
                else
                    overflow_reg <= '0';
                end if;
                -- 更新暫存器：將目前的 SW 輸入存入，供下次加法使用
                temp_reg <= signed(SW);
            end if;
        end if;
    end process;

    -- 將累加結果與溢位訊號對應輸出到 LED
    LEDG(7 downto 0) <= STD_LOGIC_VECTOR(acc_reg);
    LEDG(9)          <= overflow_reg;
    LEDG(8)          <= '0';

end Behavioral;
