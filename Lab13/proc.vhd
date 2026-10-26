-- proc.vhd (Modified)
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all; -- For Sum <= A + BusWires etc.
-- USE ieee.numeric_std.all; -- Alternative for arithmetic, but std_logic_signed is used here.

entity proc is
    generic (
        mv  : STD_LOGIC_VECTOR(2 downto 0) := "000";
        mvi : STD_LOGIC_VECTOR(2 downto 0) := "001";
        add : STD_LOGIC_VECTOR(2 downto 0) := "010";
        sub : STD_LOGIC_VECTOR(2 downto 0) := "011"
    );
    port (
        DIN                : in STD_LOGIC_VECTOR(8 downto 0);
        Resetn, Clock, Run : in STD_LOGIC;
        Done               : buffer STD_LOGIC;
        BusWires           : buffer STD_LOGIC_VECTOR(8 downto 0);
        Current_State_Out  : out STD_LOGIC_VECTOR(1 downto 0) -- Added for HEX display
    );
end proc;

architecture Behavior of proc is
    component dec3to8
        port (
            W  : in STD_LOGIC_VECTOR(2 downto 0);
            En : in STD_LOGIC;
            Y  : out STD_LOGIC_VECTOR(0 to 7));
    end component;

    component regn
        generic (n : INTEGER := 9);
        port (
            R          : in STD_LOGIC_VECTOR(n - 1 downto 0);
            Rin, Clock : in STD_LOGIC;
            Q          : buffer STD_LOGIC_VECTOR(n - 1 downto 0));
    end component;

    type State_type is (T0, T1, T2, T3);
    signal Rin, Rout                                  : STD_LOGIC_VECTOR(0 to 7);
    signal Sum                                        : STD_LOGIC_VECTOR(8 downto 0);
    signal High, IRin, DINout, Ain, Gin, Gout, AddSub : STD_LOGIC;
    signal I                                          : STD_LOGIC_VECTOR(2 downto 0);
    signal Xreg, Yreg                                 : STD_LOGIC_VECTOR(0 to 7);
    signal R0, R1, R2, R3, R4, R5, R6, R7, A, G       : STD_LOGIC_VECTOR(8 downto 0);
    signal IR                                         : STD_LOGIC_VECTOR(8 downto 0); -- IR is 9 bits to match DIN
    signal Sel                                        : STD_LOGIC_VECTOR(9 downto 0); -- bus selector Rout(0..7), Gout, DINout
    signal Tstep_Q, Tstep_D                           : State_type;
begin
    High <= '1';
    I    <= IR(2 downto 0); -- Opcode is usually MSB. Assuming IR(8..6) or IR(2..0).
    -- "OPCODE format: III XXX YYY" means III are the MSBs.
    -- IR(8 downto 0): IIIXXXXXX. This was IR(1 TO 3) in original.
    -- If DIN(8..0) -> IR(8..0) where IR(8..6) is opcode,
    -- IR(5..3) is Rx, IR(2..0) is Ry
    -- Based on "III XXX YYY", let's assume instruction is IR(8 DOWNTO 6), Rx is IR(5 DOWNTO 3), Ry is IR(2 DOWNTO 0)
    -- Original code used IR(1 to 3) for I, IR(4 to 6) for X, IR(7 to 9) for Y.
    -- This assumes IR is indexed 1 to 9. But DIN is 8 DOWNTO 0.
    -- Let's stick to the original pdf's likely intention:
    -- DIN(8..0) is loaded into IR(8..0).
    -- Instruction bits: IR(2..0) -> I (as in original proc)
    -- Rx bits: IR(5..3) -> Xreg select
    -- Ry bits: IR(8..6) -> Yreg select
    -- This means the provided "III XXX YYY" in comment is a bit misleading for MSB-first convention.
    -- Or, IR should be IR(1 to 9) and DIN mapped carefully.
    -- Let's assume the VHDL's original indexing of IR(1..9) was intentional and needs careful DIN mapping to IR in reg_IR.
    -- However, reg_IR is defined as: reg_IR: regn GENERIC MAP (n => 9) PORT MAP (DIN(8 DOWNTO 0), IRin, Clock, IR);
    -- And IR signal is: SIGNAL IR : STD_LOGIC_VECTOR(1 TO 9);
    -- This will cause a type mismatch. IR must be (8 DOWNTO 0) to match regn's Q port.
    -- Let's correct IR declaration and subsequent slicing.
    -- SIGNAL IR : STD_LOGIC_VECTOR(8 DOWNTO 0);
    -- I <= IR(2 DOWNTO 0);      -- LSBs for instruction
    -- decX: dec3to8 PORT MAP (IR(5 DOWNTO 3), High, Xreg); -- Middle bits for Rx
    -- decY: dec3to8 PORT MAP (IR(8 DOWNTO 6), High, Yreg); -- MSBs for Ry
    -- This maps to:  DIN[8..0] -> IR[8..0]
    -- Ry_sel | Ry_sel | Ry_sel | Rx_sel | Rx_sel | Rx_sel | I_sel | I_sel | I_sel
    -- IR(8)  | IR(7)  | IR(6)  | IR(5)  | IR(4)  | IR(3)  | IR(2) | IR(1) | IR(0)

    I <= IR(2 downto 0);
    decX : dec3to8 port map(IR(5 downto 3), High, Xreg);
    decY : dec3to8 port map(IR(8 downto 6), High, Yreg);

    statetable : process (Tstep_Q, Run, Done)
    begin
        case Tstep_Q is
            when T0 => -- data is loaded into IR in this time step
                if (Run = '0') then
                    Tstep_D <= T0;
                else
                    Tstep_D <= T1;
                end if;
            when T1 => -- some instructions end after this time step    
                if (Done = '1') then
                    Tstep_D <= T0;
                else
                    Tstep_D <= T2;
                end if;
            when T2 => -- always go to T3 after this
                Tstep_D <= T3;
            when T3 => -- instructions end after this time step    
                Tstep_D <= T0;
        end case;
    end process;

    controlsignals : process (Tstep_Q, I, Xreg, Yreg)
    begin
        Done <= '0'; Ain <= '0'; Gin <= '0'; Gout <= '0'; AddSub <= '0';
        IRin <= '0'; DINout <= '0'; Rin <= (others => '0'); Rout <= (others => '0'); -- Use OTHERS for clarity
        case Tstep_Q is
            when T0 => -- store DIN in IR as long as Tstep_Q = 0
                IRin <= '1';
            when T1 => -- define signals in time step T1
                case I is
                    when mv =>    -- mv Rx,Ry
                        Rout <= Yreg; -- Yreg selects which register Rx..R7 is source
                        Rin  <= Xreg; -- Xreg selects which register Rx..R7 is dest
                        Done <= '1';
                    when mvi => -- mvi Rx,#D
                        DINout <= '1';
                        Rin    <= Xreg;
                        Done   <= '1';
                    when add =>   -- add Rx,Ry -> Rx := Rx + Ry
                        Rout <= Xreg; -- Read Rx into A
                        Ain  <= '1';
                    when sub =>   -- sub Rx,Ry -> Rx := Rx - Ry
                        Rout <= Xreg; -- Read Rx into A
                        Ain  <= '1';
                    when others => -- Undefined instruction, act like NOP or halt
                        Done <= '1';   -- Go back to T0
                end case;
            when T2 => -- define signals in time step T2
                case I is
                    when add =>     -- add
                        Rout <= Yreg;   -- Read Ry onto bus
                        Gin  <= '1';    -- G := A + Bus (Ry)
                    when sub =>     -- sub
                        Rout   <= Yreg; -- Read Ry onto bus
                        AddSub <= '1';-- Configure ALU for subtraction
                        Gin    <= '1';       -- G := A - Bus (Ry)
                    when others => null; -- mvi, mv already done
                end case;
            when T3 => -- define signals in time step T3
                case I is
                    when add =>   -- add
                        Gout <= '1';  -- Put G (result) on bus
                        Rin  <= Xreg; -- Write to Rx
                        Done <= '1';
                    when sub =>   -- sub
                        Gout <= '1';  -- Put G (result) on bus
                        Rin  <= Xreg; -- Write to Rx
                        Done <= '1';
                    when others => null; -- mvi, mv already done
                end case;
        end case;
    end process;

    fsmflipflops : process (Clock, Resetn) -- Removed Tstep_D from sensitivity list, it's synchronous
    begin
        if (Resetn = '0') then
            Tstep_Q <= T0;
        elsif (rising_edge(Clock)) then
            Tstep_Q <= Tstep_D;
        end if;
    end process;

    -- Output current state for HEX display
    state_to_vector : process (Tstep_Q)
    begin
        case Tstep_Q is
            when T0 => Current_State_Out <= "00";
            when T1 => Current_State_Out <= "01";
            when T2 => Current_State_Out <= "10";
            when T3 => Current_State_Out <= "11";
        end case;
    end process;

    reg_0 : regn port map(R => BusWires, Rin => Rin(0), Clock => Clock, Q => R0);
    reg_1 : regn port map(R => BusWires, Rin => Rin(1), Clock => Clock, Q => R1);
    reg_2 : regn port map(R => BusWires, Rin => Rin(2), Clock => Clock, Q => R2);
    reg_3 : regn port map(R => BusWires, Rin => Rin(3), Clock => Clock, Q => R3);
    reg_4 : regn port map(R => BusWires, Rin => Rin(4), Clock => Clock, Q => R4);
    reg_5 : regn port map(R => BusWires, Rin => Rin(5), Clock => Clock, Q => R5);
    reg_6 : regn port map(R => BusWires, Rin => Rin(6), Clock => Clock, Q => R6);
    reg_7 : regn port map(R => BusWires, Rin => Rin(7), Clock => Clock, Q => R7);
    reg_A : regn port map(R => BusWires, Rin => Ain, Clock => Clock, Q => A);

    -- IR register input R is DIN(8 DOWNTO 0). Output Q is IR(8 DOWNTO 0)
    reg_IR : regn generic map(n => 9) port map(R => DIN, Rin => IRin, Clock => Clock, Q => IR);

    alu : process (AddSub, A, BusWires)
    begin
        if AddSub = '0' then
            Sum <= A + BusWires;
        else
            Sum <= A - BusWires;
        end if;
    end process;

    reg_G : regn port map(R => Sum, Rin => Gin, Clock => Clock, Q => G);

    -- define the internal processor bus selector
    -- Sel is 10 bits: Rout(0..7) & Gout & DINout
    -- Rout is 0 to 7, so Rout(0) is MSB for Sel if concatenated this way
    Sel(9) <= Rout(0);
    Sel(8) <= Rout(1);
    Sel(7) <= Rout(2);
    Sel(6) <= Rout(3);
    Sel(5) <= Rout(4);
    Sel(4) <= Rout(5);
    Sel(3) <= Rout(6);
    Sel(2) <= Rout(7);
    Sel(1) <= Gout;
    Sel(0) <= DINout;

    busmux : process (Sel, R0, R1, R2, R3, R4, R5, R6, R7, G, DIN)
    begin
        -- Default assignment to prevent latches if no condition is met,
        -- though the original ELSE handles this.
        -- BusWires <= (OTHERS => 'X'); -- Or 'Z'

        if Sel(9) = '1' then -- Rout(0) selected
            BusWires <= R0;
        elsif Sel(8) = '1' then -- Rout(1) selected
            BusWires <= R1;
        elsif Sel(7) = '1' then -- Rout(2) selected
            BusWires <= R2;
        elsif Sel(6) = '1' then -- Rout(3) selected
            BusWires <= R3;
        elsif Sel(5) = '1' then -- Rout(4) selected
            BusWires <= R4;
        elsif Sel(4) = '1' then -- Rout(5) selected
            BusWires <= R5;
        elsif Sel(3) = '1' then -- Rout(6) selected
            BusWires <= R6;
        elsif Sel(2) = '1' then -- Rout(7) selected
            BusWires <= R7;
        elsif Sel(1) = '1' then -- Gout selected
            BusWires <= G;
        elsif Sel(0) = '1' then -- DINout selected
            BusWires <= DIN;
        else
            -- If nothing is actively driving the bus, what should its state be?
            -- Original code implies DIN if no other source is explicitly selected
            -- by having DIN in the final ELSE of its specific Sel vector checks.
            -- If Sel is all zeros, this means BusWires gets DIN.
            -- For safety, let's make it high-impedance or a known value if nothing selected.
            -- However, to match original behavior:
            BusWires <= DIN; -- This was the behavior of original specific Sel comparisons.
            -- More robustly, should be driven by '0' or 'Z' if no explicit Sel.
            -- But if DINout is considered the "default" source when others aren't active, this is okay.
            -- Let's assume one of the control signals (Rout(i), Gout, DINout) will be high if data is needed on bus.
            -- If all Sel bits are '0', it implies no one is intentionally driving the bus.
            -- In this case, having it default to DIN can be problematic if DINout is not what's intended.
            -- A safer default when Sel is all zeros:
            -- BusWires <= (OTHERS => '0'); -- Or (OTHERS => 'Z') if it's a tristate bus
        end if;
    end process;
end Behavior;
