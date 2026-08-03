"""
Pytest umumiy sozlamalari - butun test to'plami uchun.

MUHIM: bu fayl `main.py`ni import qilishdan OLDIN ikkita narsani bajaradi
(aks holda testlar HAQIQIY, ishlab turgan bazaga ulanib, HAQIQIY pg_dump/
Telegram xabar yuborishni boshlab yuborardi):

1. DATABASE_URL'ni alohida "hazorasp_tarozi_test" bazasiga almashtiradi
   (asl .env'dagi DATABASE_URL'dan foydalanuvchi/parol/host/port o'qib,
   faqat baza nomini almashtiradi - parolni bu faylga qattiq yozishning
   hojati yo'q). Almashtirilgan qiymatda "_test" borligi tekshiriladi -
   aks holda darhol to'xtaydi (ishlab turgan bazaga tasodifan ulanish
   butunlay oldini olinadi).
2. `threading.Thread.start`ni vaqtincha "hech narsa qilmaydigan" holatga
   almashtiradi - shu bilan main.py import qilinganda ishga tushadigan
   ikkita fon oqimi (avtomatik_backup, avtomatik_telegram_hisobot) HECH
   QACHON ishga tushmaydi. main.py'NING O'ZIGA BIRON QATOR HAM
   TEGILMAYDI - bu faqat shu test jarayonida, vaqtincha.
"""
import os
import re
import threading
from pathlib import Path

import pytest
from dotenv import dotenv_values
from sqlalchemy import event
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

_BACKEND_DIR = Path(__file__).resolve().parent.parent

# --- 1) Test bazasiga yo'naltirish (main.py import qilinishidan OLDIN) ---
_env = dotenv_values(_BACKEND_DIR / ".env")
_real_db_url = _env["DATABASE_URL"]
_test_db_url = re.sub(r"/hazorasp_tarozi(\?|$)", r"/hazorasp_tarozi_test\1", _real_db_url)
if "_test" not in _test_db_url:
    raise RuntimeError(
        "Xavfsizlik: test DATABASE_URL 'hazorasp_tarozi_test' bazasini "
        f"ko'rsatishi SHART edi, hosil bo'lgan qiymat mos kelmadi: {_test_db_url}"
    )
os.environ["DATABASE_URL"] = _test_db_url


def _test_bazasini_zarur_bolsa_yaratish():
    """Agar 'hazorasp_tarozi_test' bazasi hali mavjud bo'lmasa, uni
    yaratadi (postgres maintenance bazasiga ulanib). Idempotent - baza
    allaqachon bo'lsa hech narsa qilmaydi."""
    import psycopg2
    from sqlalchemy.engine import make_url

    url = make_url(_test_db_url)
    conn = psycopg2.connect(
        host=url.host, port=url.port, user=url.username,
        password=url.password, dbname="postgres",
    )
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (url.database,))
            if not cur.fetchone():
                cur.execute(f'CREATE DATABASE "{url.database}"')
    finally:
        conn.close()


_test_bazasini_zarur_bolsa_yaratish()

# --- 2) Fon oqimlarini vaqtincha o'chirish, main.py'ni xavfsiz import qilish ---
_asl_thread_start = threading.Thread.start
threading.Thread.start = lambda self: None
try:
    import main  # noqa: E402
finally:
    threading.Thread.start = _asl_thread_start

from database import get_db  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def _sxema_tayyorligi():
    """main.py import paytida Base.metadata.create_all() allaqachon
    (test bazasiga qarshi) chaqirilgan - bu shunchaki aniq/ikkinchi
    tasdiq, chaqirish xavfsiz (idempotent)."""
    main.Base.metadata.create_all(bind=main.engine)
    yield


@pytest.fixture()
def db_session():
    """Har bir test o'z ALOHIDA tranzaksiyasida ishlaydi - test tugagach
    ROLLBACK qilinadi, hech qanday iz (na yangi qator, na o'zgarish)
    qolmaydi. Endpoint ichidagi db.commit() chaqiruvlari SAVEPOINT'ni
    yopadi, lekin shu yerda ochilgan tashqi tranzaksiya ochiq qoladi -
    standart SQLAlchemy "test uchun tashqi tranzaksiyaga qo'shilish"
    andozasi."""
    connection = main.engine.connect()
    tranzaksiya = connection.begin()
    Session = sessionmaker(bind=connection)
    session = Session()

    nested = connection.begin_nested()

    @event.listens_for(session, "after_transaction_end")
    def _savepoint_qayta_ochish(sess, trans):
        nonlocal nested
        if not nested.is_active:
            nested = connection.begin_nested()

    yield session

    session.close()
    tranzaksiya.rollback()
    connection.close()


@pytest.fixture()
def client(db_session):
    """FastAPI TestClient - get_db dependency shu testning o'z
    tranzaksiyasiga (db_session) yo'naltirilgan."""
    def _get_db_override():
        yield db_session

    main.app.dependency_overrides[get_db] = _get_db_override
    yield TestClient(main.app)
    main.app.dependency_overrides.clear()


# ---------- Umumiy "boshlang'ich ma'lumot" fixturalari ----------

@pytest.fixture()
def admin_user(db_session):
    from models import User
    from auth import hash_password
    user = User(username="test_admin", password=hash_password("parol123"),
                role="admin", is_active=True)
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def operator_user(db_session):
    from models import User
    from auth import hash_password
    user = User(username="test_operator", password=hash_password("parol123"),
                role="operator", is_active=True)
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def admin_headers(admin_user):
    from auth import create_access_token
    token = create_access_token(
        {"sub": admin_user.username, "role": admin_user.role, "id": admin_user.id})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def operator_headers(operator_user):
    from auth import create_access_token
    token = create_access_token(
        {"sub": operator_user.username, "role": operator_user.role, "id": operator_user.id})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def mahsulot_chigit(db_session):
    from models import Mahsulot
    m = Mahsulot(nom="Chigit", konditsiya_bor=True, is_active=True)
    db_session.add(m)
    db_session.commit()
    db_session.refresh(m)
    return m


@pytest.fixture()
def mashina(db_session):
    from models import Mashina
    m = Mashina(davlat_raqami="01A123BB", turi="FAW", shofyor="Test Shofyor",
                firma="Test Firma", viloyat="Xorazm", telefon=None)
    db_session.add(m)
    db_session.commit()
    db_session.refresh(m)
    return m
