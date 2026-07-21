import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "480"))

UPLOAD_DIR = os.getenv("UPLOAD_DIR", "C:/RASMLAR")
BACKUP_DIR = os.getenv("BACKUP_DIR", r"C:\hazorasp_tarozi\backup")

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

PG_DUMP_YOL = os.getenv("PG_DUMP_YOL")
WKHTMLTOPDF_YOL = os.getenv("WKHTMLTOPDF_YOL")

KAMERA_1_IP = os.getenv("KAMERA_1_IP")
KAMERA_2_IP = os.getenv("KAMERA_2_IP")
KAMERA_LOGIN = os.getenv("KAMERA_LOGIN")
KAMERA_PAROL = os.getenv("KAMERA_PAROL")

if not DATABASE_URL or not SECRET_KEY:
    raise RuntimeError(".env faylida DATABASE_URL yoki SECRET_KEY topilmadi!")
