"""
Tarozi (KLAS XK3190-A9+) COM6 port diagnostikasi.
COM6 portini turli baud tezliklarda ochib, kelayotgan xom baytlarni
hex va matn ko'rinishida ekranga chiqaradi.

Ishlatish:
    python tarozi_diag.py
"""
import sys
import time

try:
    import serial
except ImportError:
    print("pyserial topilmadi, o'rnatilmoqda...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyserial"])
    import serial

PORT = "COM6"
BAUD_RATES = [600, 1200, 2400, 4800, 9600]
SECONDS_PER_BAUD = 5

# Odatda tarozilarda uchraydigan bitlar kombinatsiyalari
# (baytlik, parity, stopbit) - standart 8N1 bilan boshlaymiz
SERIAL_KWARGS = dict(
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=0.5,
)


def format_bytes(data: bytes) -> str:
    hex_part = " ".join(f"{b:02X}" for b in data)
    text_part = "".join(chr(b) if 32 <= b <= 126 else "." for b in data)
    return f"HEX: {hex_part}\n     TEXT: {text_part}"


def listen_at_baud(port: str, baud: int, duration: float):
    print(f"\n{'=' * 60}")
    print(f"Tezlik: {baud} baud, port: {port}, davomiyligi: {duration}s")
    print(f"{'=' * 60}")
    try:
        with serial.Serial(port, baudrate=baud, **SERIAL_KWARGS) as ser:
            start = time.time()
            total_bytes = 0
            got_data = False
            while time.time() - start < duration:
                chunk = ser.read(256)
                if chunk:
                    got_data = True
                    total_bytes += len(chunk)
                    ts = time.strftime("%H:%M:%S")
                    print(f"[{ts}] {len(chunk)} bayt keldi:")
                    print(format_bytes(chunk))
            if not got_data:
                print("(Hech qanday ma'lumot kelmadi)")
            else:
                print(f"\nJami: {total_bytes} bayt qabul qilindi.")
    except serial.SerialException as e:
        print(f"XATO: portni ochib bo'lmadi: {e}")


def main():
    print(f"Tarozi diagnostikasi boshlanmoqda. Port: {PORT}")
    print("Har bir tezlikda tarozini yoqib/o'chirib yoki og'irlik qo'yib ko'ring.")
    print("To'xtatish uchun Ctrl+C bosing.\n")

    try:
        for baud in BAUD_RATES:
            listen_at_baud(PORT, baud, SECONDS_PER_BAUD)
    except KeyboardInterrupt:
        print("\nTo'xtatildi (foydalanuvchi so'rovi bilan).")

    print("\nDiagnostika tugadi.")


if __name__ == "__main__":
    main()
