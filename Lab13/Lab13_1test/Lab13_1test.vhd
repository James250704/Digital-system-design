library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Lab13_1tesst is
    port (
        SW   : in STD_LOGIC_VECTOR(9 downto 0);  -- SW9…SW0
        KEY  : in STD_LOGIC_VECTOR(2 downto 0);  -- KEY2=Clock, KEY1=Resetn, KEY0 unused
        LEDG : out STD_LOGIC_VECTOR(9 downto 0); -- LEDG9…LEDG0
        HEX3 : out STD_LOGIC_VECTOR(6 downto 0)  -- 共陽 a…g (active-low)
    );
end entity;

architecture rtl of Lab13_1tesst is

    signal DIN      : STD_LOGIC_VECTOR(8 downto 0);
    signal Run      : STD_LOGIC;
    signal Resetn   : STD_LOGIC;
    signal Clock    : STD_LOGIC;
    signal Done_sig : STD_LOGIC;
    signal BusWires : STD_LOGIC_VECTOR(8 downto 0);
    signal State2   : STD_LOGIC_VECTOR(1 downto 0);

begin

    -- SW, KEY 對應
    DIN    <= SW(8 downto 0);
    Run    <= SW(9);
    Resetn <= KEY(1);
    Clock  <= KEY(2);

    -- 實例化 9-bit processor
    u_proc : entity work.proc
        port map(
            DIN      => DIN,
            Resetn   => Resetn,
            Clock    => Clock,
            Run      => Run,
            Done     => Done_sig,
            BusWires => BusWires,
            State2   => State2
        );

    -- LEDG 映射
    LEDG(8 downto 0) <= BusWires;
    LEDG(9)          <= Done_sig;

    -- HEX3 顯示狀態 0~3（共陽，active-low）
    hex3_decode : process (State2)
    begin
        case State2 is
            when "00"   => HEX3   <= "1000000"; -- “0”
            when "01"   => HEX3   <= "1111001"; -- “1”
            when "10"   => HEX3   <= "0100100"; -- “2”
            when others => HEX3 <= "0110000";-- “3”
        end case;
    end process;

end architecture;
