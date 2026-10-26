library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity Lab08_2 is
    port (
        KEY  : in STD_LOGIC_VECTOR(2 downto 0); -- KEY(2) as clock, KEY(1) as reset
        SW   : in STD_LOGIC_VECTOR(0 downto 0); -- SW(0) as input w
        LEDG : out STD_LOGIC_VECTOR(9 downto 0) -- LEDG(9) as output z, LEDG(7-4) as state
    );
end Lab08_2;

architecture Behavioral of Lab08_2 is
    type state_type is (S0, S1_0, S2_0, S3_0, S4_0, S1_1, S2_1, S3_1, S4_1);
    signal current_state, next_state : state_type;
    signal clk, reset, w             : STD_LOGIC;
    signal z                         : STD_LOGIC;

begin
    -- Assign input/output signals
    clk              <= KEY(2);     -- Button2 as clock input
    reset            <= not KEY(1); -- Button1 as active-low reset
    w                <= SW(0);      -- SW0 as input w
    LEDG(9)          <= z;          -- Output z
    LEDG(8)          <= '0';        -- Unused LED
    LEDG(3 downto 0) <= "0000";     -- Unused LEDs

    -- State register with asynchronous reset
    process (clk, reset)
    begin
        if reset = '1' then
            current_state <= S0;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Next state logic and output
    process (current_state, w)
    begin
        -- Default output
        z                <= '0';
        LEDG(7 downto 4) <= "0000";
        next_state       <= S0; -- Default next state

        case current_state is
            when S0 =>
                LEDG(7 downto 4) <= "0000";
                if w = '1' then
                    next_state <= S1_1;
                else
                    next_state <= S1_0;
                end if;

                -- States for zeros
            when S1_0 =>
                LEDG(7 downto 4) <= "0001";
                if w = '0' then
                    next_state <= S2_0;
                else
                    next_state <= S1_1;
                end if;

            when S2_0 =>
                LEDG(7 downto 4) <= "0010";
                if w = '0' then
                    next_state <= S3_0;
                else
                    next_state <= S1_1;
                end if;

            when S3_0 =>
                LEDG(7 downto 4) <= "0011";
                if w = '0' then
                    next_state <= S4_0;
                else
                    next_state <= S1_1;
                end if;

            when S4_0 =>
                LEDG(7 downto 4) <= "0100";
                z                <= '1'; -- Only in S4_0 state
                if w = '0' then
                    next_state <= S4_0;
                else
                    next_state <= S1_1;
                end if;

                -- States for ones
            when S1_1 =>
                LEDG(7 downto 4) <= "0101";
                if w = '1' then
                    next_state <= S2_1;
                else
                    next_state <= S1_0;
                end if;

            when S2_1 =>
                LEDG(7 downto 4) <= "0110";
                if w = '1' then
                    next_state <= S3_1;
                else
                    next_state <= S1_0;
                end if;

            when S3_1 =>
                LEDG(7 downto 4) <= "0111";
                if w = '1' then
                    next_state <= S4_1;
                else
                    next_state <= S1_0;
                end if;

            when S4_1 =>
                LEDG(7 downto 4) <= "1000";
                z                <= '1'; -- Only in S4_1 state
                if w = '1' then
                    next_state <= S4_1;
                else
                    next_state <= S1_0;
                end if;

        end case;
    end process;
end Behavioral;
