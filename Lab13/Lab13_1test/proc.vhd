library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity proc is
    generic (
        mv  : STD_LOGIC_VECTOR(2 downto 0) := "000";
        mvi : STD_LOGIC_VECTOR(2 downto 0) := "001";
        add : STD_LOGIC_VECTOR(2 downto 0) := "010";
        sub : STD_LOGIC_VECTOR(2 downto 0) := "011"
    );
    port (
        DIN      : in STD_LOGIC_VECTOR(8 downto 0);
        Resetn   : in STD_LOGIC;
        Clock    : in STD_LOGIC;
        Run      : in STD_LOGIC;
        Done     : buffer STD_LOGIC;
        BusWires : buffer STD_LOGIC_VECTOR(8 downto 0);
        State2   : out STD_LOGIC_VECTOR(1 downto 0) -- 新增：輸出當前狀態（T0~T3）
    );
end entity proc;

architecture Behavior of proc is

    component dec3to8
        port (
            W  : in STD_LOGIC_VECTOR(2 downto 0);
            En : in STD_LOGIC;
            Y  : out STD_LOGIC_VECTOR(0 to 7)
        );
    end component;

    component regn
        generic (n : INTEGER := 9);
        port (
            R     : in STD_LOGIC_VECTOR(n - 1 downto 0);
            Rin   : in STD_LOGIC;
            Clock : in STD_LOGIC;
            Q     : buffer STD_LOGIC_VECTOR(n - 1 downto 0)
        );
    end component;

    type State_type is (T0, T1, T2, T3);
    signal Tstep_Q, Tstep_D : State_type;

    -- control signals
    signal Rin, Rout                                  : STD_LOGIC_VECTOR(0 to 7);
    signal Sum                                        : STD_LOGIC_VECTOR(8 downto 0);
    signal High, IRin, DINout, Ain, Gin, Gout, AddSub : STD_LOGIC;
    signal I                                          : STD_LOGIC_VECTOR(2 downto 0);
    signal Xreg, Yreg                                 : STD_LOGIC_VECTOR(0 to 7);
    signal R0, R1, R2, R3, R4, R5, R6, R7, A, G       : STD_LOGIC_VECTOR(8 downto 0);
    signal IR                                         : STD_LOGIC_VECTOR(1 to 9);
    signal Sel                                        : STD_LOGIC_VECTOR(1 to 10);

begin

    High <= '1';
    I    <= IR(1 to 3);

    -- decode register addresses
    decX : dec3to8 port map(IR(4 to 6), High, Xreg);
    decY : dec3to8 port map(IR(7 to 9), High, Yreg);

    -- 狀態機 next‐state
    statetable : process (Tstep_Q, Run, Done)
    begin
        case Tstep_Q is
            when T0 =>
                if Run = '0' then
                    Tstep_D <= T0; else
                    Tstep_D <= T1; end if;
                when T1 =>
                    if Done = '1' then
                        Tstep_D <= T0; else
                        Tstep_D <= T2; end if;
                    when T2 =>
                        Tstep_D <= T3;
                    when T3 =>
                        Tstep_D <= T0;
                    end case;
                end process;

                -- 控制信號
                controlsignals : process (Tstep_Q, I, Xreg, Yreg)
                begin
                    Done <= '0'; Ain <= '0'; Gin <= '0'; Gout <= '0'; AddSub <= '0';
                    IRin <= '0'; DINout <= '0'; Rin <= (others => '0'); Rout <= (others => '0');
                    case Tstep_Q is
                        when T0 =>
                            IRin <= '1';
                        when T1 =>
                            case I is
                                when mv =>
                                    Rout <= Yreg; Rin <= Xreg; Done <= '1';
                                when mvi =>
                                    DINout <= '1'; Rin <= Xreg; Done <= '1';
                                when add =>
                                    Rout <= Xreg; Ain <= '1';
                                when others => -- sub
                                    Rout <= Xreg; Ain <= '1';
                            end case;
                        when T2 =>
                            case I is
                                when add =>
                                    Rout <= Yreg; Gin <= '1';
                                when others => -- sub
                                    Rout <= Yreg; AddSub <= '1'; Gin <= '1';
                            end case;
                        when T3 =>
                            case I is
                                when add =>
                                    Gout <= '1'; Rin <= Xreg; Done <= '1';
                                when others => -- sub
                                    Gout <= '1'; Rin <= Xreg; Done <= '1';
                            end case;
                    end case;
                end process;

                -- 狀態觸發器
                fsmflipflops : process (Clock, Resetn)
                begin
                    if Resetn = '0' then
                        Tstep_Q <= T0;
                    elsif rising_edge(Clock) then
                        Tstep_Q <= Tstep_D;
                    end if;
                end process;

                -- 將 State_type 轉成 2-bit
                state_out : process (Tstep_Q)
                begin
                    case Tstep_Q is
                        when T0 => State2 <= "00";
                        when T1 => State2 <= "01";
                        when T2 => State2 <= "10";
                        when T3 => State2 <= "11";
                    end case;
                end process;

                -- 寄存器與 ALU、總線多路復用器
                reg_0  : regn port map(BusWires, Rin(0), Clock, R0);
                reg_1  : regn port map(BusWires, Rin(1), Clock, R1);
                reg_2  : regn port map(BusWires, Rin(2), Clock, R2);
                reg_3  : regn port map(BusWires, Rin(3), Clock, R3);
                reg_4  : regn port map(BusWires, Rin(4), Clock, R4);
                reg_5  : regn port map(BusWires, Rin(5), Clock, R5);
                reg_6  : regn port map(BusWires, Rin(6), Clock, R6);
                reg_7  : regn port map(BusWires, Rin(7), Clock, R7);
                reg_A  : regn port map(BusWires, Ain, Clock, A);
                reg_IR : regn generic map(n => 9) port map(DIN(8 downto 0), IRin, Clock, IR);

                alu : process (AddSub, A, BusWires)
                begin
                    if AddSub = '0' then
                        Sum <= A + BusWires;
                    else
                        Sum <= A - BusWires;
                    end if;
                end process;

                reg_G : regn port map(Sum, Gin, Clock, G);

                Sel <= Rout & Gout & DINout;
                busmux : process (Sel, R0, R1, R2, R3, R4, R5, R6, R7, G, DIN)
                begin
                    if Sel = "1000000000" then
                        BusWires <= R0;
                    elsif Sel = "0100000000" then
                        BusWires <= R1;
                    elsif Sel = "0010000000" then
                        BusWires <= R2;
                    elsif Sel = "0001000000" then
                        BusWires <= R3;
                    elsif Sel = "0000100000" then
                        BusWires <= R4;
                    elsif Sel = "0000010000" then
                        BusWires <= R5;
                    elsif Sel = "0000001000" then
                        BusWires <= R6;
                    elsif Sel = "0000000100" then
                        BusWires <= R7;
                    elsif Sel = "0000000010" then
                        BusWires <= G;
                    else
                        BusWires <= DIN;
                    end if;
                end process;
        end architecture Behavior;
