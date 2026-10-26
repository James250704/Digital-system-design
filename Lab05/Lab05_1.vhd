library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Lab05_1 is
    port (
        SW   : in STD_LOGIC_VECTOR(7 downto 0);
        KEY  : in STD_LOGIC_VECTOR(2 downto 0);
        HEX1 : out STD_LOGIC_VECTOR(6 downto 0);
        HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
        LEDG : out STD_LOGIC_VECTOR(9 to 9)
    );
end Lab05_1;

architecture Behavioral of Lab05_1 is
    signal A_int, B_int       : signed(3 downto 0);
    signal result_int         : signed(7 downto 0);
    signal abs_result         : unsigned(7 downto 0);
    signal op_active          : STD_LOGIC;
    signal tens, ones         : STD_LOGIC_VECTOR(3 downto 0);
    signal seg_tens, seg_ones : STD_LOGIC_VECTOR(6 downto 0);
    signal opcode             : STD_LOGIC;

    component decoder is
        port (
            digit : in STD_LOGIC_VECTOR(3 downto 0);
            seg   : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
begin
    A_int <= signed(SW(7 downto 4));
    B_int <= signed(SW(3 downto 0));

    process (A_int, B_int, KEY)
        variable temp : signed(7 downto 0);
    begin
        if (KEY = "110") then
            temp := resize(A_int, 8) + resize(B_int, 8);
            opcode <= '1';
        elsif (KEY = "101") then
            temp := resize(A_int, 8) - resize(B_int, 8);
            opcode <= '1';
        elsif (KEY = "011") then
            temp := A_int * B_int;
            opcode <= '1';
        else
            temp := (others => '0');
            opcode <= '0';
        end if;
        result_int <= temp;
    end process;

    LEDG <= "1" when (result_int < 0 and opcode = '1') else
        "0";
    abs_result <= to_unsigned(abs(to_integer(result_int)), 8);

    process (abs_result)
        variable val          : INTEGER;
        variable tmp_t, tmp_o : INTEGER;
    begin
        val   := to_integer(abs_result);
        tmp_t := (val mod 100) / 10;
        tmp_o := val mod 10;
        if (val < 10) then
            tens <= "1111";
        else
            tens <= STD_LOGIC_VECTOR(to_unsigned(tmp_t, 4));
        end if;
        ones <= STD_LOGIC_VECTOR(to_unsigned(tmp_o, 4));
    end process;

    U_seg_tens : decoder
    port map(
        digit => tens,
        seg   => seg_tens
    );

    U_seg_ones : decoder
    port map(
        digit => ones,
        seg   => seg_ones
    );

    HEX1 <= seg_tens when opcode = '1' else
        "1111111";
    HEX0 <= seg_ones when opcode = '1' else
        "1111111";
end Behavioral;
