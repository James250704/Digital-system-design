--=============================================================
--  Lab10_2  ‧ LCD：KEY(1) 清空停滾動，KEY(2) 顯示 D1256773 來回滾動
--=============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Lab10_2 is
    port (
        CLOCK_50 : in STD_LOGIC;
        KEY      : in STD_LOGIC_VECTOR(2 downto 0);
        GPIO_0   : out STD_LOGIC_VECTOR(21 downto 9); -- LCD pin 8-1
        GPIO_1   : out STD_LOGIC_VECTOR(21 downto 9)  -- LCD pin16-9
    );
end Lab10_2;

architecture arch of Lab10_2 is
    --------------------------------------------------------------------
    --  CLOCK DIVIDER & DEBOUNCE COMPONENTS
    --------------------------------------------------------------------
    component CLK_GEN is
        generic (divisor : INTEGER := 50_000_000);
        port (
            clock_in  : in STD_LOGIC;
            clock_out : out STD_LOGIC);
    end component;

    component debounce is
        port (
            clk    : in STD_LOGIC;
            button : in STD_LOGIC;
            result : out STD_LOGIC
        );
    end component;

    --------------------------------------------------------------------
    --  Internal types / constants
    --------------------------------------------------------------------
    type DDRAM is array (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
    type MSG_ARRAY is array (0 to 7) of STD_LOGIC_VECTOR(7 downto 0);

    -- "D1256773"
    constant MSG : MSG_ARRAY := (
        0 => "01000100", -- D
        1 => "00110001", -- 1
        2 => "00110010", -- 2
        3 => "00110101", -- 5
        4 => "00110110", -- 6
        5 => "00110111", -- 7
        6 => "00110111", -- 7
        7 => "00110011"  -- 3
    );
    constant MSG_LEN : INTEGER := 8;

    --------------------------------------------------------------------
    --  Signals
    --------------------------------------------------------------------
    signal RESET   : STD_LOGIC;
    signal LCM_CLK : STD_LOGIC;
    signal COUNTER : INTEGER range 0 to 41;

    signal LINE1, LINE2 : DDRAM;
    signal LCM_RS       : STD_LOGIC;
    signal LCM_RW       : STD_LOGIC;
    signal LCM_EN       : STD_LOGIC;
    signal LCM_DB       : STD_LOGIC_VECTOR(7 downto 0);

    -- clocks
    signal CLK_1khz, CLK_500hz, CLK_10hz : STD_LOGIC;

    -- keys
    signal Buttons      : STD_LOGIC_VECTOR(1 downto 0); -- 0=KEY(1), 1=KEY(2)
    signal last_buttons : STD_LOGIC_VECTOR(1 downto 0);

    -- show / scroll control
    signal show_msg : STD_LOGIC            := '0'; -- 1 = show & scroll
    signal dir      : STD_LOGIC            := '0'; -- 0 = → (text ←), 1 = ← (text →)
    signal offset   : INTEGER range 0 to 8 := 0;

    -- rising-edge detector for show_msg
    signal last_show : STD_LOGIC := '0';
begin
    --------------------------------------------------------------------
    --  Clock generators  (50 MHz → 1 kHz / 500 Hz / 10 Hz)
    --------------------------------------------------------------------
    CLK_U0 : CLK_GEN generic map(divisor => 50_000) port map(CLOCK_50, CLK_1khz);    -- 1 kHz
    CLK_U1 : CLK_GEN generic map(divisor => 100_000) port map(CLOCK_50, CLK_500hz);  -- 500 Hz
    CLK_U2 : CLK_GEN generic map(divisor => 5_000_000) port map(CLOCK_50, CLK_10hz); -- 10 Hz

    --------------------------------------------------------------------
    --  Key debounce
    --------------------------------------------------------------------
    debounce_key1 : debounce port map(clk => CLOCK_50, button => KEY(1), result => Buttons(0));
    debounce_key2 : debounce port map(clk => CLOCK_50, button => KEY(2), result => Buttons(1));

    --------------------------------------------------------------------
    --  Global reset & LCD enable
    --------------------------------------------------------------------
    RESET   <= KEY(0);
    LCM_CLK <= CLK_500hz;
    LCM_EN  <= LCM_CLK;

    --------------------------------------------------------------------
    --  (1) 1 kHz sampling process : detect key events → control show_msg
    --------------------------------------------------------------------
    process (CLK_1khz, RESET)
    begin
        if RESET = '0' then
            show_msg     <= '0';
            last_buttons <= (others => '0');
        elsif rising_edge(CLK_1khz) then
            -- KEY(1) ↑ : clear & stop
            if Buttons(0) = '1' and last_buttons(0) = '0' then
                show_msg <= '0';
                -- KEY(2) ↑ : start display
            elsif Buttons(1) = '1' and last_buttons(1) = '0' then
                show_msg <= '1';
                -- dir / offset 初始值交由 1 Hz process 在 rising edge 時重置
            end if;
            last_buttons <= Buttons;
        end if;
    end process;

    --------------------------------------------------------------------
    --  (2) 10 Hz scrolling / assembling process
    --------------------------------------------------------------------
    process (CLK_10hz, RESET)
        variable i : INTEGER;
    begin
        if RESET = '0' then
            dir       <= '0';
            offset    <= 0;
            last_show <= '0';
            -- clear both lines
            for i in 0 to 15 loop
                LINE1(i) <= "00100000";
                LINE2(i) <= "00100000";
            end loop;

        elsif rising_edge(CLK_10hz) then
            ----------------------------------------------------------------
            -- Rising edge of show_msg → reset dir/offset
            ----------------------------------------------------------------
            if show_msg = '1' and last_show = '0' then
                dir    <= '0';
                offset <= 0;
            end if;
            last_show <= show_msg;

            ----------------------------------------------------------------
            -- Ping-Pong update of offset
            ----------------------------------------------------------------
            if show_msg = '1' then
                if dir = '0' then -- move right (text ←)
                    if offset < 16 - MSG_LEN then
                        offset <= offset + 1;
                    else
                        dir    <= '1';
                        offset <= offset - 1;
                    end if;
                else -- dir = '1' move left (text →)
                    if offset > 0 then
                        offset <= offset - 1;
                    else
                        dir    <= '0';
                        offset <= offset + 1;
                    end if;
                end if;
            end if;

            ----------------------------------------------------------------
            -- Re-assemble LINE1
            ----------------------------------------------------------------
            for i in 0 to 15 loop
                if show_msg = '1' and i >= offset and i < offset + MSG_LEN then
                    LINE1(i) <= MSG(i - offset);
                else
                    LINE1(i) <= "00100000"; -- space
                end if;
            end loop;
        end if;
    end process;

    --------------------------------------------------------------------
    --  (3) 500 Hz LCD timing / data output process
    --------------------------------------------------------------------
    process (LCM_CLK, RESET)
    begin
        if RESET = '0' then
            null; -- nothing to do during reset
        elsif falling_edge(LCM_CLK) then
            case COUNTER is
                when 0 to 3 =>
                    LCM_RS <= '0'; LCM_RW <= '0'; LCM_DB <= "00111000"; -- Function set
                when 4 => LCM_DB <= "00001000";                     -- Display off
                when 5 => LCM_DB <= "00000001";                     -- Clear
                when 6 => LCM_DB <= "00001100";                     -- Display on
                when 7 => LCM_DB <= "00000110";                     -- Entry mode
                when 8 => LCM_RS <= '0'; LCM_DB <= "10000000";      -- DDRAM addr 0
                    -- LINE1
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
                    -- LINE2 (kept blank)
                when 25 => LCM_RS <= '0'; LCM_DB <= "11000000"; -- DDRAM addr 40h
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
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    --  (4) COUNTER 0-41 : LCD state machine pointer
    --------------------------------------------------------------------
    process (LCM_CLK, RESET)
    begin
        if RESET = '0' then
            COUNTER <= 0;
        elsif rising_edge(LCM_CLK) then
            if COUNTER = 41 then
                COUNTER <= 0; -- ★ 每次都從 0 重新開始，兩行都刷新 ★
            else
                COUNTER <= COUNTER + 1;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    --  LCD → FPGA I/O mapping
    --------------------------------------------------------------------
    -- pin3~6
    GPIO_0(13) <= '0'; -- LCD V0
    GPIO_0(14) <= LCM_RS;
    GPIO_0(15) <= LCM_RW;
    GPIO_0(17) <= LCM_EN;
    -- DB0~DB7  (pin7~14)
    GPIO_0(19) <= LCM_DB(0);
    GPIO_0(21) <= LCM_DB(1);
    GPIO_1(9)  <= LCM_DB(2);
    GPIO_1(11) <= LCM_DB(3);
    GPIO_1(13) <= LCM_DB(4);
    GPIO_1(14) <= LCM_DB(5);
    GPIO_1(15) <= LCM_DB(6);
    GPIO_1(17) <= LCM_DB(7);
    -- 背光
    GPIO_1(19) <= '1';
    GPIO_1(21) <= '0';

end arch;
