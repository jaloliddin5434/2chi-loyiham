"""
Tarozi (KLAS XK3190-A9+) - to'liq diagnostika (v2).

Bu skript quyidagilarni ketma-ket sinaydi:
  1. Kompyuterda ko'rinayotgan barcha COM portlarni ro'yxatlab chiqadi
     (COM6/COM7 chalkashligini aniqlash uchun).
  2. COM6 va COM7 portlarining har birida, 600/1200/2400/4800/9600 baud
     tezliklarning har birida, RTS/DTR signallarining 4 ta kombinatsiyasida
     (standart, RTS+DTR o'chiq, faqat RTS yoqiq, faqat DTR yoqiq) qisqa vaqt
     tinglaydi.
  3. Har bir kombinatsiyada kelgan xom baytlarni HEX + ASCII ko'rinishida
     chiqaradi, STX/ETX (12 bayt) freym formatini VA D2+ oddiy matn
     ("51.070=51.070=...") formatini avtomatik aniqlashga harakat qiladi.
  4. Oxirida qaysi kombinatsiyalarda umuman ma'lumot kelgani haqida
     xulosa jadvalini chiqaradi.

Ishlatish:
    python tarozi_diag_full.py

Diqqat: to'liq tsikl ~2 daqiqa davom etadi. Skript ishlayotganda
tarozi indikatori yoqiq va D2+ uzluksiz chiqish rejimida (tF=2) bo'lishi kerak.
"""
import sys
import time

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
    import serial
    import serial.tools.list_ports

PORTS = ["COM6", "COM7"]
BAUD_RATES = [600, 1200, 2400, 4800, 9600]
# (nom, rts, dtr)
LINE_COMBINATIONS = [
    ("standart (RTS=1,DTR=1)", True, True),
    ("RTS=0,DTR=0", False, False),
    ("RTS=1,DTR=0", True, False),
    ("RTS=0,DTR=1", False, True),
]
DURATION_PER_COMBO = 2.0  # soniya
STX, ETX = 0x02, 0x03
LOG_FILE = "tarozi_diag_full.log"


def list_available_ports():
    print("=" * 70)
    print("MAVJUD COM PORTLAR:")
    print("=" * 70)
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("  Hech qanday COM port topilmadi!")
    for p in ports:
        print(f"  {p.device:8s}  {p.description}  (hwid: {p.hwid})")
    print()
    return {p.device for p in ports}


def format_bytes(data: bytes) -> str:
    hex_part = " ".join(f"{b:02X}" for b in data)
    text_part = "".join(chr(b) if 32 <= b <= 126 else "." for b in data)
    return f"HEX:  {hex_part}\n     TEXT: {text_part}"


def try_parse_stx_etx(data: bytes):
    """STX..ETX (klassik 12-bayt XK3190) freymlarini qidiradi."""
    frames = []
    i = 0
    n = len(data)
    while i < n:
        if data[i] != STX:
            i += 1
            continue
        j = data.find(bytes([ETX]), i + 1, i + 24)
        if j == -1:
            i += 1
            continue
        frames.append(data[i:j + 1])
        i = j + 1
    return frames


def try_parse_d2plus(data: bytes):
    """D2+ oddiy matn rejimini ('51.070=51.070=...') qidiradi."""
    try:
        text = data.decode("ascii", errors="strict")
    except UnicodeDecodeError:
        return []
    if "=" not in text:
        return []
    parts = [p.strip() for p in text.split("=") if p.strip()]
    values = []
    for p in parts:
        cleaned = p.lstrip("+-")
        if cleaned.replace(".", "", 1).isdigit():
            values.append(p)
    return values


def listen_combo(port, baud, rts, dtr, duration, log_f):
    try:
        with serial.Serial(
            port,
            baudrate=baud,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=0.2,
        ) as ser:
            ser.rts = rts
            ser.dtr = dtr
            buf = bytearray()
            start = time.time()
            while time.time() - start < duration:
                chunk = ser.read(256)
                if chunk:
                    buf.extend(chunk)
            return bytes(buf)
    except serial.SerialException as e:
        log_f.write(f"[{port} {baud} rts={rts} dtr={dtr}] XATO: {e}\n")
        return None


def main():
    available = list_available_ports()
    for p in PORTS:
        if p not in available:
            print(f"OGOHLANTIRISH: {p} tizimda topilmadi (yuqoridagi ro'yxatga qarang)!\n")

    results = []  # (port, baud, combo_name, byte_count, stx_frames, d2_values)

    with open(LOG_FILE, "w", encoding="utf-8") as log_f:
        total_combos = len(PORTS) * len(BAUD_RATES) * len(LINE_COMBINATIONS)
        done = 0
        for port in PORTS:
            for baud in BAUD_RATES:
                for combo_name, rts, dtr in LINE_COMBINATIONS:
                    done += 1
                    print(f"[{done}/{total_combos}] {port} @ {baud} baud, {combo_name} ...", end=" ", flush=True)
                    data = listen_combo(port, baud, rts, dtr, DURATION_PER_COMBO, log_f)
                    if data is None:
                        print("PORT OCHILMADI")
                        continue
                    if not data:
                        print("0 bayt")
                        log_f.write(f"[{port} {baud} rts={rts} dtr={dtr}] 0 bayt\n")
                        continue

                    stx_frames = try_parse_stx_etx(data)
                    d2_values = try_parse_d2plus(data)
                    print(f"{len(data)} BAYT KELDI!")
                    print("     " + format_bytes(data).replace("\n", "\n     "))
                    if stx_frames:
                        print(f"     -> {len(stx_frames)} ta STX/ETX freym topildi")
                    if d2_values:
                        preview = d2_values[:5]
                        suffix = "..." if len(d2_values) > 5 else ""
                        print(f"     -> D2+ qiymatlar: {preview}{suffix}")

                    log_f.write(f"[{port} {baud} rts={rts} dtr={dtr}] {len(data)} bayt: {data!r}\n")
                    results.append((port, baud, combo_name, len(data), len(stx_frames), len(d2_values)))

    print("\n" + "=" * 70)
    print("XULOSA")
    print("=" * 70)
    if not results:
        print("Hech qanday kombinatsiyada ma'lumot kelmadi.")
        print("Ehtimoliy sabablar:")
        print("  - Kabel yoki port haqiqatda ishlamayapti (boshqa kabel/portni sinab ko'ring)")
        print("  - Indikator hali ham noto'g'ri rejimda (tF, bt sozlamalarini qayta tekshiring)")
        print("  - COM6/COM7 aslida boshqa qurilmaga tegishli (yuqoridagi port ro'yxatiga qarang)")
    else:
        print(f"{'PORT':6s} {'BAUD':6s} {'RTS/DTR':22s} {'BAYT':6s} {'STX/ETX':8s} {'D2+':6s}")
        for port, baud, combo_name, nbytes, nstx, nd2 in results:
            print(f"{port:6s} {baud:<6d} {combo_name:22s} {nbytes:<6d} {nstx:<8d} {nd2:<6d}")
    print(f"\nTo'liq xom log: {LOG_FILE}")


if __name__ == "__main__":
    main()
