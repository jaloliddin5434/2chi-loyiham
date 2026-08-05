"""
Tarozi (KLAS XK3190-A9+) - 9600 baud, freym tahlili.
Standart XK3190-A9 protokoli (12 bayt):
  [0]  STX (0x02)
  [1]  Ishora ('+' yoki '-')
  [2-7] Og'irlik, 6 ta ASCII raqam (kasr nuqtasiz)
  [8]  Kasr nuqta pozitsiyasi, ASCII '0'-'5' (necha xona kasr qismida)
  [9]  Checksum (bayt [1..8] ning XOR yig'indisi)
  [10] ETX (0x03)
  [11] CR (0x0D)

15 soniya davomida portni tinglaydi, har bir freymni RAW HEX va
tahlil qilingan og'irlik ("12.5 kg") ko'rinishida chiqaradi.
"""
import sys
import time

try:
    import serial
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
    import serial

PORT = "COM9"
BAUD = 9600
DURATION = 15
STX = 0x02
ETX = 0x03
FRAME_LEN = 12


def parse_frame(frame: bytes):
    if len(frame) != FRAME_LEN:
        return None
    if frame[0] != STX or frame[10] != ETX:
        return None

    sign_byte = chr(frame[1])
    digits = frame[2:8]
    decimal_byte = chr(frame[8])
    checksum_byte = frame[9]

    if not all(48 <= b <= 57 for b in digits):
        return None
    if sign_byte not in ("+", "-"):
        return None
    if not decimal_byte.isdigit():
        return None

    computed_checksum = 0
    for b in frame[1:9]:
        computed_checksum ^= b
    checksum_ok = computed_checksum == checksum_byte

    digit_str = digits.decode("ascii")
    decimals = int(decimal_byte)
    if decimals > 0:
        int_part = digit_str[:-decimals] or "0"
        frac_part = digit_str[-decimals:]
        value_str = f"{int_part}.{frac_part}"
    else:
        value_str = digit_str
    value = float(value_str)
    if sign_byte == "-":
        value = -value

    return {
        "value": value,
        "checksum_ok": checksum_ok,
        "computed_checksum": computed_checksum,
        "checksum_byte": checksum_byte,
    }


def format_hex(data: bytes) -> str:
    return " ".join(f"{b:02X}" for b in data)


def main():
    print(f"Port: {PORT}, tezlik: {BAUD}, davomiyligi: {DURATION}s")
    print("Tarozi ustiga og'irlik qo'ying va o'zgarishni kuzating.\n")

    buffer = bytearray()
    try:
        with serial.Serial(
            PORT,
            baudrate=BAUD,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=0.2,
        ) as ser:
            start = time.time()
            while time.time() - start < DURATION:
                chunk = ser.read(256)
                if not chunk:
                    continue
                buffer.extend(chunk)

                while True:
                    stx_idx = buffer.find(bytes([STX]))
                    if stx_idx == -1:
                        buffer.clear()
                        break
                    if stx_idx > 0:
                        del buffer[:stx_idx]
                    if len(buffer) < FRAME_LEN:
                        break

                    frame = bytes(buffer[:FRAME_LEN])
                    ts = time.strftime("%H:%M:%S")
                    result = parse_frame(frame)

                    if result is None:
                        print(f"[{ts}] Noma'lum freym: {format_hex(frame)}")
                        del buffer[0]
                        continue

                    del buffer[:FRAME_LEN]
                    status = "OK" if result["checksum_ok"] else "CHECKSUM XATO"
                    print(
                        f"[{ts}] RAW: {format_hex(frame)}  ->  "
                        f"{result['value']:.3f} kg  [{status}, "
                        f"kutilgan={result['checksum_byte']:02X} "
                        f"hisoblangan={result['computed_checksum']:02X}]"
                    )
    except serial.SerialException as e:
        print(f"XATO: portni ochib bo'lmadi: {e}")

    print("\nTugadi.")


if __name__ == "__main__":
    main()
