from pydantic import BaseModel, field_validator, model_validator
from typing import Optional
from models import HujjatHolati

RUXSAT_ETILGAN_ROLLAR = ("admin", "operator", "hisobchi")

class UserCreate(BaseModel):
    username: str
    password: str
    role: str

    @field_validator('username')
    @classmethod
    def username_tekshiruv(cls, qiymat):
        if not qiymat or not qiymat.strip():
            raise ValueError("Login bo'sh bo'lishi mumkin emas!")
        return qiymat.strip()

    @field_validator('password')
    @classmethod
    def password_tekshiruv(cls, qiymat):
        if not qiymat or len(qiymat) < 6:
            raise ValueError("Parol kamida 6 belgidan iborat bo'lishi kerak!")
        return qiymat

    @field_validator('role')
    @classmethod
    def role_tekshiruv(cls, qiymat):
        if qiymat not in RUXSAT_ETILGAN_ROLLAR:
            raise ValueError(
                f"Rol faqat quyidagilardan biri bo'lishi kerak: {', '.join(RUXSAT_ETILGAN_ROLLAR)}"
            )
        return qiymat

class UserParolYangilash(BaseModel):
    yangi_parol: str

    @field_validator('yangi_parol')
    @classmethod
    def parol_tekshiruv(cls, qiymat):
        if not qiymat or len(qiymat) < 6:
            raise ValueError("Parol kamida 6 belgidan iborat bo'lishi kerak!")
        return qiymat

class UserHolatYangilash(BaseModel):
    is_active: bool

class UserLogin(BaseModel):
    username: str
    password: str
    role: str

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    username: str

class MahsulotNarxiCreate(BaseModel):
    narx: float

    @field_validator('narx')
    @classmethod
    def narx_tekshiruv(cls, qiymat):
        if qiymat is None or qiymat <= 0:
            raise ValueError("Narx musbat son bo'lishi kerak!")
        return qiymat

class PinOrnatish(BaseModel):
    eski_pin: Optional[str] = None
    yangi_pin: str

    @field_validator('yangi_pin')
    @classmethod
    def yangi_pin_tekshiruv(cls, qiymat):
        if not qiymat or not qiymat.isdigit() or len(qiymat) != 4:
            raise ValueError("PIN aynan 4 ta raqamdan iborat bo'lishi kerak!")
        return qiymat

class PinTekshirish(BaseModel):
    pin: str

class FirmaCreate(BaseModel):
    nom: str

    @field_validator('nom')
    @classmethod
    def nom_tekshiruv(cls, qiymat):
        if not qiymat or not qiymat.strip():
            raise ValueError("Firma nomi bo'sh bo'lishi mumkin emas!")
        return qiymat.strip()

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
    dostaverka: Optional[str] = None
    dostaverka_vaqt: Optional[str] = None
    mijoz_kaliti: Optional[str] = None

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
    mashina_raqami: Optional[str] = None
    shofyor: Optional[str] = None
    firma: Optional[str] = None
    tiket_raqam: Optional[str] = None
    klass: Optional[str] = None
    sinf: Optional[str] = None
    seleksiya_navi: Optional[str] = None
    terim_turi: Optional[str] = None
    qabul_qildi: Optional[str] = None
    yuk_olindi: Optional[str] = None
    dostaverka: Optional[str] = None
    dostaverka_vaqt: Optional[str] = None
    namlik: Optional[float] = None
    ifloslik: Optional[float] = None
    holat: Optional[HujjatHolati] = None
    bekor_sabab: Optional[str] = None
    sabab: Optional[str] = None

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