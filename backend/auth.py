from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.hash import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def hash_password(password: str):
    return bcrypt.hash(password)

def verify_password(plain_password: str, hashed_password: str):
    return bcrypt.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_minutes: int = None):
    to_encode = data.copy()
    muddat = expires_minutes if expires_minutes is not None else ACCESS_TOKEN_EXPIRE_MINUTES
    expire = datetime.utcnow() + timedelta(minutes=muddat)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None

def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token yaroqsiz yoki muddati o'tgan",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload

def require_role(role: str):
    def checker(current_user: dict = Depends(get_current_user)):
        if current_user.get("role") != role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bu amal uchun ruxsatingiz yo'q",
            )
        return current_user
    return checker

def require_moliyaviy_ruxsat(current_user: dict = Depends(get_current_user)):
    """Moliyaviy hisobot/narx endpointlari uchun - oddiy admin login
    tokeni YETARLI EMAS. Token ichida `moliyaviy_ruxsat: true` da'vosi
    bo'lishi shart - bu faqat to'g'ri PIN kiritilgandan keyin
    (POST /moliyaviy/pin-tekshir orqali) 20 daqiqaga beriladigan alohida
    tokenlarda mavjud bo'ladi. Shu bilan boshqa admin PIN oynasini
    chetlab o'tib, to'g'ridan-to'g'ri so'rov yuborsa ham (masalan devtools
    orqali), oddiy login tokeni bilan bu ma'lumotni ola olmaydi."""
    if current_user.get("role") != "admin" or not current_user.get("moliyaviy_ruxsat"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Moliyaviy ma'lumotlarga kirish uchun PIN tasdiqlanishi kerak!",
        )
    return current_user