import enum
from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text, Enum as SQLEnum, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from database import Base

class HujjatHolati(str, enum.Enum):
    JARAYON = "jarayon"
    TUGALLANDI = "tugallandi"
    BEKOR_QILINDI = "bekor"

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())

class Mahsulot(Base):
    __tablename__ = "mahsulotlar"
    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String)
    konditsiya_bor = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)

class Mashina(Base):
    __tablename__ = "mashinalar"
    id = Column(Integer, primary_key=True, index=True)
    davlat_raqami = Column(String, index=True)
    turi = Column(String)
    shofyor = Column(String)
    firma = Column(String)
    viloyat = Column(String)
    telefon = Column(String, nullable=True)

class Hujjat(Base):
    __tablename__ = "hujjatlar"
    id = Column(Integer, primary_key=True, index=True)
    raqam = Column(String, unique=True, index=True)
    mashina_id = Column(Integer, ForeignKey("mashinalar.id", ondelete="RESTRICT"))
    mahsulot_id = Column(Integer, ForeignKey("mahsulotlar.id", ondelete="RESTRICT"))
    operator_id = Column(Integer)
    aravalar_soni = Column(Integer, default=1)
    tuda_raqam = Column(String, nullable=True)
    texnik_chiqit = Column(String, nullable=True)
    sanoat_turi = Column(String, nullable=True)
    klassifikatsiya = Column(String, nullable=True)
    davomlilik_raqam = Column(String, nullable=True)
    davomlilik_dan = Column(String, nullable=True)
    davomlilik_gacha = Column(String, nullable=True)
    yuk_oluvchi = Column(String, nullable=True)
    shartnoma = Column(String, nullable=True)
    mashina_raqami = Column(String, nullable=True)
    shofyor = Column(String, nullable=True)
    firma = Column(String, nullable=True)
    tiket_raqam = Column(String, nullable=True)
    klass = Column(String, nullable=True)
    sinf = Column(String, nullable=True)
    seleksiya_navi = Column(String, nullable=True)
    terim_turi = Column(String, nullable=True)
    qabul_qildi = Column(String, nullable=True)
    yuk_olindi = Column(String, nullable=True)
    dostaverka = Column(String, nullable=True)
    dostaverka_vaqt = Column(String, nullable=True)
    holat = Column(
        SQLEnum(
            HujjatHolati,
            name="hujjat_holati_enum",
            values_callable=lambda enum_klass: [e.value for e in enum_klass],
        ),
        default=HujjatHolati.JARAYON,
        nullable=False,
    )
    bekor_sabab = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())

class Olchov(Base):
    __tablename__ = "olchovlar"
    id = Column(Integer, primary_key=True, index=True)
    hujjat_id = Column(Integer, ForeignKey("hujjatlar.id", ondelete="CASCADE"))
    arava_raqam = Column(Integer)
    tara = Column(Float, nullable=True)
    brutto = Column(Float, nullable=True)
    netto = Column(Float, nullable=True)
    namlik = Column(Float, nullable=True)
    ifloslik = Column(Float, nullable=True)
    konditsion = Column(Float, nullable=True)
    tara_rasm = Column(String, nullable=True)
    brutto_rasm = Column(String, nullable=True)
    qolda_kiritildi = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())

class Navbat(Base):
    __tablename__ = "navbat"
    id = Column(Integer, primary_key=True, index=True)
    hujjat_id = Column(Integer, ForeignKey("hujjatlar.id", ondelete="CASCADE"), unique=True, index=True)
    mashina_id = Column(Integer)
    raqam = Column(String)
    turi = Column(String, nullable=True)
    shofyor = Column(String, nullable=True)
    firma = Column(String, nullable=True)
    mahsulot_id = Column(Integer)
    mahsulot_nomi = Column(String)
    vaqt = Column(String, nullable=True)
    kelgan_vaqt = Column(DateTime, default=func.now())
    tuda_raqam = Column(String, nullable=True)
    tiket_raqam = Column(String, nullable=True)
    seleksiya_navi = Column(String, nullable=True)
    klass = Column(String, nullable=True)
    sinf = Column(String, nullable=True)
    terim_turi = Column(String, nullable=True)
    namlik = Column(Float, nullable=True)
    ifloslik = Column(Float, nullable=True)
    tugallandi = Column(Boolean, default=False)
    tugallangan_vaqt = Column(DateTime, nullable=True)
    aravalar_json = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())

class HujjatRaqamHisoblagich(Base):
    __tablename__ = "hujjat_raqam_hisoblagich"
    id = Column(Integer, primary_key=True, autoincrement=True)
    yil = Column(Integer, nullable=False)
    mahsulot_id = Column(Integer, nullable=True)  # NULL = eski (2026 yilgacha ishlatilgan) umumiy hisoblagich
    oxirgi_raqam = Column(Integer, default=0)

    __table_args__ = (
        UniqueConstraint("yil", "mahsulot_id", name="uq_hujjat_raqam_hisoblagich_yil_mahsulot"),
    )

class TizimXatosi(Base):
    __tablename__ = "tizim_xatolari"
    id = Column(Integer, primary_key=True, index=True)
    turi = Column(String)
    xabar = Column(Text)
    korilgan = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())

class TahrirTarixi(Base):
    __tablename__ = "tahrir_tarixi"
    id = Column(Integer, primary_key=True, index=True)
    hujjat_id = Column(Integer, ForeignKey("hujjatlar.id", ondelete="CASCADE"), index=True)
    maydon = Column(String)
    eski_qiymat = Column(Text, nullable=True)
    yangi_qiymat = Column(Text, nullable=True)
    sabab = Column(Text)
    ozgartirgan_user_id = Column(Integer, nullable=True)
    ozgartirgan_username = Column(String, nullable=True)
    created_at = Column(DateTime, default=func.now())

class Sozlama(Base):
    __tablename__ = "sozlamalar"
    id = Column(Integer, primary_key=True, index=True)
    kalit = Column(String, unique=True, index=True)
    qiymat = Column(Text, nullable=True)
    updated_at = Column(DateTime, default=func.now())