library verilog;
use verilog.vl_types.all;
entity Lab04_1_vlg_sample_tst is
    port(
        SW              : in     vl_logic_vector(3 downto 0);
        sampler_tx      : out    vl_logic
    );
end Lab04_1_vlg_sample_tst;
