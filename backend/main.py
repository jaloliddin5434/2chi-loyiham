from fastapi import FastAPI, Depends, HTTPException, status, Request
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
            yangi.konditsion = yangi.netto * (100 - (yangi.namlik + yangi.ifloslik)) / 89.5
    db.add(yangi)
    db.commit()
    db.refresh(yangi)
    if yangi.brutto and yangi.tara:
        print(f"Excel ga yozilmoqda: hujjat_id={yangi.hujjat_id}")
        excel_qatorga_yoz(yangi.hujjat_id, db)
    return yangi

@app.get("/olchovlar/{hujjat_id}")
def olchovlar_royxati(hujjat_id: int, db: Session = Depends(get_db)):
    return db.query(Olchov).filter(Olchov.hujjat_id == hujjat_id).all()

# ============ NAVBAT (PostgreSQL) ============
import json

@app.post("/navbat/qosh")
def navbat_qosh(data: dict, db: Session = Depends(get_db)):
    from models import Navbat
    mavjud = db.query(Navbat).filter(Navbat.hujjat_id == data.get("hujjatId")).first()
    if mavjud:
        db.delete(mavjud)
        db.commit()
    yangi = Navbat(
        hujjat_id=data.get("hujjatId"),
        mashina_id=data.get("mashinaId"),
        raqam=data.get("raqam"),
        turi=data.get("turi"),
        shofyor=data.get("shofyor"),
        firma=data.get("firma"),
        mahsulot_id=data.get("mahsulotId"),
        mahsulot_nomi=data.get("mahsulotNomi"),
        vaqt=data.get("vaqt"),
        tuda_raqam=data.get("tudaRaqam"),
        tiket_raqam=data.get("tiketRaqam"),
        seleksiya_navi=data.get("seleksiyaNavi"),
        klass=data.get("klass"),
        sinf=data.get("sinf"),
        terim_turi=data.get("terimTuri"),
        namlik=data.get("namlik"),
        ifloslik=data.get("ifloslik"),
        tugallandi=False,
        aravalar_json=json.dumps(data.get("aravalar", {})),
    )
    db.add(yangi)
    db.commit()
    return {"status": "ok"}

@app.get("/navbat")
def navbat_get(db: Session = Depends(get_db)):
    from models import Navbat
    navbat = db.query(Navbat).filter(Navbat.tugallandi == False).order_by(Navbat.kelgan_vaqt.asc()).all()
    natija = []
    for n in navbat:
        natija.append({
            "hujjatId": n.hujjat_id,
            "mashinaId": n.mashina_id,
            "raqam": n.raqam,
            "turi": n.turi,
            "shofyor": n.shofyor,
            "firma": n.firma,
            "mahsulotId": n.mahsulot_id,
            "mahsulotNomi": n.mahsulot_nomi,
            "vaqt": n.vaqt,
            "tudaRaqam": n.tuda_raqam,
            "tiketRaqam": n.tiket_raqam,
            "seleksiyaNavi": n.seleksiya_navi,
            "klass": n.klass,
            "sinf": n.sinf,
            "terimTuri": n.terim_turi,
            "namlik": n.namlik,
            "ifloslik": n.ifloslik,
            "aravalar": json.loads(n.aravalar_json) if n.aravalar_json else {},
            "hujjatRaqam": db.query(Hujjat).filter(Hujjat.id == n.hujjat_id).first().raqam if n.hujjat_id else '',
        })
        
    return natija

@app.post("/navbat/tugallandi")
def navbat_tugallandi(data: dict, db: Session = Depends(get_db)):
    from models import Navbat
    navbat = db.query(Navbat).filter(Navbat.hujjat_id == data.get("hujjatId")).first()
    if navbat:
        navbat.tugallandi = True
        navbat.tugallangan_vaqt = datetime.now()
        navbat.aravalar_json = json.dumps(data.get("aravalar", {}))
        db.commit()
    return {"status": "ok"}

@app.get("/navbat/tugallanganlar")
def tugallanganlar_get(db: Session = Depends(get_db)):
    from models import Navbat
    from datetime import timedelta
    kun_oldin = datetime.now() - timedelta(hours=24)
    tugallanganlar = db.query(Navbat).filter(
        Navbat.tugallandi == True,
        Navbat.tugallangan_vaqt >= kun_oldin
    ).order_by(Navbat.tugallangan_vaqt.desc()).all()
    natija = []
    for n in tugallanganlar:
        natija.append({
            "hujjatId": n.hujjat_id,
            "mashinaId": n.mashina_id,
            "raqam": n.raqam,
            "turi": n.turi,
            "shofyor": n.shofyor,
            "firma": n.firma,
            "mahsulotId": n.mahsulot_id,
            "mahsulotNomi": n.mahsulot_nomi,
            "vaqt": n.vaqt,
            "tugallanganVaqt": str(n.tugallangan_vaqt) if n.tugallangan_vaqt else None,
            "aravalar": json.loads(n.aravalar_json) if n.aravalar_json else {},
        })
    return natija

@app.post("/navbat/bekor")
def navbat_bekor(data: dict, db: Session = Depends(get_db)):
    from models import Navbat
    navbat = db.query(Navbat).filter(Navbat.hujjat_id == data.get("hujjatId")).first()
    if navbat:
        db.delete(navbat)
        db.commit()
    return {"status": "ok"}

@app.delete("/navbat/tozala")
def navbat_tozala(db: Session = Depends(get_db)):
    from models import Navbat
    db.query(Navbat).delete()
    db.commit()
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
    patoz = [h for h in hujjatlar if h.mahsulot_id == 4]
    patoz = [h for h in hujjatlar if h.mahsulot_id == 4]
    
    # Tonnaj hisoblash
    def tonnaj(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto:
                    jami += o.netto
        return round(jami / 1000, 2)
    
    def konditsion_hisob(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.konditsion:
                    jami += o.konditsion
        return round(jami / 1000, 2)

    from models import Navbat as NavbatModel
    navbat_soni = db.query(NavbatModel).filter(NavbatModel.tugallandi == False).count()
    tugallangan_soni = db.query(NavbatModel).filter(NavbatModel.tugallandi == True).count()

    return {
        "sana": str(bugun),
        "mashinalar_soni": len(hujjatlar),
        "tugallanganlar_soni": tugallangan_soni,
        "navbat_soni": navbat_soni,
        "chigit": {"soni": len(chigit), "tonnaj": tonnaj(chigit), "konditsion": konditsion_hisob(chigit)},
        "chiganoq": {"soni": len(chiganoq), "tonnaj": tonnaj(chiganoq)},
        "pochog": {"soni": len(pochog), "tonnaj": tonnaj(pochog)},
        "patoz": {"soni": len(patoz), "tonnaj": tonnaj(patoz)},
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
    patoz = [h for h in hujjatlar if h.mahsulot_id == 4]
    
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
    patoz = [h for h in hujjatlar if h.mahsulot_id == 4]
    
    def tonnaj(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto:
                    jami += o.netto
        return round(jami / 1000, 2)
    
    def konditsion_hisob(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.konditsion:
                    jami += o.konditsion
        return round(jami / 1000, 2)

    return {
        "oy": str(oy_boshi),
        "mashinalar_soni": len(hujjatlar),
        "chigit": {"soni": len(chigit), "tonnaj": tonnaj(chigit), "konditsion": konditsion_hisob(chigit)},
        "chiganoq": {"soni": len(chiganoq), "tonnaj": tonnaj(chiganoq)},
        "pochog": {"soni": len(pochog), "tonnaj": tonnaj(pochog)},
        "patoz": {"soni": len(patoz), "tonnaj": tonnaj(patoz)},
        "jami_tonnaj": tonnaj(hujjatlar),
    }
    
@app.get("/statistika/mavsum")
def mavsum_statistika(db: Session = Depends(get_db)):
    from datetime import date
    bugun = date.today()
    # Mavsum: 1 Avgust dan 31 Iyul gacha
    if bugun.month >= 8:
        mavsum_boshi = date(bugun.year, 8, 1)
    else:
        mavsum_boshi = date(bugun.year - 1, 8, 1)
    
    hujjatlar = db.query(Hujjat).filter(
        Hujjat.created_at >= mavsum_boshi
    ).all()
    
    chigit = [h for h in hujjatlar if h.mahsulot_id == 1]
    chiganoq = [h for h in hujjatlar if h.mahsulot_id == 2]
    pochog = [h for h in hujjatlar if h.mahsulot_id == 3]
    patoz = [h for h in hujjatlar if h.mahsulot_id == 4]
    
    def tonnaj(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.netto:
                    jami += o.netto
        return round(jami / 1000, 2)
    
    def konditsion_hisob(hujjat_list):
        jami = 0
        for h in hujjat_list:
            olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar:
                if o.konditsion:
                    jami += o.konditsion
        return round(jami / 1000, 2)
    
    return {
        "mavsum_boshi": str(mavsum_boshi),
        "mashinalar_soni": len(hujjatlar),
        "chigit": {"soni": len(chigit), "tonnaj": tonnaj(chigit), "konditsion": konditsion_hisob(chigit)},
        "chiganoq": {"soni": len(chiganoq), "tonnaj": tonnaj(chiganoq)},
        "pochog": {"soni": len(pochog), "tonnaj": tonnaj(pochog)},
        "patoz": {"soni": len(patoz), "tonnaj": tonnaj(patoz)},
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
        if now.hour == 15 and now.minute == 58:
            try:
                from datetime import date
                db = next(get_db())
                bugun = date.today()
                hujjatlar = db.query(Hujjat).filter(
                    Hujjat.created_at >= bugun
                ).all()
                def tonnaj(mahsulot_id):
                    h_list = [h for h in hujjatlar if h.mahsulot_id == mahsulot_id]
                    jami_netto = 0
                    jami_kond = 0
                    for h in h_list:
                        olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
                        for o in olchovlar:
                            if o.netto: jami_netto += o.netto
                            if o.konditsion: jami_kond += o.konditsion
                    return len(h_list), round(jami_netto/1000, 2), round(jami_kond/1000, 2)
                
                chigit_son, chigit_netto, chigit_kond = tonnaj(1)
                chiganoq_son, chiganoq_netto, _ = tonnaj(2)
                pochog_son, pochog_netto, _ = tonnaj(3)
                patoz_son, patoz_netto, _ = tonnaj(4)
                
                # Mavsum statistikasi
                from datetime import date as d
                bugun_d = d.today()
                if bugun_d.month >= 8:
                    mavsum_boshi = datetime(bugun_d.year, 8, 1)
                else:
                    mavsum_boshi = datetime(bugun_d.year - 1, 8, 1)
                mavsum_hujjatlar = db.query(Hujjat).filter(Hujjat.created_at >= mavsum_boshi).all()
                
                def mavsum_tonnaj(mahsulot_id):
                    h_list = [h for h in mavsum_hujjatlar if h.mahsulot_id == mahsulot_id]
                    jami_netto = 0
                    jami_kond = 0
                    for h in h_list:
                        olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
                        for o in olchovlar:
                            if o.netto: jami_netto += o.netto
                            if o.konditsion: jami_kond += o.konditsion
                    return len(h_list), round(jami_netto/1000, 2), round(jami_kond/1000, 2)
                
                mchigit_son, mchigit_netto, mchigit_kond = mavsum_tonnaj(1)
                mchiganoq_son, mchiganoq_netto, _ = mavsum_tonnaj(2)
                mpochog_son, mpochog_netto, _ = mavsum_tonnaj(3)
                mpatoz_son, mpatoz_netto, _ = mavsum_tonnaj(4)
                
                matn = f"""📊 <b>KUNLIK HISOBOT</b>
📅 Sana: {bugun}

🚛 Jami: <b>{len(hujjatlar)} ta</b>

🟡 <b>Chigit:</b> {chigit_son} ta | Netto: <b>{chigit_netto} t</b> | Kond: <b>{chigit_kond} t</b>
🟢 <b>Chiganoq:</b> {chiganoq_son} ta | Netto: <b>{chiganoq_netto} t</b>
🟠 <b>Pochog:</b> {pochog_son} ta | Netto: <b>{pochog_netto} t</b>
🔴 <b>Patoz:</b> {patoz_son} ta | Netto: <b>{patoz_netto} t</b>

━━━━━━━━━━━━━━━
📦 <b>MAVSUM JAMI</b>
🟡 Chigit: {mchigit_son} ta | {mchigit_netto} t | Kond: {mchigit_kond} t
🟢 Chiganoq: {mchiganoq_son} ta | {mchiganoq_netto} t
🟠 Pochog: {mpochog_son} ta | {mpochog_netto} t
🔴 Patoz: {mpatoz_son} ta | {mpatoz_netto} t

🏭 Hazorasp Tekstil tarozi tizimi"""
                telegram_xabar_yuborish(matn)
                print(f"✅ Avtomatik hisobot yuborildi: {bugun}")
            except Exception as e:
                print(f"❌ Hisobot xato: {e}")
            time.sleep(61)
        time.sleep(30)


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
# ============ EXCEL HISOBOT ============
import openpyxl
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side

def excel_qatorga_yoz(hujjat_id, db):
    try:
        from datetime import date
        bugun = date.today()
        fayl_yol = f"C:/RASMLAR/hisobot_{bugun.year}.xlsx"
        
        try:
            wb = openpyxl.load_workbook(fayl_yol)
            ws = wb.active
        except:
            wb = openpyxl.Workbook()
            ws = wb.active
            ws.title = "Hisobot"
            ws.append(["№", "Наклад №", "Маҳсулот", "Тара", "Брутто", "Нетто", "Кондицион", "Машина", "Юк олувчи", "Сана"])
            for cell in ws[1]:
                cell.fill = PatternFill(start_color="1A4A08", end_color="1A4A08", fill_type="solid")
                cell.font = Font(bold=True, color="FFFFFF")
        
        hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
        if not hujjat:
            return
        
        mashina = db.query(Mashina).filter(Mashina.id == hujjat.mashina_id).first()
        olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == hujjat_id).all()
        mahsulot = db.query(Mahsulot).filter(Mahsulot.id == hujjat.mahsulot_id).first()
        mahsulot_nomi = mahsulot.nom if mahsulot else ""
        
        for o in olchovlar:
            if o.tara and o.brutto:
                qator_raqam = ws.max_row
                ws.append([
                    qator_raqam,
                    hujjat.raqam,
                    mahsulot_nomi,
                    round(o.tara),
                    round(o.brutto),
                    round(o.netto) if o.netto else 0,
                    round(o.konditsion) if o.konditsion else 0,
                    mashina.davlat_raqami if mashina else "",
                    mashina.firma if mashina else "",
                    str(bugun),
                ])
        
        wb.save(fayl_yol)
        print(f"✅ Excel ga yozildi: {hujjat.raqam} ({mahsulot_nomi})")
    except Exception as e:
        print(f"❌ Excel xato: {e}")
# ============ SOZLAMALAR ============
from models import Sozlama

@app.get("/sozlamalar")
def sozlamalar_olish(db: Session = Depends(get_db)):
    sozlamalar = db.query(Sozlama).all()
    natija = {}
    for s in sozlamalar:
        natija[s.kalit] = s.qiymat
    return natija

@app.post("/sozlamalar")
def sozlama_saqlash(data: dict, db: Session = Depends(get_db)):
    for kalit, qiymat in data.items():
        mavjud = db.query(Sozlama).filter(Sozlama.kalit == kalit).first()
        if mavjud:
            mavjud.qiymat = str(qiymat)
            mavjud.updated_at = datetime.now()
        else:
            yangi = Sozlama(kalit=kalit, qiymat=str(qiymat))
            db.add(yangi)
    db.commit()
    return {"status": "ok"}

# ============ SERVER HOLATI ============
import psutil

@app.get("/server/holat")
def server_holat():
    try:
        cpu = psutil.cpu_percent(interval=1)
        ram = psutil.virtual_memory()
        disk = psutil.disk_usage('C:/')
        uptime_seconds = (datetime.now() - datetime.fromtimestamp(psutil.boot_time())).total_seconds()
        kun = int(uptime_seconds // 86400)
        soat = int((uptime_seconds % 86400) // 3600)
        return {
            "cpu": round(cpu, 1),
            "ram": round(ram.percent, 1),
            "disk": round(disk.percent, 1),
            "uptime": f"{kun} kun {soat} soat"
        }
    except Exception as e:
        return {"cpu": 0, "ram": 0, "disk": 0, "uptime": "—"}

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

hisobot_thread = threading.Thread(target=avtomatik_telegram_hisobot, daemon=True)
hisobot_thread.start()

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
    patoz_son, patoz_netto, _ = tonnaj_hisob(4)
    
    if bugun.month >= 8:
        mavsum_boshi = datetime(bugun.year, 8, 1)
    else:
        mavsum_boshi = datetime(bugun.year - 1, 8, 1)
    mavsum_hujjatlar = db.query(Hujjat).filter(Hujjat.created_at >= mavsum_boshi).all()
    
    def mavsum_tonnaj(mahsulot_id):
        h_list = [h for h in mavsum_hujjatlar if h.mahsulot_id == mahsulot_id]
        jami_netto = 0
        jami_kond = 0
        for h in h_list:
            olchovlar_m = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
            for o in olchovlar_m:
                if o.netto: jami_netto += o.netto
                if o.konditsion: jami_kond += o.konditsion
        return len(h_list), round(jami_netto/1000, 2), round(jami_kond/1000, 2)
    
    mchigit_son, mchigit_netto, mchigit_kond = mavsum_tonnaj(1)
    mchiganoq_son, mchiganoq_netto, _ = mavsum_tonnaj(2)
    mpochog_son, mpochog_netto, _ = mavsum_tonnaj(3)
    mpatoz_son, mpatoz_netto, _ = mavsum_tonnaj(4)
    
    matn = f"""📊 <b>KUNLIK HISOBOT</b>
📅 Sana: {bugun}

🚛 Jami: <b>{len(hujjatlar)} ta</b>

🟡 <b>Chigit:</b> {chigit_son} ta | Netto: <b>{chigit_netto} t</b> | Kond: <b>{chigit_kond} t</b>
🟢 <b>Chiganoq:</b> {chiganoq_son} ta | Netto: <b>{chiganoq_netto} t</b>
🟠 <b>Pochog:</b> {pochog_son} ta | Netto: <b>{pochog_netto} t</b>
🔴 <b>Patoz:</b> {patoz_son} ta | Netto: <b>{patoz_netto} t</b>

━━━━━━━━━━━━━━━
📦 <b>MAVSUM JAMI</b>
🟡 Chigit: {mchigit_son} ta | {mchigit_netto} t | Kond: {mchigit_kond} t
🟢 Chiganoq: {mchiganoq_son} ta | {mchiganoq_netto} t
🟠 Pochog: {mpochog_son} ta | {mpochog_netto} t
🔴 Patoz: {mpatoz_son} ta | {mpatoz_netto} t

🏭 Hazorasp Tekstil tarozi tizimi"""
    
    telegram_xabar_yuborish(matn)
    return {"status": "ok", "xabar": matn}
 # ============ PDF SAQLASH ============

@app.post("/nakladnoy/saqlash")
async def nakladnoy_saqlash(request: Request, db: Session = Depends(get_db)):
    try:
        data = await request.json()
        mashina_raqami = data.get("mashina_raqami", "noma_lum")
        mahsulot_nomi = data.get("mahsulot_nomi", "Chigit")
        sana = data.get("sana", datetime.now().strftime("%Y-%m-%d"))
        print(f"Kelgan data: tara1={data.get('tara1')}, brutto1={data.get('brutto1')}, firma={data.get('firma')}")
        tara1 = float(data.get("tara1", 0) or 0)
        brutto1 = float(data.get("brutto1", 0) or 0)
        netto1 = brutto1 - tara1
        tara2 = float(data.get("tara2", 0) or 0)
        brutto2 = float(data.get("brutto2", 0) or 0)
        netto2 = brutto2 - tara2
        tara3 = float(data.get("tara3", 0) or 0)
        brutto3 = float(data.get("brutto3", 0) or 0)
        netto3 = brutto3 - tara3
        tiket = data.get("tiket", "")
        nakladnoy_raqam = data.get("nakladnoy_raqam", "")
        hujjat_id_val = data.get("hujjat_id", None)
        if hujjat_id_val:
            hujjat_obj = db.query(Hujjat).filter(Hujjat.id == hujjat_id_val).first()
            if hujjat_obj:
                nakladnoy_raqam = hujjat_obj.raqam
                print(f"nakladnoy_raqam: {nakladnoy_raqam}")
            else:
                print(f"hujjat topilmadi: {hujjat_id_val}")
        else:
            print(f"hujjat_id_val yoq: {data.get('hujjat_id')}")
        firma = data.get("firma", "")
        konditsion1_raw = data.get("konditsion1", 0)
        hujjat_id_raw = data.get("hujjat_id", None)
        if (not konditsion1_raw or konditsion1_raw == 0) and hujjat_id_raw:
            olchovlar_db = db.query(Olchov).filter(Olchov.hujjat_id == hujjat_id_raw).all()
            konditsion1 = sum(o.konditsion for o in olchovlar_db if o.konditsion) or 0
        else:
            konditsion1 = float(konditsion1_raw or 0)
        
        
        namlik = data.get("namlik", "") or "—"
        ifloslik = data.get("ifloslik", "") or "—"
        shofyor = data.get("shofyor", "")
        seleksiya = data.get("seleksiya", "")
        klass = data.get("klass", "")
        terim_turi = data.get("terim_turi", "")
        tuda_raqam = data.get("tuda_raqam", "")
        qabul_qildi = data.get("qabul_qildi", "")
        yuk_olindi = data.get("yuk_olindi", "")
        dostaverka = data.get("dostaverka", "")
        dostaverka_vaqt = data.get("dostaverka_vaqt", "")
        mashina_turi = data.get("mashina_turi", "")
        arava1_qator = f"<tr><td>1-arava</td><td>{round(tara1)}</td><td>{round(brutto1)}</td><td>{round(netto1)}</td><td>{round(konditsion1)}</td></tr>" if tara1 > 0 else ""
        arava2_qator = f"<tr><td>2-arava</td><td>{round(tara2)}</td><td>{round(brutto2)}</td><td>{round(netto2)}</td><td>-</td></tr>" if tara2 > 0 else ""
        arava3_qator = f"<tr><td>3-arava</td><td>{round(tara3)}</td><td>{round(brutto3)}</td><td>{round(netto3)}</td><td>-</td></tr>" if tara3 > 0 else ""
        html_content = f"""<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
body {{ font-family: Arial; font-size: 16px; margin: 20px; }}
h2 {{ text-align: center; font-size: 18px; margin: 10px 0; }}
h3 {{ text-align: center; font-size: 16px; margin: 8px 0; }}
p {{ margin: 8px 0; }}
table {{ width: 100%; border-collapse: collapse; margin: 12px 0; }}
th, td {{ border: 1px solid black; padding: 12px 15px; line-height: 1.6; }}
th {{ background: #1A4A08; color: white; text-align: center; }}
td {{ text-align: center; }}
td.left {{ text-align: left; }}
.jami {{ font-weight: bold; }}
.imzo {{ border: none; padding: 12px 0; }}
</style></head>
<body>
<h2>ЗАВОД НУСХАСИ</h2>
<h2>ТОВАР ТРАНСПОРТ НАКЛАДНОЙ № {nakladnoy_raqam} &nbsp;&nbsp; Тикет №: {tiket}</h2>
<h3>Ishlab chiqarishdan qabul qilingan mahsulotlarni tashish uchun</h3>
<p style="text-align:center">Sana: {sana} &nbsp;&nbsp; Mashina turi: {mashina_turi} &nbsp;&nbsp; Raqam: {mashina_raqami}</p>
<table style="margin-bottom:8px">
<tr><td class="left"><b>Юк жўнатувчи:</b> "Ҳазорасп текстил" МЧЖга қарашли пахта тозалаш завод</td></tr>
<tr><td class="left"><b>Юк олувчи:</b> {firma}</td></tr>
</table>
<table style="margin-bottom:8px">
<tr>
  <td class="left"><b>Тикет №:</b> {tiket}</td>
  <td class="left"><b>Сана:</b> {sana}</td>
  <td class="left"><b>Туда №:</b> {tuda_raqam}</td>
</tr>
<tr>
  <td class="left"><b>Терим тури:</b> {terim_turi}</td>
  <td class="left"><b>Класс:</b> {klass}</td>
  <td class="left"><b>Селексия нави:</b> {seleksiya}</td>
</tr>
<tr>
  <td class="left"><b>Намлик %:</b> {namlik}</td>
  <td class="left"><b>Ифлослик %:</b> {ifloslik}</td>
  <td class="left"><b>Шофёр:</b> {shofyor}</td>
</tr>
</table>
<table>
<tr>
  <th>Юкнинг номи</th>
  <th>Тара (Урама), кг</th>
  <th>Брутто (Урама б/н), кг</th>
  <th>Нетто (Соф), кг</th>
  <th>Кондицион вазн, кг</th>
</tr>
{arava1_qator}
{arava2_qator}
{arava3_qator}
<tr class="jami">
  <td>Жами:</td>
  <td>{round(tara1+tara2+tara3)}</td>
  <td>{round(brutto1+brutto2+brutto3)}</td>
  <td>{round(netto1+netto2+netto3)}</td>
  <td>{round(konditsion1)}</td>
</tr>
</table>
<p style="margin-top:8px"><b>Доставерна № {dostaverka}</b> &nbsp;&nbsp; Муддат: {dostaverka_vaqt}</p>
<table style="margin-top:10px;border:none">
<tr>
  <td class="imzo">Қабул қилди: {qabul_qildi} ___________</td>
  <td class="imzo">Юк олинди: {yuk_olindi} ___________</td>
</tr>
<tr>
  <td class="imzo">Раҳбар ИМЗО ___________</td>
  <td class="imzo">Шофёр ИМЗО ___________</td>
</tr>
<tr>
  <td class="imzo">Юк олиб кетувчи ИМЗО ___________</td>
  <td class="imzo">Таразбон ИМЗО ___________</td>
</tr>
</table>
</body></html>"""

        raqam = mashina_raqami.replace(" ", "_").replace("/", "_")
        papka = Path(f"C:/RASMLAR/{sana}/{mahsulot_nomi}/{raqam}")
        papka.mkdir(parents=True, exist_ok=True)
        
        html_fayl = papka / "nakladnoy.html"
        with open(html_fayl, "w", encoding="utf-8") as f:
            f.write(html_content)
        print(f"arava1_qator: {arava1_qator}")
        print(f"HTML uzunligi: {len(html_content)}")
        
        pdf_fayl = papka / "nakladnoy.pdf"
        import pdfkit
        wkhtmltopdf_yol = r"C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
        config = pdfkit.configuration(wkhtmltopdf=wkhtmltopdf_yol)
        options = {'orientation': 'Landscape', 'page-size': 'A4'}
        pdfkit.from_file(str(html_fayl), str(pdf_fayl), configuration=config, options=options)
       
        
        return {"status": "ok", "fayl": str(pdf_fayl)}
    except Exception as e:
        print(f"XATO: {e}")
        import traceback
        traceback.print_exc()
        return {"status": "error", "message": str(e)}

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

# ============ GRAFIK MA'LUMOTLAR ============

@app.get("/statistika/grafik/kunlik")
def grafik_kunlik(db: Session = Depends(get_db)):
    from datetime import date, timedelta
    natija = []
    for i in range(6, -1, -1):
        kun = date.today() - timedelta(days=i)
        keyingi_kun = kun + timedelta(days=1)
        hujjatlar = db.query(Hujjat).filter(
            Hujjat.created_at >= kun,
            Hujjat.created_at < keyingi_kun
        ).all()
        chigit = len([h for h in hujjatlar if h.mahsulot_id == 1])
        chiganoq = len([h for h in hujjatlar if h.mahsulot_id == 2])
        pochog = len([h for h in hujjatlar if h.mahsulot_id == 3])
        natija.append({
            "kun": str(kun),
            "chigit": chigit,
            "chiganoq": chiganoq,
            "pochog": pochog,
            "jami": len(hujjatlar)
        })
    return natija

@app.get("/statistika/grafik/oylik")
def grafik_oylik(db: Session = Depends(get_db)):
    from datetime import date, timedelta
    bugun = date.today()
    oy_boshi = bugun.replace(day=1)
    natija = []
    kun = oy_boshi
    while kun <= bugun:
        keyingi_kun = kun + timedelta(days=1)
        hujjatlar = db.query(Hujjat).filter(
            Hujjat.created_at >= kun,
            Hujjat.created_at < keyingi_kun
        ).all()
        chigit = len([h for h in hujjatlar if h.mahsulot_id == 1])
        chiganoq = len([h for h in hujjatlar if h.mahsulot_id == 2])
        pochog = len([h for h in hujjatlar if h.mahsulot_id == 3])
        natija.append({
            "kun": str(kun),
            "chigit": chigit,
            "chiganoq": chiganoq,
            "pochog": pochog,
            "jami": len(hujjatlar)
        })
        kun = keyingi_kun
    return natija

@app.get("/statistika/grafik/mavsum")
def grafik_mavsum(db: Session = Depends(get_db)):
    from datetime import date, timedelta
    bugun = date.today()
    if bugun.month >= 8:
        mavsum_boshi = date(bugun.year, 8, 1)
    else:
        mavsum_boshi = date(bugun.year - 1, 8, 1)
    natija = []
    oy = mavsum_boshi
    while oy <= bugun:
        keyingi_oy = date(oy.year + (oy.month // 12), (oy.month % 12) + 1, 1)
        hujjatlar = db.query(Hujjat).filter(
            Hujjat.created_at >= oy,
            Hujjat.created_at < keyingi_oy
        ).all()
        chigit = len([h for h in hujjatlar if h.mahsulot_id == 1])
        chiganoq = len([h for h in hujjatlar if h.mahsulot_id == 2])
        pochog = len([h for h in hujjatlar if h.mahsulot_id == 3])
        natija.append({
            "oy": f"{oy.year}-{oy.month:02d}",
            "chigit": chigit,
            "chiganoq": chiganoq,
            "pochog": pochog,
            "jami": len(hujjatlar)
        })
        oy = keyingi_oy
    return natija