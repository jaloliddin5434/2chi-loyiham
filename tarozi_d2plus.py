"""
Tarozi (KLAS XK3190-A9+) - D2+ oddiy matn rejimi (tF=2), 9600 baud.
Indikator checksumsiz, oddiy ASCII matn ko'rinishida uzluksiz yuboradi,
masalan: "51.07000=51.07000=51.08000=..."

15 soniya davomida portni tinglaydi, kelgan xom matnni to'g'ridan-to'g'ri
ekranga chiqaradi va "=" belgisi bilan ajratilgan har bir qiymatni
alohida qatorda ko'rsatadi.
"""
import sys
import time

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

try:
    import serial
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
    import serial

PORT = "COM6"
BAUD = 9600
DURATION = 15


def main():
    print(f"Port: {PORT}, tezlik: {BAUD}, davomiyligi: {DURATION}s\n")

    buffer = ""
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

                text = chunk.decode("ascii", errors="replace")
                print(f"RAW MATN: {text!r}")
                buffer += text

                while "=" in buffer:
                    value, buffer = buffer.split("=", 1)
                    value = value.strip()
                    if value:
                        ts = time.strftime("%H:%M:%S")
                        print(f"  [{ts}] QIYMAT: {value}")
    except serial.SerialException as e:
        print(f"XATO: portni ochib bo'lmadi: {e}")

    print("\nTugadi.")


if __name__ == "__main__":
    main()
