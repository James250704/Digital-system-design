library verilog;
use verilog.vl_types.all;
entity Lab04_2_vlg_sample_tst is
    port(
        KEY             : in     vl_logic_vector(1 downto 0);
        SW              : in     vl_logic_vector(5 downto 0);
        sampler_tx      : out    vl_logic
    );
end Lab04_2_vlg_sample_tst;
