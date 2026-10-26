library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity decoder is
    port (
        digit : in STD_LOGIC_VECTOR(3 downto 0); -- 0~9 的4位元輸入
        seg   : out STD_LOGIC_VECTOR(6 downto 0) -- 7段顯示器輸出
    );
end decoder;

architecture Behavioral of decoder is
begin
    process (digit)
    begin
        case digit is
            when "0000" => seg <= "1000000"; -- 顯示 0
            when "0001" => seg <= "1111001"; -- 顯示 1
            when "0010" => seg <= "0100100"; -- 顯示 2
            when "0011" => seg <= "0110000"; -- 顯示 3
            when "0100" => seg <= "0011001"; -- 顯示 4
            when "0101" => seg <= "0010010"; -- 顯示 5
            when "0110" => seg <= "0000010"; -- 顯示 6
            when "0111" => seg <= "1111000"; -- 顯示 7
            when "1000" => seg <= "0000000"; -- 顯示 8
            when "1001" => seg <= "0010000"; -- 顯示 9
            when others => seg <= "1111111"; -- 關閉或空白
        end case;
    end process;
end Behavioral;
