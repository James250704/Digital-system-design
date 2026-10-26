library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab12_2 is
    port (
        -- Clock and Reset Inputs
        CLOCK_50 : in STD_LOGIC;                -- System Clock (e.g., 50MHz)
        KEY      : in STD_LOGIC_VECTOR(0 to 0); -- Active-low asynchronous reset for square position

        -- PS2 Keyboard Inputs
        PS2_CLK  : in STD_LOGIC; -- PS/2 Clock line
        PS2_DATA : in STD_LOGIC; -- PS/2 Data line

        -- VGA Outputs
        VGA_HS : out STD_LOGIC;
        VGA_VS : out STD_LOGIC;
        VGA_R  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end entity Lab12_2;

architecture behavior of Lab12_2 is

    -- VGA Timing Constants for 640x480 @ 60Hz
    constant H_DISPLAY_AREA : INTEGER := 640;
    constant H_FRONT_PORCH  : INTEGER := 8;
    constant H_SYNC_PULSE   : INTEGER := 96;
    constant H_BACK_PORCH   : INTEGER := 56;
    constant H_TOTAL_PERIOD : INTEGER := H_DISPLAY_AREA + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; -- 800

    constant V_DISPLAY_AREA : INTEGER := 480;
    constant V_FRONT_PORCH  : INTEGER := 10;
    constant V_SYNC_PULSE   : INTEGER := 2;
    constant V_BACK_PORCH   : INTEGER := 33;
    constant V_TOTAL_PERIOD : INTEGER := V_DISPLAY_AREA + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; -- 525

    -- Signals for VGA timing generation
    signal pixel_clk_enable : STD_LOGIC            := '0';
    signal pixel_clk_count  : INTEGER range 0 to 1 := 0;

    signal h_counter : INTEGER range 0 to H_TOTAL_PERIOD - 1 := 0;
    signal v_counter : INTEGER range 0 to V_TOTAL_PERIOD - 1 := 0;

    signal internal_video_on  : STD_LOGIC;
    signal internal_pixel_row : INTEGER range 0 to V_DISPLAY_AREA - 1;
    signal internal_pixel_col : INTEGER range 0 to H_DISPLAY_AREA - 1;

    -- Square properties
    constant SQUARE_SIZE      : INTEGER := 20;
    constant MOVE_STEP        : INTEGER := 20;
    constant INITIAL_SQUARE_X : INTEGER := (H_DISPLAY_AREA - SQUARE_SIZE) / 2; -- 310
    constant INITIAL_SQUARE_Y : INTEGER := (V_DISPLAY_AREA - SQUARE_SIZE) / 2; -- 230

    signal square_x_pos : INTEGER range 0 to H_DISPLAY_AREA := INITIAL_SQUARE_X;
    signal square_y_pos : INTEGER range 0 to V_DISPLAY_AREA := INITIAL_SQUARE_Y;

    -- Max positions for the top-left corner of the square
    constant MAX_SQUARE_X : INTEGER := H_DISPLAY_AREA - SQUARE_SIZE; -- 620
    constant MAX_SQUARE_Y : INTEGER := V_DISPLAY_AREA - SQUARE_SIZE; -- 460

    -- PS2 Keyboard Interface Signals (for raw scan codes used for arrow keys)
    signal raw_ps2_code_new_s      : STD_LOGIC;
    signal raw_ps2_code_s          : STD_LOGIC_VECTOR(7 downto 0);
    signal prev_raw_ps2_code_new_s : STD_LOGIC := '0'; -- For edge detection

    -- PS2 Scan Code Processing State (for raw scan codes)
    type ps2_processing_state is (S_IDLE, S_E0_RECEIVED, S_BREAK_RECEIVED);
    signal kbd_state : ps2_processing_state := S_IDLE;

    -- Signals for ps2_keyboard_to_ascii outputs (instantiated but not used for arrow logic)
    signal ascii_output_new_s  : STD_LOGIC;
    signal ascii_output_code_s : STD_LOGIC_VECTOR(6 downto 0);

    -- Color definitions (12-bit RGB: 4-bit R, 4-bit G, 4-bit B)
    constant COLOR_WHITE       : STD_LOGIC_VECTOR(11 downto 0) := x"FFF";
    constant COLOR_BLACK       : STD_LOGIC_VECTOR(11 downto 0) := x"000";
    signal current_pixel_color : STD_LOGIC_VECTOR(11 downto 0);

    -- Internal reset
    signal reset_n_internal : STD_LOGIC;

    -- Clock frequency generic for PS/2 modules
    constant SYS_CLK_FREQ : INTEGER := 50_000_000; -- Assuming 50MHz from CLOCK_50

begin

    reset_n_internal <= KEY(0); -- KEY0 is active-low

    -- Instance 1: ps2_keyboard (for raw scan codes needed for arrow keys)
    ps2_raw_code_inst : entity work.ps2_keyboard
        generic map(
            clk_freq              => SYS_CLK_FREQ,
            debounce_counter_size => 8 -- Default from ps2_keyboard, suitable for 50MHz
        )
        port map(
            clk          => CLOCK_50,
            ps2_clk      => PS2_CLK,
            ps2_data     => PS2_DATA,
            ps2_code_new => raw_ps2_code_new_s,
            ps2_code     => raw_ps2_code_s
        );

    ps2_ascii_conversion_inst : entity work.ps2_keyboard_to_ascii
        generic map(
            clk_freq                  => SYS_CLK_FREQ,
            ps2_debounce_counter_size => 8
        )
        port map(
            clk        => CLOCK_50,
            ps2_clk    => PS2_CLK,
            ps2_data   => PS2_DATA,
            ascii_new  => ascii_output_new_s,
            ascii_code => ascii_output_code_s
        );

    -- Pixel Clock Generator (25MHz from 50MHz CLOCK_50)
    pixel_clk_generator : process (CLOCK_50, reset_n_internal)
    begin
        if reset_n_internal = '0' then
            pixel_clk_count  <= 0;
            pixel_clk_enable <= '0';
        elsif rising_edge(CLOCK_50) then
            if pixel_clk_count = 0 then
                pixel_clk_enable <= '1';
                pixel_clk_count  <= 1;
            else
                pixel_clk_enable <= '0';
                pixel_clk_count  <= 0;
            end if;
        end if;
    end process pixel_clk_generator;

    -- VGA Timing Generation
    vga_timing_logic : process (CLOCK_50, reset_n_internal)
    begin
        if reset_n_internal = '0' then
            h_counter          <= 0;
            v_counter          <= 0;
            VGA_HS             <= '1';
            VGA_VS             <= '1';
            internal_video_on  <= '0';
            internal_pixel_col <= 0;
            internal_pixel_row <= 0;
        elsif rising_edge(CLOCK_50) then
            if pixel_clk_enable = '1' then
                if h_counter < H_TOTAL_PERIOD - 1 then
                    h_counter <= h_counter + 1;
                else
                    h_counter <= 0;
                    if v_counter < V_TOTAL_PERIOD - 1 then
                        v_counter <= v_counter + 1;
                    else
                        v_counter <= 0;
                    end if;
                end if;

                if h_counter >= H_DISPLAY_AREA + H_FRONT_PORCH and
                    h_counter < H_DISPLAY_AREA + H_FRONT_PORCH + H_SYNC_PULSE then
                    VGA_HS <= '0';
                else
                    VGA_HS <= '1';
                end if;

                if v_counter >= V_DISPLAY_AREA + V_FRONT_PORCH and
                    v_counter < V_DISPLAY_AREA + V_FRONT_PORCH + V_SYNC_PULSE then
                    VGA_VS <= '0';
                else
                    VGA_VS <= '1';
                end if;

                if (h_counter < H_DISPLAY_AREA) and (v_counter < V_DISPLAY_AREA) then
                    internal_video_on  <= '1';
                    internal_pixel_col <= h_counter;
                    internal_pixel_row <= v_counter;
                else
                    internal_video_on <= '0';
                end if;
            end if;
        end if;
    end process vga_timing_logic;

    -- Keyboard Input Processing (using raw_ps2_code from ps2_raw_code_inst) and Square Movement
    square_control_process : process (CLOCK_50, reset_n_internal)
        variable temp_x, temp_y : INTEGER;
    begin
        if reset_n_internal = '0' then
            square_x_pos <= INITIAL_SQUARE_X;
            square_y_pos <= INITIAL_SQUARE_Y;
            kbd_state    <= S_IDLE;
        elsif rising_edge(CLOCK_50) then
            prev_raw_ps2_code_new_s <= raw_ps2_code_new_s; -- For edge detection

            if raw_ps2_code_new_s = '1' and prev_raw_ps2_code_new_s = '0' then -- New raw PS/2 code
                case kbd_state is
                    when S_IDLE =>
                        if raw_ps2_code_s = x"E0" then
                            kbd_state <= S_E0_RECEIVED;
                        elsif raw_ps2_code_s = x"F0" then
                            kbd_state <= S_BREAK_RECEIVED;
                        else
                            null;
                        end if;

                    when S_E0_RECEIVED => -- This is the key after E0 (make code)
                        temp_x := square_x_pos;
                        temp_y := square_y_pos;
                        case raw_ps2_code_s is
                            when x"74" => -- Right Arrow
                                temp_x := square_x_pos + MOVE_STEP;
                                if temp_x > MAX_SQUARE_X then
                                    temp_x := MAX_SQUARE_X; end if;
                                    square_x_pos <= temp_x;
                                when x"6B" => -- Left Arrow
                                    temp_x := square_x_pos - MOVE_STEP;
                                    if temp_x < 0 then
                                        temp_x := 0; end if;
                                        square_x_pos <= temp_x;
                                    when x"75" => -- Up Arrow
                                        temp_y := square_y_pos - MOVE_STEP;
                                        if temp_y < 0 then
                                            temp_y := 0; end if;
                                            square_y_pos <= temp_y;
                                        when x"72" => -- Down Arrow
                                            temp_y := square_y_pos + MOVE_STEP;
                                            if temp_y > MAX_SQUARE_Y then
                                                temp_y := MAX_SQUARE_Y; end if;
                                                square_y_pos <= temp_y;
                                            when others => null;
                                            end case;
                                            kbd_state <= S_IDLE;

                                        when S_BREAK_RECEIVED => -- Key after F0 (break code)
                                            kbd_state <= S_IDLE;     -- We ignore break codes for movement
                                        end case;
                                    end if;
                                end if;
                        end process square_control_process;

                        -- Pixel Drawing Logic
                        pixel_drawing_logic : process (internal_video_on, internal_pixel_col, internal_pixel_row, square_x_pos, square_y_pos)
                        begin
                            if internal_video_on = '1' then
                                if internal_pixel_col >= square_x_pos and internal_pixel_col < (square_x_pos + SQUARE_SIZE) and
                                    internal_pixel_row >= square_y_pos and internal_pixel_row < (square_y_pos + SQUARE_SIZE) then
                                    current_pixel_color <= COLOR_WHITE;
                                else
                                    current_pixel_color <= COLOR_BLACK;
                                end if;
                            else
                                current_pixel_color <= COLOR_BLACK; -- Blanking interval
                            end if;
                        end process pixel_drawing_logic;

                        -- VGA Output Assignment (Registered on Pixel Clock)
                        vga_output_assignment : process (CLOCK_50, reset_n_internal)
                        begin
                            if reset_n_internal = '0' then
                                VGA_R <= (others => '0');
                                VGA_G <= (others => '0');
                                VGA_B <= (others => '0');
                            elsif rising_edge(CLOCK_50) then
                                if pixel_clk_enable = '1' then
                                    VGA_R <= current_pixel_color(11 downto 8);
                                    VGA_G <= current_pixel_color(7 downto 4);
                                    VGA_B <= current_pixel_color(3 downto 0);
                                end if;
                            end if;
                        end process vga_output_assignment;
                end if;
            end process square_control_process;
        end if;
    end process vga_output_assignment;
end architecture behavior;
