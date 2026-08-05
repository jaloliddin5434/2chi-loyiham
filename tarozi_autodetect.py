"""
Tarozi (KLAS XK3190-A9+) - 9600 baud, freym formatini AVTOMATIK aniqlash.

Qattiq 12-bayt taxmin o'rniga, xom oqimdagi haqiqiy STX(0x02)/ETX(0x03)
belgilaridan freym chegaralarini topadi (freym uzunligi o'zgaruvchan
bo'lishi mumkin - masalan leading-zero suppression tufayli), so'ngra
har bir freym uchun bir nechta checksum algoritmini sinab, qaysi biri
eng ko'p mos kelishini aniqlaydi.

20 soniya davomida tinglaydi - shu payt tarozi ustidagi og'irlikni
bir necha marta o'zgartiring (turli qiymatlar bilan sinash foydali).
"""
import sys
import time
from collections import Counter, defaultdict

try:
    import serial
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
    import serial

PORT = "COM6"
BAUD = 9600
DURATION = 20
STX = 0x02
ETX = 0x03
MAX_FRAME_SEARCH = 24  # ETX dan keyin shuncha bayt ichida qidiramiz
LOG_FILE = "tarozi_raw_capture.log"


def capture(port: str, baud: int, duration: float) -> bytes:
    print(f"Port: {port}, tezlik: {baud}, davomiyligi: {duration}s")
    print("Tarozi ustidagi og'irlikni bir necha marta o'zgartiring...\n")
    buf = bytearray()
    with serial.Serial(
        port,
        baudrate=baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=0.2,
    ) as ser:
        start = time.time()
        while time.time() - start < duration:
            chunk = ser.read(256)
            if chunk:
                buf.extend(chunk)
                print("RAW: " + " ".join(f"{b:02X}" for b in chunk))
    return bytes(buf)


def extract_frames(data: bytes):
    """STX..ETX oralig'idagi bloklarni (ikkalasini ham qo'shib) qaytaradi."""
    frames = []
    i = 0
    n = len(data)
    while i < n:
        if data[i] != STX:
            i += 1
            continue
        # keyingi ETX ni qidiramiz
        j = i + 1
        limit = min(n, i + 1 + MAX_FRAME_SEARCH)
        etx_pos = None
        while j < limit:
            if data[j] == ETX:
                etx_pos = j
                break
            j += 1
        if etx_pos is None:
            i += 1
            continue
        frames.append(data[i:etx_pos + 1])
        i = etx_pos + 1
    return frames


def checksum_candidates(frame: bytes):
    """(nom, hisoblangan_qiymat) juftliklari ro'yxatini qaytaradi.
    Checksum bayti frame[-2] deb faraz qilinadi (ETX dan oldingi bayt)."""
    if len(frame) < 4:
        return []
    body_incl_stx = frame[0:-2]   # STX ... (checksumgacha)
    body_excl_stx = frame[1:-2]   # sign ... (checksumgacha)
    body_excl_dec = frame[1:-3] if len(frame) >= 5 else b""  # decimal baytisiz

    def xor_of(b):
        r = 0
        for x in b:
            r ^= x
        return r

    def sum_of(b):
        return sum(b) % 256

    def twos_comp(b):
        return (0x100 - sum(b)) % 256

    return [
        ("XOR(sign..dec)", xor_of(body_excl_stx)),
        ("XOR(STX..dec)", xor_of(body_incl_stx)),
        ("SUM(sign..dec)%256", sum_of(body_excl_stx)),
        ("SUM(STX..dec)%256", sum_of(body_incl_stx)),
        ("2COMP(sign..dec)", twos_comp(body_excl_stx)),
        ("2COMP(STX..dec)", twos_comp(body_incl_stx)),
        ("XOR(sign..digits, dec siz)", xor_of(body_excl_dec)),
        ("SUM(sign..digits, dec siz)%256", sum_of(body_excl_dec)),
    ]


def try_parse_weight(frame: bytes):
    """STX+sign+digits+decimal+checksum+ETX tuzilishini o'zgaruvchan
    digit-uzunlik bilan sinaydi. Muvaffaqiyatsiz bo'lsa None qaytaradi."""
    if len(frame) < 5:
        return None
    sign_byte = chr(frame[1])
    if sign_byte not in ("+", "-"):
        return None
    decimal_byte = chr(frame[-3])
    if not decimal_byte.isdigit():
        return None
    digits = frame[2:-3]
    if not digits or not all(48 <= b <= 57 for b in digits):
        return None
    digit_str = digits.decode("ascii")
    decimals = int(decimal_byte)
    if decimals > len(digit_str):
        return None
    if decimals > 0:
        int_part = digit_str[:-decimals] or "0"
        frac_part = digit_str[-decimals:]
        value = float(f"{int_part}.{frac_part}")
    else:
        value = float(digit_str)
    if sign_byte == "-":
        value = -value
    return value


def main():
    raw = capture(PORT, BAUD, DURATION)

    with open(LOG_FILE, "wb") as f:
        f.write(raw)
    print(f"\nXom baytlar saqlandi: {LOG_FILE} ({len(raw)} bayt)\n")

    frames = extract_frames(raw)
    print(f"Topilgan STX..ETX freymlar soni: {len(frames)}\n")
    if not frames:
        print("Hech qanday STX/ETX juftligi topilmadi.")
        print("=> 1-yo'l (dasturiy) ishlamadi. D2+ oddiy matn rejimiga o'tishni tavsiya qilaman:")
        print('   Indikatorda: Print set -> 98 -> "tF" ni "2" ga o\'zgartiring.')
        return

    length_hist = Counter(len(f) for f in frames)
    print("Freym uzunliklari taqsimoti (bayt -> soni):")
    for length, count in sorted(length_hist.items()):
        print(f"  {length:2d} bayt : {count}")
    print()

    match_counts = defaultdict(int)
    match_total = 0
    for frame in frames:
        candidates = checksum_candidates(frame)
        if not candidates:
            continue
        match_total += 1
        actual = frame[-2]
        for name, computed in candidates:
            if computed == actual:
                match_counts[name] += 1

    print("Checksum algoritmlari mos kelish darajasi (mos / jami):")
    ranked = sorted(match_counts.items(), key=lambda kv: kv[1], reverse=True)
    if not ranked:
        print("  Hech biri hech qachon mos kelmadi.")
    for name, count in ranked:
        pct = 100 * count / match_total if match_total else 0
        print(f"  {name:32s}: {count:3d} / {match_total}  ({pct:.0f}%)")

    best_name, best_count = ranked[0] if ranked else (None, 0)
    best_pct = 100 * best_count / match_total if match_total else 0

    print()
    if best_pct >= 90:
        print(f"=> Yaxshi natija: '{best_name}' algoritmi {best_pct:.0f}% freymlarda mos keldi.")
        print("   Shu algoritm bilan freymlarni tahlil qilib, og'irlikni chiqaramiz:\n")
        for frame in frames:
            value = try_parse_weight(frame)
            hexs = " ".join(f"{b:02X}" for b in frame)
            if value is not None:
                print(f"  [{hexs}]  ->  {value:.3f} kg")
            else:
                print(f"  [{hexs}]  ->  (parslanmadi)")
    else:
        print(f"=> Eng yaxshi topilgan algoritm ham faqat {best_pct:.0f}% mos keldi - bu ishonchli emas.")
        print("=> 1-yo'l (dasturiy aniqlash) natija bermadi.")
        print("=> MUQOBIL: D2+ oddiy matn (checksumsiz) rejimiga o'ting:")
        print('   Indikatorda: Print set -> 98 -> "tF" ni "2" ga o\'zgartiring.')
        print("   Shundan keyin indikator \"51.07000=51.07000=...\" ko'rinishida matn yuboradi,")
        print("   buni tahlil qilish ancha oddiy va ishonchli bo'ladi.")


if __name__ == "__main__":
    main()
