library verilog;
use verilog.vl_types.all;
entity Lab04_2 is
    port(
        SW              : in     vl_logic_vector(5 downto 0);
        KEY             : in     vl_logic_vector(1 downto 0);
        LEDG            : out    vl_logic_vector(3 downto 0);
        HEX0            : out    vl_logic_vector(6 downto 0);
        HEX1            : out    vl_logic_vector(6 downto 0)
    );
end Lab04_2;
