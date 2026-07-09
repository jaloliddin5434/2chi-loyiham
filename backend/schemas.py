from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    username: str
    password: str
    role: str

class UserLogin(BaseModel):
    username: str
    password: str
    role: str

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    username: str

class MahsulotCreate(BaseModel):
    nom: str
    konditsiya_bor: bool = False

class MashinaCreate(BaseModel):
    davlat_raqami: str
    turi: str
    shofyor: str
    firma: str
    viloyat: str
    telefon: Optional[str] = None

class HujjatCreate(BaseModel):
    mashina_id: int
    mahsulot_id: int
    aravalar_soni: int = 1
    tuda_raqam: Optional[str] = None
    texnik_chiqit: Optional[str] = None
    sanoat_turi: Optional[str] = None
    klassifikatsiya: Optional[str] = None
    davomlilik_raqam: Optional[str] = None
    davomlilik_dan: Optional[str] = None
    davomlilik_gacha: Optional[str] = None
    yuk_oluvchi: Optional[str] = None
    shartnoma: Optional[str] = None

class OlchovCreate(BaseModel):
    hujjat_id: int
    arava_raqam: int
    tara: Optional[float] = None
    brutto: Optional[float] = None
    namlik: Optional[float] = None
    ifloslik: Optional[float] = None
    qolda_kiritildi: bool = False