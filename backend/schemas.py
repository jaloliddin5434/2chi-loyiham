from pydantic import BaseModel, field_validator, model_validator
from typing import Optional
from datetime import datetime
from models import HujjatHolati

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

class HujjatUpdate(BaseModel):
    aravalar_soni: Optional[int] = None
    tuda_raqam: Optional[str] = None
    texnik_chiqit: Optional[str] = None
    sanoat_turi: Optional[str] = None
    klassifikatsiya: Optional[str] = None
    davomlilik_raqam: Optional[str] = None
    davomlilik_dan: Optional[str] = None
    davomlilik_gacha: Optional[str] = None
    yuk_oluvchi: Optional[str] = None
    shartnoma: Optional[str] = None
    holat: Optional[HujjatHolati] = None
    bekor_sabab: Optional[str] = None

class OlchovCreate(BaseModel):
    hujjat_id: int
    arava_raqam: int
    tara: Optional[float] = None
    brutto: Optional[float] = None
    namlik: Optional[float] = None
    ifloslik: Optional[float] = None
    qolda_kiritildi: bool = False

    @field_validator('namlik')
    @classmethod
    def namlik_tekshiruv(cls, qiymat):
        if qiymat is not None and not (0 <= qiymat <= 100):
            raise ValueError('Namlik foizi 0 dan 100 gacha bo\'lishi kerak!')
        return qiymat

    @field_validator('ifloslik')
    @classmethod
    def ifloslik_tekshiruv(cls, qiymat):
        if qiymat is not None and not (0 <= qiymat <= 100):
            raise ValueError('Ifloslik foizi 0 dan 100 gacha bo\'lishi kerak!')
        return qiymat

    @model_validator(mode='after')
    def yigindi_tekshiruv(self):
        if self.namlik is not None and self.ifloslik is not None:
            if self.namlik + self.ifloslik > 100:
                raise ValueError(
                    'Namlik va ifloslik yig\'indisi 100 foizdan oshmasligi kerak!'
                )
        return self