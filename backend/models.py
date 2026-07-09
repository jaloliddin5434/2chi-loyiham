from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text
from sqlalchemy.sql import func
from database import Base

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
    mashina_id = Column(Integer)
    mahsulot_id = Column(Integer)
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
    holat = Column(String, default="jarayon")
    bekor_sabab = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())

class Olchov(Base):
    __tablename__ = "olchovlar"
    id = Column(Integer, primary_key=True, index=True)
    hujjat_id = Column(Integer)
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
    hujjat_id = Column(Integer, unique=True, index=True)
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