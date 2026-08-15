from typing import Optional

from dotenv import load_dotenv
from pydantic import ValidationError
from pydantic_settings import BaseSettings

load_dotenv()


class _Sozlamalar(BaseSettings):
    """.env faylidagi barcha sozlamalar - Pydantic orqali yuklanadi va
    tekshiriladi. Avval har bir qiymat alohida os.getenv() bilan qo'lda
    o'qilardi, faqat DATABASE_URL/SECRET_KEY yo'qligi aniq tekshirilardi
    - boshqa notog'ri turdagi qiymat (masalan ACCESS_TOKEN_EXPIRE_MINUTES
    ustiga son bo'lmagan matn yozilsa) darrov emas, faqat o'sha qiymat
    birinchi marta ishlatilganda (masalan birinchi login so'rovida)
    tushunarsiz xato bilan buzilardi. Endi HAMMASI server ishga
    tushganda, BITTA aniq xato xabari bilan tekshiriladi.

    `load_dotenv()` yuqorida ALLAQACHON .env faylini `os.environ`ga
    yuklagan - shu sabab bu yerda alohida `env_file` ko'rsatilmaydi,
    Pydantic standart tarzda `os.environ`dan o'qiydi (avvalgi
    `os.getenv()` bilan bir xil manba)."""

    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480

    TELEGRAM_TOKEN: Optional[str] = None
    TELEGRAM_CHAT_ID: Optional[str] = None

    # Statistika/hisobot uchun ALOHIDA bot - ogohlantirish (xatolik)
    # xabarlari bilan aralashib ketmasligi uchun. Bo'sh bo'lsa (hali
    # sozlanmagan bo'lsa) telegram_hisobot_yuborish() shunchaki hech
    # narsa yubormaydi.
    TELEGRAM_HISOBOT_TOKEN: Optional[str] = None
    TELEGRAM_HISOBOT_CHAT_ID: Optional[str] = None

    PG_DUMP_YOL: Optional[str] = None

    # Baza zaxira nusxalari (.sql) va tortish tasdiqlovchi rasmlar/
    # nakladnoy fayllari qayerga saqlanishi - avval main.py ichida
    # to'g'ridan-to'g'ri qattiq yozilgan edi (C:\hazorasp_tarozi\backup,
    # C:\RASMLAR), boshqa kompyuterga (masalan diski boshqacha
    # tuzilgan) ko'chirilsa kodga tegish kerak bo'lardi.
    BACKUP_DIR: str = r"C:\hazorasp_tarozi\backup"
    RASMLAR_DIR: str = r"C:\RASMLAR"

    # Ikkinchi kompyuterga (bir xil LAN'dagi tashqi zaxira) backup
    # nusxasini ko'chirish uchun SMB ulanish ma'lumotlari. Barchasi
    # to'ldirilmaguncha (IP, foydalanuvchi, parol) tarmoqqa ko'chirish
    # urinilmaydi.
    TARMOQ_BACKUP_IP: str = ""
    TARMOQ_BACKUP_SHARE: str = "Backup"
    TARMOQ_BACKUP_FOYDALANUVCHI: str = ""
    TARMOQ_BACKUP_PAROL: str = ""

    KAMERA_1_IP: Optional[str] = None
    KAMERA_2_IP: Optional[str] = None
    KAMERA_LOGIN: Optional[str] = None
    KAMERA_PAROL: Optional[str] = None

    # Tarozixonadagi kompyuterda ishlaydigan "Tarozi agenti"
    # (tarozi_agent.py) POST /tarozi/yubor so'rovida shu kalitni
    # X-Tarozi-Agent-Key sarlavhasida yuborishi shart - mos kelmasa
    # so'rov rad etiladi. Ikkala tomonda ham (server .env va agent
    # .env) bir xil qiymat turishi kerak.
    TAROZI_AGENT_KEY: str = ""

    # QR kod (nakladnoy-korish ochiq sahifasi) uchun serverning tashqi
    # manzili - frontend'ning ApiService.baseUrl bilan bir xil
    # (hozircha lokal tarmoq IP, faqat shu WiFi'ga ulangan qurilmalar
    # ocha oladi).
    SERVER_ASOSIY_URL: str = "http://10.112.30.77:47001"

    # Tunnel/tarmoq o'z-o'zini kuzatish (_tunnel_bir_tekshiruv) uchun -
    # ATAYLAB SERVER_ASOSIY_URL'dan ALOHIDA. SERVER_ASOSIY_URL mahalliy
    # tarmoq (LAN) manzili - shu bilan tekshirish aslida hech qachon
    # Cloudflare Tunnel/internet muammosini aniqlay olmasdi (faqat
    # backend jarayonining o'zi tirikligini tekshirardi). Bu real
    # productionda topilgan monitoring teshigi edi (2026-08-10) - shu
    # sabab tunnel tekshiruvi ENDI haqiqiy ommaviy domenga (Cloudflare
    # Tunnel orqali) so'rov yuboradi.
    TUNNEL_TEKSHIRUV_URL: str = "https://api.smart-tarozi.uz/health"

    # CORS - brauzerdan so'rov yuborishga ruxsat berilgan manzillar
    # ro'yxati (vergul bilan ajratilgan). Kelajakda domen/reverse-proxy
    # qo'shilganda faqat shu .env qiymatini yangilash kifoya - kodga
    # tegish shart emas.
    #
    # DIQQAT: standart qiymat ATAYLAB hech qanday muayyan kompyuter
    # (server) IP'iga tayanmaydi - faqat doimiy, joylashuvdan mustaqil
    # manzillar (domen) va localhost. Avval bu yerda bitta muayyan
    # ish stantsiyasining LAN IP'i qattiq yozilgan edi - production
    # boshqa kompyuterga ko'chirilganda, agar kimdir .env'da
    # ALLOWED_ORIGINS'ni yangilashni unutsa, backend eskirgan/notogri
    # kompyuterning IP'iga ruxsat berib qolar edi (2026-08-15dagi
    # TARMOQ_BACKUP_IP config-drift voqeasi bilan bir xil naqsh).
    # Mahalliy tarmoq (LAN, ofis ichi, internetsiz) to'g'ridan-to'g'ri
    # kirish manzili HAR BIR SERVERDA .env orqali ALOHIDA qo'shilishi
    # kerak - shunda ham unutilsa, natija "faqat bulut orqali ishlaydi"
    # bo'ladi (darhol sezilib, tekshiriladi), "notogri kompyuterga
    # ruxsat" emas.
    ALLOWED_ORIGINS: str = "https://smart-tarozi.uz,https://app.smart-tarozi.uz,http://localhost:47080"

    # Avval /docs, /redoc, /openapi.json production'da HAM hech qanday
    # to'sqichsiz, autentifikatsiyasiz ochiq edi - butun API sxemasi
    # (barcha endpoint/parametr nomlari) har kimga ko'rinardi. Standart
    # qiymat ATAYLAB False - ochiq qoldirish kerak bo'lsa (masalan
    # mahalliy ishlab chiqishda), .env'da aniq yoqilishi kerak.
    API_HUJJATLARI_OCHIQ: bool = False


try:
    _sozlama = _Sozlamalar()
except ValidationError as e:
    raise RuntimeError(
        f".env faylida xato yoki yetishmayotgan majburiy sozlama(lar) bor:\n{e}"
    ) from e

DATABASE_URL = _sozlama.DATABASE_URL
SECRET_KEY = _sozlama.SECRET_KEY
ALGORITHM = _sozlama.ALGORITHM
ACCESS_TOKEN_EXPIRE_MINUTES = _sozlama.ACCESS_TOKEN_EXPIRE_MINUTES

TELEGRAM_TOKEN = _sozlama.TELEGRAM_TOKEN
TELEGRAM_CHAT_ID = _sozlama.TELEGRAM_CHAT_ID

TELEGRAM_HISOBOT_TOKEN = _sozlama.TELEGRAM_HISOBOT_TOKEN
TELEGRAM_HISOBOT_CHAT_ID = _sozlama.TELEGRAM_HISOBOT_CHAT_ID

PG_DUMP_YOL = _sozlama.PG_DUMP_YOL
BACKUP_DIR = _sozlama.BACKUP_DIR
RASMLAR_DIR = _sozlama.RASMLAR_DIR

TARMOQ_BACKUP_IP = _sozlama.TARMOQ_BACKUP_IP
TARMOQ_BACKUP_SHARE = _sozlama.TARMOQ_BACKUP_SHARE
TARMOQ_BACKUP_FOYDALANUVCHI = _sozlama.TARMOQ_BACKUP_FOYDALANUVCHI
TARMOQ_BACKUP_PAROL = _sozlama.TARMOQ_BACKUP_PAROL

KAMERA_1_IP = _sozlama.KAMERA_1_IP
KAMERA_2_IP = _sozlama.KAMERA_2_IP
KAMERA_LOGIN = _sozlama.KAMERA_LOGIN
KAMERA_PAROL = _sozlama.KAMERA_PAROL

TAROZI_AGENT_KEY = _sozlama.TAROZI_AGENT_KEY

SERVER_ASOSIY_URL = _sozlama.SERVER_ASOSIY_URL
TUNNEL_TEKSHIRUV_URL = _sozlama.TUNNEL_TEKSHIRUV_URL

ALLOWED_ORIGINS = [
    manzil.strip()
    for manzil in _sozlama.ALLOWED_ORIGINS.split(",")
    if manzil.strip()
]

API_HUJJATLARI_OCHIQ = _sozlama.API_HUJJATLARI_OCHIQ
