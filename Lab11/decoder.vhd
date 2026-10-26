library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity decoder is
    port (
        digit : in STD_LOGIC_VECTOR(4 downto 0); -- 5位元輸入，但只使用低4位
        seg   : out STD_LOGIC_VECTOR(6 downto 0) -- 7段顯示器輸出
    );
end decoder;

architecture Behavioral of decoder is
begin
    process (digit)
    begin
        case digit is
            when "00000" => seg <= "1000000";  -- 顯示 0
            when "00001" => seg <= "1111001";  -- 顯示 1
            when "00010" => seg <= "0100100";  -- 顯示 2
            when "00011" => seg <= "0110000";  -- 顯示 3
            when "00100" => seg <= "0011001";  -- 顯示 4
            when "00101" => seg <= "0010010";  -- 顯示 5
            when "00110" => seg <= "0000010";  -- 顯示 6
            when "00111" => seg <= "1111000";  -- 顯示 7
            when "01000" => seg <= "0000000";  -- 顯示 8
            when "01001" => seg <= "0010000";  -- 顯示 9
            when "01010" => seg <= "0001000";  -- 顯示 A
            when "01011" => seg <= "0000011";  -- 顯示 b
            when "01100" => seg <= "0100111";  -- 顯示 c
            when "01101" => seg <= "0100001";  -- 顯示 d
            when "01110" => seg <= "0000110";  -- 顯示 E
            when "01111" => seg <= "0001110";  -- 顯示 F
            when others  => seg  <= "1111111"; -- 關閉或空白
        end case;
    end process;
end Behavioral;
