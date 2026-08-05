import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "480"))

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

PG_DUMP_YOL = os.getenv("PG_DUMP_YOL")

# Ikkinchi kompyuterga (bir xil LAN'dagi tashqi zaxira) backup nusxasini
# ko'chirish uchun SMB ulanish ma'lumotlari. Barchasi to'ldirilmaguncha
# (IP, foydalanuvchi, parol) tarmoqqa ko'chirish urinilmaydi.
TARMOQ_BACKUP_IP = os.getenv("TARMOQ_BACKUP_IP", "")
TARMOQ_BACKUP_SHARE = os.getenv("TARMOQ_BACKUP_SHARE", "Backup")
TARMOQ_BACKUP_FOYDALANUVCHI = os.getenv("TARMOQ_BACKUP_FOYDALANUVCHI", "")
TARMOQ_BACKUP_PAROL = os.getenv("TARMOQ_BACKUP_PAROL", "")

KAMERA_1_IP = os.getenv("KAMERA_1_IP")
KAMERA_2_IP = os.getenv("KAMERA_2_IP")
KAMERA_LOGIN = os.getenv("KAMERA_LOGIN")
KAMERA_PAROL = os.getenv("KAMERA_PAROL")

# Tarozixonadagi kompyuterda ishlaydigan "Tarozi agenti" (tarozi_agent.py)
# POST /tarozi/yubor so'rovida shu kalitni X-Tarozi-Agent-Key sarlavhasida
# yuborishi shart - mos kelmasa so'rov rad etiladi. Ikkala tomonda ham
# (server .env va agent .env) bir xil qiymat turishi kerak.
TAROZI_AGENT_KEY = os.getenv("TAROZI_AGENT_KEY", "")

# QR kod (nakladnoy-korish ochiq sahifasi) uchun serverning tashqi manzili -
# frontend'ning ApiService.baseUrl bilan bir xil (hozircha lokal tarmoq IP,
# faqat shu WiFi'ga ulangan qurilmalar ocha oladi).
SERVER_ASOSIY_URL = os.getenv("SERVER_ASOSIY_URL", "http://10.112.30.77:8001")

# CORS - brauzerdan so'rov yuborishga ruxsat berilgan manzillar ro'yxati
# (vergul bilan ajratilgan). Kelajakda domen/reverse-proxy qo'shilganda
# faqat shu .env qiymatini yangilash kifoya - kodga tegish shart emas.
ALLOWED_ORIGINS = [
    manzil.strip()
    for manzil in os.getenv(
        "ALLOWED_ORIGINS", "http://10.112.30.77:8080,http://localhost:8080"
    ).split(",")
    if manzil.strip()
]

if not DATABASE_URL or not SECRET_KEY:
    raise RuntimeError(".env faylida DATABASE_URL yoki SECRET_KEY topilmadi!")
