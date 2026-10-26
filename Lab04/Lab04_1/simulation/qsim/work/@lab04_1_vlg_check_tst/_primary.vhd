library verilog;
use verilog.vl_types.all;
entity Lab04_1_vlg_check_tst is
    port(
        HEX0            : in     vl_logic_vector(6 downto 0);
        HEX1            : in     vl_logic_vector(6 downto 0);
        sampler_rx      : in     vl_logic
    );
end Lab04_1_vlg_check_tst;
