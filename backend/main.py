from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from database import engine, get_db, Base
from models import User, Mahsulot, Mashina, Hujjat, Olchov
from schemas import UserLogin, Token, UserCreate, MashinaCreate, HujjatCreate, OlchovCreate
from auth import verify_password, create_access_token, hash_password
import models
from typing import List
from datetime import datetime

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Hazorasp Tekstil Tarozi Tizimi", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============ XOTIRADA NAVBAT ============
navbat_royxati: List[dict] = []
tugallangan_royxati: List[dict] = []

# ============ ASOSIY ============

@app.get("/")
def root():
    return {"message": "Hazorasp Tekstil Tarozi Tizimi ishlamoqda!"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(
        User.username == user_data.username,
        User.role == user_data.role
    ).first()
    if not user or not verify_password(user_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Login yoki parol noto'g'ri!"
        )
    token = create_access_token({"sub": user.username, "role": user.role, "id": user.id})
    return {"access_token": token, "token_type": "bearer", "role": user.role, "username": user.username}

@app.post("/setup")
def setup(db: Session = Depends(get_db)):
    admin = db.query(User).filter(User.role == "admin").first()
    if admin:
        return {"message": "Admin allaqachon mavjud!"}
    new_admin = User(
        username="admin",
        password=hash_password("admin123"),
        role="admin",
        is_active=True
    )
    db.add(new_admin)
    new_operator = User(
        username="operator",
        password=hash_password("operator123"),
        role="operator",
        is_active=True
    )
    db.add(new_operator)
    mahsulotlar = [
        Mahsulot(nom="Chigit", konditsiya_bor=True),
        Mahsulot(nom="Chiganoq", konditsiya_bor=False),
        Mahsulot(nom="Chiganoq po'chog'i", konditsiya_bor=False),
    ]
    for m in mahsulotlar:
        db.add(m)
    db.commit()
    return {"message": "Tizim sozlandi!"}

# ============ MASHINALAR ============

@app.post("/mashinalar")
def mashina_qoshish(mashina: MashinaCreate, db: Session = Depends(get_db)):
    mavjud = db.query(Mashina).filter(
        Mashina.davlat_raqami == mashina.davlat_raqami
    ).first()
    if mavjud:
        return mavjud
    yangi = Mashina(**mashina.dict())
    db.add(yangi)
    db.commit()
    db.refresh(yangi)
    return yangi

@app.get("/mashinalar")
def mashinalar_royxati(db: Session = Depends(get_db)):
    return db.query(Mashina).all()

@app.get("/mashinalar/qidiruv/{raqam}")
def mashina_qidiruv(raqam: str, db: Session = Depends(get_db)):
    return db.query(Mashina).filter(
        Mashina.davlat_raqami.ilike(f"%{raqam}%")
    ).all()

# ============ MAHSULOTLAR ============

@app.get("/mahsulotlar")
def mahsulotlar_royxati(db: Session = Depends(get_db)):
    return db.query(Mahsulot).filter(Mahsulot.is_active == True).all()

# ============ HUJJATLAR ============

@app.post("/hujjatlar")
def hujjat_yaratish(hujjat: HujjatCreate, db: Session = Depends(get_db)):
    oxirgi = db.query(Hujjat).order_by(Hujjat.id.desc()).first()
    if oxirgi:
        raqam = int(oxirgi.raqam.split("/")[1]) + 1
        yil = oxirgi.raqam.split("/")[0]
    else:
        yil = str(datetime.now().year)
        raqam = 1
    yangi_raqam = f"{yil}/{str(raqam).zfill(3)}"
    yangi = Hujjat(raqam=yangi_raqam, **hujjat.dict())
    db.add(yangi)
    db.commit()
    db.refresh(yangi)
    return yangi

@app.get("/hujjatlar")
def hujjatlar_royxati(mahsulot_id: int = None, db: Session = Depends(get_db)):
    if mahsulot_id:
        hujjatlar = db.query(Hujjat).filter(Hujjat.mahsulot_id == mahsulot_id).all()
    else:
        hujjatlar = db.query(Hujjat).all()
    natija = []
    for h in hujjatlar:
        mashina = db.query(Mashina).filter(Mashina.id == h.mashina_id).first()
        olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
        jami_tara = sum(o.tara for o in olchovlar if o.tara) or None
        jami_brutto = sum(o.brutto for o in olchovlar if o.brutto) or None
        jami_netto = sum(o.netto for o in olchovlar if o.netto) or None
        jami_konditsion = sum(o.konditsion for o in olchovlar if o.konditsion) or None
        natija.append({
            "id": h.id,
            "raqam": h.raqam,
            "mashina_id": h.mashina_id,
            "mashina_raqami": mashina.davlat_raqami if mashina else "—",
            "shofyor": mashina.shofyor if mashina else "—",
            "firma": mashina.firma if mashina else "—",
            "mahsulot_id": h.mahsulot_id,
            "aravalar_soni": h.aravalar_soni,
            "holat": h.holat,
            "tara": jami_tara,
            "brutto": jami_brutto,
            "netto": jami_netto,
            "konditsion": jami_konditsion,
            "created_at": str(h.created_at) if h.created_at else None,
        })
    return natija

@app.get("/hujjatlar/{hujjat_id}")
def hujjat_detail(hujjat_id: int, db: Session = Depends(get_db)):
    hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    if not hujjat:
        raise HTTPException(status_code=404, detail="Hujjat topilmadi!")
    return hujjat

@app.put("/hujjatlar/{hujjat_id}")
def hujjat_yangilash(hujjat_id: int, data: dict, db: Session = Depends(get_db)):
    hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    if not hujjat:
        raise HTTPException(status_code=404, detail="Hujjat topilmadi!")
    for key, value in data.items():
        if hasattr(hujjat, key):
            setattr(hujjat, key, value)
    db.commit()
    db.refresh(hujjat)
    return hujjat

@app.delete("/hujjatlar/{hujjat_id}")
def hujjat_ochirish(hujjat_id: int, db: Session = Depends(get_db)):
    hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    if not hujjat:
        raise HTTPException(status_code=404, detail="Hujjat topilmadi!")
    db.delete(hujjat)
    db.commit()
    return {"message": "Hujjat o'chirildi!"}

# ============ OLCHOVLAR ============

@app.post("/olchovlar")
def olchov_saqlash(olchov: OlchovCreate, db: Session = Depends(get_db)):
    yangi = Olchov(**olchov.dict())
    if yangi.brutto and yangi.tara:
        yangi.netto = yangi.brutto - yangi.tara
        if yangi.namlik and yangi.ifloslik:
            yangi.konditsion = yangi.netto * (92 / (100 - yangi.namlik)) * (97 / (100 - yangi.ifloslik))
    db.add(yangi)
    db.commit()
    db.refresh(yangi)
    return yangi

@app.get("/olchovlar/{hujjat_id}")
def olchovlar_royxati(hujjat_id: int, db: Session = Depends(get_db)):
    return db.query(Olchov).filter(Olchov.hujjat_id == hujjat_id).all()

# ============ NAVBAT (xotirada) ============

@app.post("/navbat/qosh")
def navbat_qosh(data: dict):
    # Mavjud bo'lsa yangilash
    global navbat_royxati
    navbat_royxati = [m for m in navbat_royxati
                      if m.get("hujjatId") != data.get("hujjatId")]
    navbat_royxati.append(data)
    return {"status": "ok", "soni": len(navbat_royxati)}

@app.get("/navbat")
def navbat_get():
    return navbat_royxati

@app.post("/navbat/tugallandi")
def navbat_tugallandi(data: dict):
    global navbat_royxati
    navbat_royxati = [m for m in navbat_royxati
                      if m.get("hujjatId") != data.get("hujjatId")]
    data["tugallanganVaqt"] = str(datetime.now())
    tugallangan_royxati.insert(0, data)
    return {"status": "ok"}

@app.get("/navbat/tugallanganlar")
def tugallanganlar_get():
    return tugallangan_royxati

@app.post("/navbat/bekor")
def navbat_bekor(data: dict):
    global navbat_royxati
    navbat_royxati = [m for m in navbat_royxati
                      if m.get("hujjatId") != data.get("hujjatId")]
    return {"status": "ok"}

@app.delete("/navbat/tozala")
def navbat_tozala():
    global navbat_royxati, tugallangan_royxati
    navbat_royxati = []
    tugallangan_royxati = []
    return {"status": "ok"}

# ============ STATISTIKA ============

@app.get("/statistika/kunlik")
def kunlik_statistika(db: Session = Depends(get_db)):
    from datetime import date
    bugun = date.today()
    hujjatlar = db.query(Hujjat).filter(
        Hujjat.created_at >= bugun
    ).all()
    
    # Mahsulot bo'yicha
    chigit = [h for h in hujjatlar if h.mahsulot_id == 1]
    chiganoq = [h for h in hujjatlar if h.mahsulot_id == 2]
    pochog = [h for h in hujjatlar if h.mahsulot_id == 3]
    
    # Tonnaj hisoblash
    def tonnaj(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto:
                    jami += o.netto
        return round(jami / 1000, 2)
    
    return {
        "sana": str(bugun),
        "mashinalar_soni": len(hujjatlar),
        "tugallanganlar_soni": len(tugallangan_royxati),
        "navbat_soni": len(navbat_royxati),
        "chigit": {"soni": len(chigit), "tonnaj": tonnaj(chigit)},
        "chiganoq": {"soni": len(chiganoq), "tonnaj": tonnaj(chiganoq)},
        "pochog": {"soni": len(pochog), "tonnaj": tonnaj(pochog)},
        "jami_tonnaj": tonnaj(hujjatlar),
    }

@app.get("/statistika/haftalik")
def haftalik_statistika(db: Session = Depends(get_db)):
    from datetime import date, timedelta
    bugun = date.today()
    hafta_boshi = bugun - timedelta(days=7)
    hujjatlar = db.query(Hujjat).filter(
        Hujjat.created_at >= hafta_boshi
    ).all()
    
    chigit = [h for h in hujjatlar if h.mahsulot_id == 1]
    chiganoq = [h for h in hujjatlar if h.mahsulot_id == 2]
    pochog = [h for h in hujjatlar if h.mahsulot_id == 3]
    
    def tonnaj(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto:
                    jami += o.netto
        return round(jami / 1000, 2)
    
    return {
        "dan": str(hafta_boshi),
        "gacha": str(bugun),
        "mashinalar_soni": len(hujjatlar),
        "chigit": {"soni": len(chigit), "tonnaj": tonnaj(chigit)},
        "chiganoq": {"soni": len(chiganoq), "tonnaj": tonnaj(chiganoq)},
        "pochog": {"soni": len(pochog), "tonnaj": tonnaj(pochog)},
        "jami_tonnaj": tonnaj(hujjatlar),
    }

@app.get("/statistika/oylik")
def oylik_statistika(db: Session = Depends(get_db)):
    from datetime import date, timedelta
    bugun = date.today()
    oy_boshi = bugun.replace(day=1)
    hujjatlar = db.query(Hujjat).filter(
        Hujjat.created_at >= oy_boshi
    ).all()
    
    chigit = [h for h in hujjatlar if h.mahsulot_id == 1]
    chiganoq = [h for h in hujjatlar if h.mahsulot_id == 2]
    pochog = [h for h in hujjatlar if h.mahsulot_id == 3]
    
    def tonnaj(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto:
                    jami += o.netto
        return round(jami / 1000, 2)
    
    return {
        "oy": str(oy_boshi),
        "mashinalar_soni": len(hujjatlar),
        "chigit": {"soni": len(chigit), "tonnaj": tonnaj(chigit)},
        "chiganoq": {"soni": len(chiganoq), "tonnaj": tonnaj(chiganoq)},
        "pochog": {"soni": len(pochog), "tonnaj": tonnaj(pochog)},
        "jami_tonnaj": tonnaj(hujjatlar),
    }
    
    # ============ BACKUP ============

import os
import shutil
from datetime import datetime

@app.post("/backup")
def backup_qilish():
    try:
        backup_dir = r"C:\hazorasp_tarozi\backup"
        os.makedirs(backup_dir, exist_ok=True)
        
        sana = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        backup_fayl = os.path.join(backup_dir, f"backup_{sana}.sql")
        
        pg_dump = r"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
        
        import subprocess
        result = subprocess.run(
    [pg_dump, "-U", "postgres", "-p", "5433", "-d", "hazorasp_tarozi", "-f", backup_fayl],
    capture_output=True, text=True,
    env={**os.environ, "PGPASSWORD": "Xorazm2026"}
)
        
        if result.returncode == 0:
            size = os.path.getsize(backup_fayl)
            return {
                "status": "ok",
                "fayl": backup_fayl,
                "vaqt": sana,
                "hajm": f"{size // 1024} KB"
            }
        else:
            return {"status": "error", "message": result.stderr}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/backup/royxat")
def backup_royxat():
    try:
        backup_dir = r"C:\hazorasp_tarozi\backup"
        os.makedirs(backup_dir, exist_ok=True)
        fayllar = os.listdir(backup_dir)
        fayllar.sort(reverse=True)
        return {"fayllar": fayllar, "soni": len(fayllar)}
    except Exception as e:
        return {"status": "error", "message": str(e)}
  # ============ AVTOMATIK BACKUP ============
import threading

def avtomatik_telegram_hisobot():
    import time
    while True:
        now = datetime.now()
        if now.hour == 20 and now.minute == 0:
            try:
                from datetime import date
                db = next(get_db())
                bugun = date.today()
                hujjatlar = db.query(Hujjat).filter(
                    Hujjat.created_at >= bugun
                ).all()
                chigit = len([h for h in hujjatlar if h.mahsulot_id == 1])
                chiganoq = len([h for h in hujjatlar if h.mahsulot_id == 2])
                pochog = len([h for h in hujjatlar if h.mahsulot_id == 3])
                matn = f"""📊 <b>KUNLIK HISOBOT</b>
📅 Sana: {bugun}

🚛 Jami mashinalar: <b>{len(hujjatlar)} ta</b>
🟡 Chigit: <b>{chigit} ta</b>
🟢 Chiganoq: <b>{chiganoq} ta</b>
🟠 Chiganoq po'chog'i: <b>{pochog} ta</b>

🏭 Hazorasp Tekstil tarozi tizimi"""
                telegram_xabar_yuborish(matn)
                print(f"✅ Avtomatik hisobot yuborildi: {bugun}")
            except Exception as e:
                print(f"❌ Hisobot xato: {e}")
            time.sleep(61)
        time.sleep(30)

hisobot_thread = threading.Thread(target=avtomatik_telegram_hisobot, daemon=True)
hisobot_thread.start()

def avtomatik_backup():
    import time
    while True:
        now = datetime.now()
        # Har kuni soat 23:00 da
        if now.hour == 23 and now.minute == 0:
            try:
                backup_dir = r"C:\hazorasp_tarozi\backup"
                os.makedirs(backup_dir, exist_ok=True)
                sana = now.strftime("%Y-%m-%d_%H-%M-%S")
                backup_fayl = os.path.join(backup_dir, f"backup_{sana}.sql")
                pg_dump = r"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
                import subprocess
                subprocess.run(
                    [pg_dump, "-U", "postgres", "-p", "5433", "-d", "hazorasp_tarozi", "-f", backup_fayl],
                    env={**os.environ, "PGPASSWORD": "Xorazm2026"}
                )
                print(f"✅ Avtomatik backup: {backup_fayl}")
            except Exception as e:
                print(f"❌ Backup xato: {e}")
            time.sleep(61)
        time.sleep(30)

# Serverni ishga tushirganda backup thread boshlash
backup_thread = threading.Thread(target=avtomatik_backup, daemon=True)
backup_thread.start()
# ============ TELEGRAM BOT ============
import requests as req

def telegram_xabar_yuborish(matn: str):
    try:
        from config import TELEGRAM_TOKEN, TELEGRAM_CHAT_ID
        if not TELEGRAM_TOKEN or not TELEGRAM_CHAT_ID:
            return
        url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        req.post(url, json={
            "chat_id": TELEGRAM_CHAT_ID,
            "text": matn,
            "parse_mode": "HTML"
        })
    except Exception as e:
        print(f"Telegram xato: {e}")

@app.post("/telegram/test")
def telegram_test():
    telegram_xabar_yuborish("✅ Hazorasp Tekstil tarozi tizimi ulandi!")
    return {"status": "ok"}

@app.get("/telegram/kunlik")
def telegram_kunlik(db: Session = Depends(get_db)):
    from datetime import date
    bugun = date.today()
    hujjatlar = db.query(Hujjat).filter(
        Hujjat.created_at >= bugun
    ).all()
    
    def tonnaj_hisob(mahsulot_id):
        h_list = [h for h in hujjatlar if h.mahsulot_id == mahsulot_id]
        jami_netto = 0
        jami_kond = 0
        for h in h_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto: jami_netto += o.netto
                if o.konditsion: jami_kond += o.konditsion
        return len(h_list), round(jami_netto/1000, 2), round(jami_kond/1000, 2)
    
    chigit_son, chigit_netto, chigit_kond = tonnaj_hisob(1)
    chiganoq_son, chiganoq_netto, _ = tonnaj_hisob(2)
    pochog_son, pochog_netto, _ = tonnaj_hisob(3)
    
    matn = f"""📊 <b>KUNLIK HISOBOT</b>
📅 Sana: {bugun}

🚛 Jami mashinalar: <b>{len(hujjatlar)} ta</b>

🟡 <b>Chigit:</b> {chigit_son} ta
   • Netto: <b>{chigit_netto} t</b>
   • Konditsion: <b>{chigit_kond} t</b>

🟢 <b>Chiganoq:</b> {chiganoq_son} ta
   • Netto: <b>{chiganoq_netto} t</b>

🟠 <b>Chiganoq po'chog'i:</b> {pochog_son} ta
   • Netto: <b>{pochog_netto} t</b>

🏭 Hazorasp Tekstil tarozi tizimi"""
    
    telegram_xabar_yuborish(matn)
    return {"status": "ok", "xabar": matn}
 # ============ KAMERA ============
from pathlib import Path
import concurrent.futures

KAMERA_1 = "10.112.12.43"
KAMERA_2 = "10.112.12.47"
KAMERA_LOGIN = "test"
KAMERA_PAROL = "Test@123"

def bir_kameradan_rasm_ol(cam_ip, fayl_yol):
    try:
        url = f"http://{cam_ip}/ISAPI/Streaming/channels/101/picture"
        response = req.get(
            url,
            auth=req.auth.HTTPDigestAuth(KAMERA_LOGIN, KAMERA_PAROL),
            timeout=5
        )
        if response.status_code == 200:
            with open(fayl_yol, "wb") as f:
                f.write(response.content)
            return {"status": "ok", "fayl": str(fayl_yol)}
        else:
            return {"status": "error", "message": f"Kamera {cam_ip} javob bermadi"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/kamera/rasm")
def rasm_ol(data: dict):
    try:
        mashina_raqami = data.get("mashina_raqami", "noma_lum")
        mahsulot_nomi = data.get("mahsulot_nomi", "Chigit")
        tur = data.get("tur", "tara")
        
        sana = datetime.now().strftime("%Y-%m-%d")
        vaqt = datetime.now().strftime("%H-%M-%S")
        raqam = mashina_raqami.replace(" ", "_").replace("/", "_")
        
        papka = Path(f"C:/RASMLAR/{sana}/{mahsulot_nomi}/{raqam}")
        papka.mkdir(parents=True, exist_ok=True)
        
        fayl1 = papka / f"{tur}_cam1_{vaqt}.jpg"
        fayl2 = papka / f"{tur}_cam2_{vaqt}.jpg"
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            future1 = executor.submit(bir_kameradan_rasm_ol, KAMERA_1, fayl1)
            future2 = executor.submit(bir_kameradan_rasm_ol, KAMERA_2, fayl2)
            natija1 = future1.result()
            natija2 = future2.result()
        
        return {
            "status": "ok",
            "vaqt": vaqt,
            "kamera1": natija1,
            "kamera2": natija2,
            "papka": str(papka)
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}