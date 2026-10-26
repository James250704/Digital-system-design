library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Lab10_1 is
    port (
        CLOCK_50 : in STD_LOGIC;
        KEY      : in STD_LOGIC_VECTOR(2 downto 0);
        GPIO_0   : out STD_LOGIC_VECTOR(21 downto 9); -- LCD pin  8~1
        GPIO_1   : out STD_LOGIC_VECTOR(21 downto 9)  -- LCD pin 16~9
    );
end Lab10_1;

architecture arch of Lab10_1 is
    --------------------------------------------------------------------
    --  Component 宣告
    --------------------------------------------------------------------
    component CLK_GEN is
        generic (divisor : INTEGER := 50_000_000);
        port (
            clock_in  : in STD_LOGIC;
            clock_out : out STD_LOGIC
        );
    end component;

    component debounce is
        port (
            clk    : in STD_LOGIC;
            button : in STD_LOGIC;
            result : out STD_LOGIC
        );
    end component;

    --------------------------------------------------------------------
    --  型別 & 訊號
    --------------------------------------------------------------------
    type DDRAM is array(0 to 15) of STD_LOGIC_VECTOR(7 downto 0);

    signal RESET                  : STD_LOGIC;
    signal LCM_CLK                : STD_LOGIC;
    signal COUNTER                : INTEGER range 0 to 41;
    signal LINE1, LINE2           : DDRAM;
    signal LCM_RS, LCM_RW, LCM_EN : STD_LOGIC;
    signal LCM_DB                 : STD_LOGIC_VECTOR(7 downto 0);

    -- 三個工作時脈
    signal CLK_1khz, CLK_500hz, CLK_1hz : STD_LOGIC;

    -- 去彈跳後的按鍵：Buttons(0) = KEY(1)、Buttons(1) = KEY(2)
    signal Buttons : STD_LOGIC_VECTOR(1 downto 0);

    -- 顯示控制：1=顯示訊息、0=清空
    signal show_msg : STD_LOGIC := '0';

    -- 初始化完成旗標
    signal init_done : STD_LOGIC := '0';

    -- 便利常數
    constant BLANK : STD_LOGIC_VECTOR(7 downto 0) := "00100000"; -- ASCII " "
    constant DOT   : STD_LOGIC_VECTOR(7 downto 0) := "00101110"; -- ASCII "."
begin
    --------------------------------------------------------------------
    --  時脈產生器 & debounce
    --------------------------------------------------------------------
    CLK_U0 : CLK_GEN generic map(divisor => 50_000) port map(CLOCK_50, CLK_1khz);
    CLK_U1 : CLK_GEN generic map(divisor => 100_000) port map(CLOCK_50, CLK_500hz);
    CLK_U2 : CLK_GEN generic map(divisor => 50_000_000) port map(CLOCK_50, CLK_1hz);

    debounce_key1 : debounce port map(clk => CLOCK_50, button => KEY(1), result => Buttons(0));
    debounce_key2 : debounce port map(clk => CLOCK_50, button => KEY(2), result => Buttons(1));

    --------------------------------------------------------------------
    --  基本訊號
    --------------------------------------------------------------------
    LCM_CLK <= CLK_500hz; -- 約 2 ms
    LCM_EN  <= LCM_CLK;
    RESET   <= KEY(0); -- active-low

    --------------------------------------------------------------------
    --  按鍵取樣 + LINE1 / LINE2 更新
    --------------------------------------------------------------------
    manage_display : process (CLK_1khz, RESET)
    begin
        if RESET = '0' then
            show_msg <= '0';
            for i in 0 to 15 loop
                LINE1(i) <= BLANK;
                LINE2(i) <= BLANK;
            end loop;

        elsif rising_edge(CLK_1khz) then
            -- KEY 為 active-low
            if Buttons(0) = '0' then -- KEY(1)：清空
                show_msg <= '0';
            elsif Buttons(1) = '0' then -- KEY(2)：顯示
                show_msg <= '1';
            end if;

            -- 依 show_msg 決定內容
            if show_msg = '0' then
                for i in 0 to 15 loop
                    LINE1(i) <= BLANK;
                    LINE2(i) <= BLANK;
                end loop;
            else
                -- Iecs Digital….
                LINE1(0)  <= "01001001"; -- I
                LINE1(1)  <= "01000101"; -- E
                LINE1(2)  <= "01000011"; -- C
                LINE1(3)  <= "01010011"; -- S
                LINE1(4)  <= BLANK;
                LINE1(5)  <= "01000100"; -- D
                LINE1(6)  <= "01101001"; -- i
                LINE1(7)  <= "01100111"; -- g
                LINE1(8)  <= "01101001"; -- i
                LINE1(9)  <= "01110100"; -- t
                LINE1(10) <= "01100001"; -- a
                LINE1(11) <= "01101100"; -- l
                LINE1(12) <= DOT;
                LINE1(13) <= DOT;
                LINE1(14) <= DOT;
                LINE1(15) <= DOT;

                -- System Design...
                LINE2(0)  <= "01010011"; -- S
                LINE2(1)  <= "01111001"; -- y
                LINE2(2)  <= "01110011"; -- s
                LINE2(3)  <= "01110100"; -- t
                LINE2(4)  <= "01100101"; -- e
                LINE2(5)  <= "01101101"; -- m
                LINE2(6)  <= BLANK;
                LINE2(7)  <= "01000100"; -- D
                LINE2(8)  <= "01100101"; -- e
                LINE2(9)  <= "01110011"; -- s
                LINE2(10) <= "01101001"; -- i
                LINE2(11) <= "01100111"; -- g
                LINE2(12) <= "01101110"; -- n
                LINE2(13) <= DOT;
                LINE2(14) <= DOT;
                LINE2(15) <= DOT;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    --  計數器：初始化僅跑一次
    --------------------------------------------------------------------
    process (LCM_CLK, RESET)
    begin
        if RESET = '0' then
            COUNTER   <= 0;
            init_done <= '0';

        elsif rising_edge(LCM_CLK) then
            if COUNTER = 41 then -- 第二行最後一字元送完
                if init_done = '0' then
                    init_done <= '1'; -- 標記初始化完成
                end if;
                -- 完成初始化後只回到 8，跳過 0‥7
                if init_done = '0' then
                    COUNTER <= 0;
                else
                    COUNTER <= 8;
                end if;
            else
                COUNTER <= COUNTER + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    --  LCD 指令 / 資料輸出
    --------------------------------------------------------------------
    process (LCM_CLK, RESET)
    begin
        if RESET = '0' then
            LCM_RS <= '0';
            LCM_RW <= '0';
            LCM_DB <= (others => '0');

        elsif falling_edge(LCM_CLK) then
            ----------------------------------------------------------------
            --   0‥7：僅第一次執行 (init_done='0')
            ----------------------------------------------------------------
            if init_done = '0' then
                case COUNTER is
                    when 0 | 1 | 2 | 3 =>
                        LCM_RS <= '0'; LCM_RW <= '0';
                        LCM_DB <= "00111000"; -- Function Set
                    when 4 =>
                        LCM_DB <= "00001000"; -- Display OFF
                    when 5 =>
                        LCM_DB <= "00000001"; -- Clear Display
                    when 6 =>
                        LCM_DB <= "00001100"; -- Display ON
                    when 7 =>
                        LCM_DB <= "00000110"; -- Entry Mode Set
                    when others => null;
                end case;
            end if;

            ----------------------------------------------------------------
            --   8‥41：兩行字 (每次都執行)
            ----------------------------------------------------------------
            case COUNTER is
                    -- 第一行
                when 8 =>
                    LCM_RS <= '0'; LCM_DB <= "10000000"; -- DDRAM Addr 0
                when 9  => LCM_RS <= '1'; LCM_DB <= LINE1(0);
                when 10 => LCM_DB <= LINE1(1);
                when 11 => LCM_DB <= LINE1(2);
                when 12 => LCM_DB <= LINE1(3);
                when 13 => LCM_DB <= LINE1(4);
                when 14 => LCM_DB <= LINE1(5);
                when 15 => LCM_DB <= LINE1(6);
                when 16 => LCM_DB <= LINE1(7);
                when 17 => LCM_DB <= LINE1(8);
                when 18 => LCM_DB <= LINE1(9);
                when 19 => LCM_DB <= LINE1(10);
                when 20 => LCM_DB <= LINE1(11);
                when 21 => LCM_DB <= LINE1(12);
                when 22 => LCM_DB <= LINE1(13);
                when 23 => LCM_DB <= LINE1(14);
                when 24 => LCM_DB <= LINE1(15);

                    -- 第二行
                when 25 =>
                    LCM_RS <= '0'; LCM_DB <= "11000000"; -- DDRAM Addr 40h
                when 26 => LCM_RS <= '1'; LCM_DB <= LINE2(0);
                when 27 => LCM_DB <= LINE2(1);
                when 28 => LCM_DB <= LINE2(2);
                when 29 => LCM_DB <= LINE2(3);
                when 30 => LCM_DB <= LINE2(4);
                when 31 => LCM_DB <= LINE2(5);
                when 32 => LCM_DB <= LINE2(6);
                when 33 => LCM_DB <= LINE2(7);
                when 34 => LCM_DB <= LINE2(8);
                when 35 => LCM_DB <= LINE2(9);
                when 36 => LCM_DB <= LINE2(10);
                when 37 => LCM_DB <= LINE2(11);
                when 38 => LCM_DB <= LINE2(12);
                when 39 => LCM_DB <= LINE2(13);
                when 40 => LCM_DB <= LINE2(14);
                when 41 => LCM_DB <= LINE2(15);

                when others => null;
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    --  LCD-to-GPIO 對應
    --------------------------------------------------------------------
    GPIO_0(13) <= '0'; -- 鍵入固定
    GPIO_0(14) <= LCM_RS;
    GPIO_0(15) <= LCM_RW;
    GPIO_0(17) <= LCM_EN;

    -- DB0 ~ DB7
    GPIO_0(19) <= LCM_DB(0);
    GPIO_0(21) <= LCM_DB(1);
    GPIO_1(9)  <= LCM_DB(2);
    GPIO_1(11) <= LCM_DB(3);
    GPIO_1(13) <= LCM_DB(4);
    GPIO_1(14) <= LCM_DB(5);
    GPIO_1(15) <= LCM_DB(6);
    GPIO_1(17) <= LCM_DB(7);

    -- 背光常亮
    GPIO_1(19) <= '1';
    GPIO_1(21) <= '0';
end arch;
