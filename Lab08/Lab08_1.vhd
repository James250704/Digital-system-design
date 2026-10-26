library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity Lab08_1 is
    port (
        KEY  : in STD_LOGIC_VECTOR(2 downto 0); -- KEY(2) as clock, KEY(1) as reset
        SW   : in STD_LOGIC_VECTOR(0 downto 0); -- SW(0) as input X
        LEDG : out STD_LOGIC_VECTOR(9 downto 0) -- LEDG(9) as output, LEDG(7-5) as state
    );
end Lab08_1;

architecture Behavioral of Lab08_1 is
    type state_type is (S0_IDLE, S1_1, S2_10, S3_101, S4_1011); -- States for detecting "1011"
    signal current_state, next_state : state_type;
    signal clk, rst_n, x             : STD_LOGIC;
begin
    -- Assign input/output signals
    clk   <= KEY(2); -- KEY(2) as clock input
    rst_n <= KEY(1); -- KEY(1) as active-low reset
    x     <= SW(0);  -- SW(0) as input X

    -- Clock process
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= S0_IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- State transition process
    process (current_state, x)
    begin
        case current_state is
            when S0_IDLE =>
                if x = '1' then
                    next_state <= S1_1;
                else
                    next_state <= S0_IDLE;
                end if;

            when S1_1 =>
                if x = '0' then
                    next_state <= S2_10;
                else
                    next_state <= S1_1;
                end if;

            when S2_10 =>
                if x = '1' then
                    next_state <= S3_101;
                else
                    next_state <= S0_IDLE;
                end if;

            when S3_101 =>
                if x = '1' then
                    next_state <= S4_1011;
                else
                    next_state <= S2_10;
                end if;

            when S4_1011 =>
                if x = '1' then
                    next_state <= S1_1;
                else
                    next_state <= S2_10;
                end if;
        end case;
    end process;

    -- Output logic
    process (current_state)
    begin
        case current_state is
            when S0_IDLE =>
                LEDG(7 downto 5) <= "000";
                LEDG(9)          <= '0';

            when S1_1 =>
                LEDG(7 downto 5) <= "001";
                LEDG(9)          <= '0';

            when S2_10 =>
                LEDG(7 downto 5) <= "010";
                LEDG(9)          <= '0';

            when S3_101 =>
                LEDG(7 downto 5) <= "101";
                LEDG(9)          <= '0';

            when S4_1011 =>
                LEDG(7 downto 5) <= "011";
                LEDG(9)          <= '1'; -- Output 1 when sequence detected
        end case;
    end process;
end Behavioral;
