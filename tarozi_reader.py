"""
Tarozi (KLAS XK3190-A9+, uzluksiz rejim) uchun mustahkam o'quvchi.

Freym formati (aniqlangan): 09 2B <7 xonali raqam> 12 0D
    TAB '+' 0000000 DC2 CR

Liniyada elektr shovqin bor (tasodifiy baytlar frame ichiga kirib qoladi),
shuning uchun to'liq freym emas, faqat eng barqaror qism -
sign (+/-) va undan keyingi 7 ta ASCII raqam - qidiriladi va o'qiladi.
Faqat qiymat o'zgarganda konsolga chiqariladi (spam bo'lmasligi uchun).
"""
import re
import sys
import time

try:
    import serial
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
    import serial

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PORT = "COM7"
BAUD = 9600
DURATION = 60

FRAME_RE = re.compile(rb"([+\-])([0-9]{7})")


def open_port_with_retry(port, baud, attempts=5, delay=1.0):
    for attempt in range(1, attempts + 1):
        try:
            return serial.Serial(
                port,
                baudrate=baud,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=0.2,
            )
        except serial.SerialException as e:
            print(f"  urinish {attempt}: portni ochib bo'lmadi ({e}); {delay}s kutib qayta urinamiz...")
            time.sleep(delay)
    return None


def main():
    print(f"Port: {PORT}, tezlik: {BAUD}, davomiyligi: {DURATION}s\n")

    ser = open_port_with_retry(PORT, BAUD)
    if ser is None:
        print("XATO: portni ochib bo'lmadi.")
        return

    buffer = bytearray()
    last_value = None

    with ser:
        start = time.time()
        while time.time() - start < DURATION:
            chunk = ser.read(256)
            if chunk:
                buffer += chunk

            match = None
            for match in FRAME_RE.finditer(buffer):
                pass  # oxirgi (eng so'nggi) moslikni olamiz

            if match:
                sign = match.group(1).decode()
                digits = match.group(2).decode()
                value = f"{sign}{digits}"
                if value != last_value:
                    ts = time.strftime("%H:%M:%S")
                    print(f"[{ts}] XOM QIYMAT: {value}")
                    last_value = value
                # buferni oxirgi moslikdan keyingi qismgacha qisqartiramiz
                del buffer[: match.end()]

            # bufer haddan tashqari o'smasligi uchun cheklaymiz
            if len(buffer) > 4096:
                del buffer[:-64]

    print("\nTugadi.")


if __name__ == "__main__":
    main()
