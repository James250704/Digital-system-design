def calculate_divider(clock_freq_hz, target_freq_hz):
    """
    計算 VHDL 除頻器所需的 DIVIDER 值。
    :param clock_freq_hz: 輸入時脈頻率（Hz）
    :param target_freq_hz: 輸出時脈頻率（Hz）
    :return: 適用於 VHDL 的 DIVIDER 整數
    """
    if target_freq_hz <= 0 or clock_freq_hz <= 0:
        raise ValueError("頻率必須為正數")
    divider = int(clock_freq_hz / (2 * target_freq_hz)) - 1
    return divider

if __name__ == "__main__":
    clock_freq = 50_000_000  # 固定為 50MHz

    try:
        target_freq = float(input("請輸入目標頻率（Hz，例如輸入 5 表示 5Hz）："))
        divider = calculate_divider(clock_freq, target_freq)
        print(f"\n👉 輸出 {target_freq}Hz 所需的 DIVIDER 是：{divider}")
        print(f"VHDL 可寫為：constant DIVIDER : INTEGER := {divider};")
    except ValueError:
        print("❌ 請輸入正確的數字格式，例如 1、10、1000...")