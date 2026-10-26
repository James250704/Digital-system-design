-- Lab13_1.vhd
library ieee;
use ieee.std_logic_1164.all;

entity Lab13_1 is
    port (
        -- Inputs
        SW  : in STD_LOGIC_VECTOR(9 downto 0); -- SW9 for Run, SW8-0 for DIN
        KEY : in STD_LOGIC_VECTOR(3 downto 0); -- KEY(1) for Resetn, KEY(2) for Clock

        -- Outputs
        LEDG : out STD_LOGIC_VECTOR(9 downto 0); -- LEDG9 for Done, LEDG8-0 for BusWires
        HEX3 : out STD_LOGIC_VECTOR(6 downto 0)  -- To display current state (0-3)
    );
end Lab13_1;

architecture Behavior of Lab13_1 is
    -- Component declaration for the processor
    component proc
        port (
            DIN                : in STD_LOGIC_VECTOR(8 downto 0);
            Resetn, Clock, Run : in STD_LOGIC;
            Done               : buffer STD_LOGIC;
            BusWires           : buffer STD_LOGIC_VECTOR(8 downto 0);
            Current_State_Out  : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    -- Internal signals to connect to the processor
    signal s_proc_DIN           : STD_LOGIC_VECTOR(8 downto 0);
    signal s_proc_Run           : STD_LOGIC;
    signal s_proc_Resetn        : STD_LOGIC;
    signal s_proc_Clock         : STD_LOGIC;
    signal s_proc_Done          : STD_LOGIC;
    signal s_proc_BusWires      : STD_LOGIC_VECTOR(8 downto 0);
    signal s_proc_Current_State : STD_LOGIC_VECTOR(1 downto 0);

begin
    -- Connect board inputs to processor inputs
    s_proc_DIN    <= SW(8 downto 0);
    s_proc_Run    <= SW(9);
    s_proc_Resetn <= KEY(1); -- KEY(1) is active-low
    s_proc_Clock  <= KEY(2); -- Use KEY(2) directly as clock. Note: push buttons bounce.

    -- Instantiate the processor
    processor_inst : proc
    port map(
        DIN               => s_proc_DIN,
        Run               => s_proc_Run,
        Resetn            => s_proc_Resetn,
        Clock             => s_proc_Clock,
        Done              => s_proc_Done,
        BusWires          => s_proc_BusWires,
        Current_State_Out => s_proc_Current_State
    );

    -- Connect processor outputs to board outputs
    LEDG(8 downto 0) <= s_proc_BusWires;
    LEDG(9)          <= s_proc_Done;

    -- 7-Segment Display Driver for HEX3 to show current state (0, 1, 2, 3)
    -- HEX displays on DE0 are common anode, so '0' lights up a segment.
    -- Segments: HEX3(0)=a, HEX3(1)=b, ..., HEX3(6)=g
    seven_seg_decoder : process (s_proc_Current_State)
    begin
        case s_proc_Current_State is
            when "00" =>       -- Display '0' (State T0)
                HEX3 <= "1000000"; -- gfedcba (segment 'g' is off)
            when "01" =>       -- Display '1' (State T1)
                HEX3 <= "1111001"; -- gfedcba (segments 'b' and 'c' are on)
            when "10" =>       -- Display '2' (State T2)
                HEX3 <= "0100100"; -- gfedcba
            when "11" =>       -- Display '3' (State T3)
                HEX3 <= "0110000"; -- gfedcba
            when others =>     -- Should not happen
                HEX3 <= "0000000"; -- All segments on (error or undefined)
        end case;
    end process seven_seg_decoder;

end Behavior;
