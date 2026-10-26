library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity test is
    port (
        SW   : in STD_LOGIC_VECTOR(7 downto 0);  -- A = SW(7 downto 4), B = SW(3 downto 0)
        KEY  : in STD_LOGIC_VECTOR(2 downto 0);  -- Operation select
        HEX0 : out STD_LOGIC_VECTOR(6 downto 0); -- Ones digit display
        HEX1 : out STD_LOGIC_VECTOR(6 downto 0); -- Tens digit display
        LEDG : out STD_LOGIC_VECTOR(9 downto 9)  -- Negative result indicator
    );
end test;

architecture Behavioral of test is

    -- Component declaration for the 7-segment decoder
    component seven_seg_decoder
        port (
            digit : in STD_LOGIC_VECTOR(3 downto 0);
            seg   : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    -- Internal signals
    signal A, B           : INTEGER range -8 to 7;
    signal result         : INTEGER range -64 to 64;
    signal abs_result     : INTEGER range 0 to 64;
    signal tens_digit     : INTEGER range 0 to 9;
    signal ones_digit     : INTEGER range 0 to 9;
    signal tens_digit_slv : STD_LOGIC_VECTOR(3 downto 0);
    signal ones_digit_slv : STD_LOGIC_VECTOR(3 downto 0);
    signal op_valid       : BOOLEAN;

    -- Intermediate signals for decoder outputs
    signal tens_decoder : STD_LOGIC_VECTOR(6 downto 0);
    signal ones_decoder : STD_LOGIC_VECTOR(6 downto 0);

begin

    -- Convert the 4-bit two's complement numbers to integers
    A <= to_integer(signed(SW(7 downto 4)));
    B <= to_integer(signed(SW(3 downto 0)));

    -- Compute the result based on the KEY input and determine if the operation is valid.
    process (SW, KEY)
    begin
        op_valid <= false;
        result   <= 0;
        LEDG     <= "0";

        if KEY = "110" then -- Addition
            result   <= A + B;
            op_valid <= true;
        elsif KEY = "101" then -- Subtraction
            result   <= A - B;
            op_valid <= true;
        elsif KEY = "011" then -- Multiplication
            result   <= A * B;
            op_valid <= true;
        end if;

        if op_valid then
            if result < 0 then
                LEDG       <= "1";
                abs_result <= - result;
            else
                abs_result <= result;
            end if;
        else
            abs_result <= 0; -- Default value when no valid operation is selected
        end if;

        -- Convert absolute result to tens and ones digits
        tens_digit <= abs_result / 10;
        ones_digit <= abs_result mod 10;
    end process;

    -- Convert the integer digits to 4-bit std_logic_vectors for the decoder
    tens_digit_slv <= STD_LOGIC_VECTOR(to_unsigned(tens_digit, 4));
    ones_digit_slv <= STD_LOGIC_VECTOR(to_unsigned(ones_digit, 4));

    -- Instantiate the seven-segment decoders for the tens and ones digits
    Tens : seven_seg_decoder port map(
        digit => tens_digit_slv,
        seg   => tens_decoder
    );

    Ones : seven_seg_decoder port map(
        digit => ones_digit_slv,
        seg   => ones_decoder
    );

    -- Drive the HEX displays: if a valid operation is selected, use the decoder outputs;
    -- otherwise, display blank (all segments off)
    HEX1 <= tens_decoder when op_valid else
        "1111111";
    HEX0 <= ones_decoder when op_valid else
        "1111111";

end Behavioral;
