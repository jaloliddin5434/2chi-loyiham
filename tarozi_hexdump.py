"""
COM6 protokolini aniqlash uchun xom baytlarni HEX ko'rinishda chiqaradi.
Og'irlikni bir necha marta qo'yib-olib, freym qanday o'zgarishini kuzatish mumkin.
"""
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
DURATION = 20


def main():
    print(f"Port: {PORT}, tezlik: {BAUD}, davomiyligi: {DURATION}s\n")

    ser = None
    for attempt in range(1, 6):
        try:
            ser = serial.Serial(
                PORT,
                baudrate=BAUD,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=0.2,
            )
            break
        except serial.SerialException as e:
            print(f"  urinish {attempt}: portni ochib bo'lmadi ({e}); 1s kutib qayta urinamiz...")
            time.sleep(1)

    if ser is None:
        print("XATO: 5 urinishdan keyin ham portni ochib bo'lmadi.")
        print("\nTugadi.")
        return

    with ser:
        start = time.time()
        while time.time() - start < DURATION:
            chunk = ser.read(64)
            if not chunk:
                continue
            ts = time.strftime("%H:%M:%S")
            hexstr = " ".join(f"{b:02X}" for b in chunk)
            print(f"[{ts}] ({len(chunk):3d} bayt) {hexstr}")

    print("\nTugadi.")


if __name__ == "__main__":
    main()
