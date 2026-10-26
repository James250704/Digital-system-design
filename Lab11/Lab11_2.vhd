library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab11_2 is
    port (
        clk      : in STD_LOGIC;                    -- 50 MHz 系統時脈
        KEY      : in STD_LOGIC_VECTOR(1 downto 0); -- KEY(1)：異步復位 (active-low)
        ps2_clk  : in STD_LOGIC;                    -- PS/2 鍵盤時脈
        ps2_data : in STD_LOGIC;                    -- PS/2 鍵盤資料
        LEDG     : out STD_LOGIC_VECTOR(7 downto 0) -- 8 顆綠色 LED
    );
end Lab11_2;

architecture rtl of Lab11_2 is

    -- PS/2 → ASCII 轉換模組輸出
    signal ascii_new  : STD_LOGIC;
    signal ascii_code : STD_LOGIC_VECTOR(6 downto 0);

    -- LED 暫存器
    signal led_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin

    ----------------------------------------------------------------
    -- 實例化 PS/2 → ASCII 轉換元件
    ----------------------------------------------------------------
    u_ps2_to_ascii : entity work.ps2_keyboard_to_ascii
        generic map(
            clk_freq                  => 50_000_000,
            ps2_debounce_counter_size => 8
        )
        port map(
            clk        => clk,
            ps2_clk    => ps2_clk,
            ps2_data   => ps2_data,
            ascii_new  => ascii_new,
            ascii_code => ascii_code
        );

    ----------------------------------------------------------------
    -- LED 控制：異步復位 + ASCII 觸發旋轉
    ----------------------------------------------------------------
    process (KEY(1), clk)
    begin
        if KEY(1) = '0' then
            -- 異步復位：全部關閉
            led_reg <= (others => '0');
        elsif rising_edge(clk) then
            if ascii_new = '1' then
                case ascii_code is
                    when "0110000" => -- ASCII '0' = 0x30 = "0110000"
                        -- 右旋轉
                        led_reg <= led_reg(0) & led_reg(7 downto 1);

                    when "0110001" => -- ASCII '1' = 0x31 = "0110001"
                        -- 左旋轉
                        led_reg <= led_reg(6 downto 0) & led_reg(7);

                    when others =>
                        -- 其他按鍵不做動作
                        led_reg <= led_reg;
                end case;
            end if;
        end if;
    end process;

    -- 將暫存器驅動到板上 LED
    LEDG <= led_reg;

end rtl;
