import uuid
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.hash import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES
from database import get_db
from models import User, QoraRoyxatToken

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def hash_password(password: str):
    return bcrypt.hash(password)

def verify_password(plain_password: str, hashed_password: str):
    return bcrypt.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_minutes: int = None):
    to_encode = data.copy()
    muddat = expires_minutes if expires_minutes is not None else ACCESS_TOKEN_EXPIRE_MINUTES
    expire = datetime.utcnow() + timedelta(minutes=muddat)
    # `jti` (JWT ID) - har bir tokenga noyob identifikator. Faqat
    # logout qora ro'yxati (qarang: QoraRoyxatToken) uchun kerak -
    # tokenning o'zi shu bitta qatorini qora ro'yxatga qo'shish orqali,
    # boshqa (shu foydalanuvchining boshqa qurilmadagi) tokenlariga
    # tegmasdan, aynan shu SESSIYANI bekor qilish imkonini beradi.
    to_encode.update({"exp": expire, "jti": str(uuid.uuid4())})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = verify_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token yaroqsiz yoki muddati o'tgan",
            headers={"WWW-Authenticate": "Bearer"},
        )
    # DIQQAT: token o'zi hali amal qilsa (muddati tugamagan bo'lsa) ham,
    # foydalanuvchi shu orada admin tomonidan FAOLSIZLANTIRILGAN bo'lishi
    # mumkin - token standart bo'yicha 8 soatgacha amal qiladi va
    # serverda "bekor qilib" bo'lmaydi (JWT stateless), shu sabab HAR
    # so'rovda bazadan haqiqiy holat tekshiriladi. Avval faolsizlantirish
    # faqat KELAJAKDAGI login urinishlarini to'xtatardi, joriy (allaqachon
    # qo'lga kiritilgan) sessiyaga umuman ta'sir qilmasdi - audit orqali
    # topilgan xavfsizlik teshigi.
    # Token qora ro'yxatga (POST /logout orqali) qo'shilganmi? Eski
    # (bu funksiya qo'shilishidan oldin chiqarilgan) tokenlarda `jti`
    # yo'q - ular bu tekshiruvni oddiy o'tkazib yuboradi (baribir o'z
    # tabiiy muddatida tugaydi).
    jti = payload.get("jti")
    if jti and db.query(QoraRoyxatToken).filter(QoraRoyxatToken.jti == jti).first():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sessiya tugatilgan (chiqish qilingan) - qayta kiring",
            headers={"WWW-Authenticate": "Bearer"},
        )
    foydalanuvchi = db.query(User).filter(User.id == payload.get("id")).first()
    if foydalanuvchi is None or not foydalanuvchi.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Hisobingiz faolsizlantirilgan yoki mavjud emas",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload

def require_role(*rollar: str):
    """Bir yoki bir nechta rolga ruxsat beradi - masalan
    require_role("admin", "rahbar") ikkalasini ham qabul qiladi."""
    def checker(current_user: dict = Depends(get_current_user)):
        if current_user.get("role") not in rollar:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bu amal uchun ruxsatingiz yo'q",
            )
        return current_user
    return checker

# Moliyaviy (PIN-himoyalangan) ma'lumotlarni ko'ra oladigan rollar - admin
# (to'liq boshqaruv) va rahbar (faqat o'qish uchun mobil dashboard,
# qarang: GET /statistika/kunlik va h.k. atrofidagi "rahbar" izohlari).
# "hisobchi" ATAYLAB bu yerda YO'Q - moliyaviy hisobot hozircha faqat
# admin/rahbar uchun mo'ljallangan.
MOLIYAVIY_RUXSAT_ROLLARI = ("admin", "rahbar")

def require_moliyaviy_ruxsat(current_user: dict = Depends(get_current_user)):
    """Moliyaviy hisobot/narx endpointlari uchun - oddiy admin login
    tokeni YETARLI EMAS. Token ichida `moliyaviy_ruxsat: true` da'vosi
    bo'lishi shart - bu faqat to'g'ri PIN kiritilgandan keyin
    (POST /moliyaviy/pin-tekshir orqali) 20 daqiqaga beriladigan alohida
    tokenlarda mavjud bo'ladi. Shu bilan boshqa admin PIN oynasini
    chetlab o'tib, to'g'ridan-to'g'ri so'rov yuborsa ham (masalan devtools
    orqali), oddiy login tokeni bilan bu ma'lumotni ola olmaydi."""
    if (current_user.get("role") not in MOLIYAVIY_RUXSAT_ROLLARI
            or not current_user.get("moliyaviy_ruxsat")):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Moliyaviy ma'lumotlarga kirish uchun PIN tasdiqlanishi kerak!",
        )
    return current_user