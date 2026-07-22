from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from database import engine, get_db, Base, SessionLocal
from models import User, Mahsulot, Mashina, Hujjat, Olchov, HujjatHolati, HujjatRaqamHisoblagich, TizimXatosi, TahrirTarixi
from schemas import UserLogin, Token, UserCreate, MashinaCreate, HujjatCreate, HujjatUpdate, OlchovCreate
from auth import verify_password, create_access_token, hash_password, get_current_user, require_role
from config import PG_DUMP_YOL, WKHTMLTOPDF_YOL, KAMERA_1_IP, KAMERA_2_IP, KAMERA_LOGIN, KAMERA_PAROL
import models
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
def mashina_qoshish(mashina: MashinaCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
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
def mashinalar_royxati(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(Mashina).all()

@app.get("/mashinalar/qidiruv/{raqam}")
def mashina_qidiruv(raqam: str, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(Mashina).filter(
        Mashina.davlat_raqami.ilike(f"%{raqam}%")
    ).all()

# ============ MAHSULOTLAR ============

@app.get("/mahsulotlar")
def mahsulotlar_royxati(db: Session = Depends(get_db)):
    # Login'dan OLDINGI mahsulot-tanlash ekrani shu endpointni tokensiz chaqiradi,
    # shuning uchun bu yerda autentifikatsiya talab qilinmaydi.
    return db.query(Mahsulot).filter(Mahsulot.is_active == True).all()

# ============ HUJJATLAR ============

def keyingi_hujjat_raqami(db: Session, yil: int) -> str:
    hisoblagich = db.query(HujjatRaqamHisoblagich).filter(
        HujjatRaqamHisoblagich.yil == yil
    ).with_for_update().first()

    if not hisoblagich:
        hisoblagich = HujjatRaqamHisoblagich(yil=yil, oxirgi_raqam=0)
        db.add(hisoblagich)
        db.flush()
        hisoblagich = db.query(HujjatRaqamHisoblagich).filter(
            HujjatRaqamHisoblagich.yil == yil
        ).with_for_update().first()

    hisoblagich.oxirgi_raqam += 1
    db.flush()
    return f"{yil}/{str(hisoblagich.oxirgi_raqam).zfill(3)}"

@app.post("/hujjatlar")
def hujjat_yaratish(hujjat: HujjatCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    yil = datetime.now().year
    yangi_raqam = keyingi_hujjat_raqami(db, yil)
    mashina = db.query(Mashina).filter(Mashina.id == hujjat.mashina_id).first()
    yangi = Hujjat(
        raqam=yangi_raqam,
        mashina_raqami=mashina.davlat_raqami if mashina else None,
        shofyor=mashina.shofyor if mashina else None,
        firma=mashina.firma if mashina else None,
        **hujjat.dict(),
    )
    db.add(yangi)
    db.commit()
    db.refresh(yangi)
    return yangi

@app.get("/hujjatlar")
def hujjatlar_royxati(
    mahsulot_id: int = None,
    bekor_qilinganlarni_korsat: bool = False,
    sana_dan: str = None,
    sana_gacha: str = None,
    sahifa: int = 1,
    sahifa_hajmi: int = 50,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    so_rov = db.query(Hujjat)
    if mahsulot_id:
        so_rov = so_rov.filter(Hujjat.mahsulot_id == mahsulot_id)
    if not bekor_qilinganlarni_korsat:
        so_rov = so_rov.filter(Hujjat.holat != HujjatHolati.BEKOR_QILINDI)
    if sana_dan:
        so_rov = so_rov.filter(Hujjat.created_at >= sana_dan)
    if sana_gacha:
        so_rov = so_rov.filter(Hujjat.created_at < sana_gacha)

    jami_soni = so_rov.count()

    hujjatlar = so_rov.order_by(Hujjat.id.desc()) \
        .offset((sahifa - 1) * sahifa_hajmi) \
        .limit(sahifa_hajmi) \
        .all()

    natija = []
    for h in hujjatlar:
        olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == h.id).all()
        jami_tara = sum(o.tara for o in olchovlar if o.tara) or None
        jami_brutto = sum(o.brutto for o in olchovlar if o.brutto) or None
        jami_netto = sum(o.netto for o in olchovlar if o.netto) or None
        jami_konditsion = sum(o.konditsion for o in olchovlar if o.konditsion) or None
        natija.append({
            "id": h.id,
            "raqam": h.raqam,
            "mashina_id": h.mashina_id,
            "mashina_raqami": h.mashina_raqami or "—",
            "shofyor": h.shofyor or "—",
            "firma": h.firma or "—",
            "mahsulot_id": h.mahsulot_id,
            "aravalar_soni": h.aravalar_soni,
            "tuda_raqam": h.tuda_raqam,
            "tiket_raqam": h.tiket_raqam,
            "klass": h.klass,
            "sinf": h.sinf,
            "seleksiya_navi": h.seleksiya_navi,
            "terim_turi": h.terim_turi,
            "qabul_qildi": h.qabul_qildi,
            "yuk_olindi": h.yuk_olindi,
            "holat": h.holat,
            "tara": jami_tara,
            "brutto": jami_brutto,
            "netto": jami_netto,
            "konditsion": jami_konditsion,
            "created_at": str(h.created_at) if h.created_at else None,
        })
    return {
        "natijalar": natija,
        "jami": jami_soni,
        "sahifa": sahifa,
        "sahifa_hajmi": sahifa_hajmi,
    }

@app.get("/hujjatlar/{hujjat_id}")
def hujjat_detail(hujjat_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    if not hujjat:
        raise HTTPException(status_code=404, detail="Hujjat topilmadi!")
    return hujjat

RUXSAT_ETILGAN_OTISHLAR = {
    HujjatHolati.JARAYON: {HujjatHolati.TUGALLANDI, HujjatHolati.BEKOR_QILINDI},
    HujjatHolati.TUGALLANDI: set(),
    HujjatHolati.BEKOR_QILINDI: set(),
}

def holat_otishi_ruxsatmi(eski: HujjatHolati, yangi: HujjatHolati) -> bool:
    if eski == yangi:
        return True
    return yangi in RUXSAT_ETILGAN_OTISHLAR.get(eski, set())

# hujjat_yangilash orqali tahrirlanishi mumkin bo'lgan va TahrirTarixi'ga
# yoziladigan barcha maydonlar (bekor_sabab bundan mustasno emas - u ham
# kuzatiladi, faqat maxsus talab qilinish qoidasi bekor_sabab_talab_qilinadi
# bilan alohida tekshiriladi).
AUDIT_MAYDONLAR = [
    'aravalar_soni', 'tuda_raqam', 'texnik_chiqit', 'sanoat_turi', 'klassifikatsiya',
    'davomlilik_raqam', 'davomlilik_dan', 'davomlilik_gacha', 'yuk_oluvchi', 'shartnoma',
    'mashina_raqami', 'shofyor', 'firma', 'tiket_raqam', 'klass', 'sinf',
    'seleksiya_navi', 'terim_turi', 'qabul_qildi', 'yuk_olindi',
    'holat', 'bekor_sabab',
]

def _qiymat_normal(qiymat):
    """None va bo'sh satrni bitta 'qiymat yo'q' holatiga tenglashtiradi,
    shunda frontend har doim to'liq forma yuborsa ham yolg'on o'zgarish
    aniqlanmaydi."""
    if qiymat is None:
        return None
    if isinstance(qiymat, str) and qiymat.strip() == "":
        return None
    return qiymat

def _qiymat_matn(qiymat):
    if qiymat is None:
        return None
    return qiymat.value if hasattr(qiymat, "value") else str(qiymat)

@app.put("/hujjatlar/{hujjat_id}")
def hujjat_yangilash(hujjat_id: int, data: HujjatUpdate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    if not hujjat:
        raise HTTPException(status_code=404, detail="Hujjat topilmadi!")
    if data.holat is not None and data.holat != hujjat.holat:
        if not holat_otishi_ruxsatmi(hujjat.holat, data.holat):
            raise HTTPException(
                status_code=400,
                detail=f"'{hujjat.holat.value}' holatidan '{data.holat.value}' holatiga o'tish mumkin emas!"
            )

    sabab_umumiy = (data.sabab or "").strip() or None
    sabab_bekor = (data.bekor_sabab or "").strip() or None

    if data.holat == HujjatHolati.BEKOR_QILINDI:
        if not sabab_bekor:
            raise HTTPException(
                status_code=400,
                detail="Hujjatni bekor qilish uchun sabab ko'rsatilishi shart!"
            )

    payload = data.dict(exclude_unset=True)

    # namlik/ifloslik Hujjatda emas, shu hujjatga tegishli barcha Olchov
    # qatorlarida - shuning uchun AUDIT_MAYDONLAR umumiy tsiklidan tashqarida,
    # alohida ishlanadi.
    olchovlar = None
    if "namlik" in payload or "ifloslik" in payload:
        olchovlar = db.query(Olchov).filter(Olchov.hujjat_id == hujjat_id).all()
        if not olchovlar:
            raise HTTPException(
                status_code=400,
                detail="Bu hujjatda hali birorta o'lchov (arava) yo'q, namlik/ifloslik saqlab bo'lmaydi!"
            )

    ozgarishlar = []
    for maydon in AUDIT_MAYDONLAR:
        if maydon not in payload:
            continue
        eski = getattr(hujjat, maydon)
        yangi = payload[maydon]
        if _qiymat_normal(eski) == _qiymat_normal(yangi):
            continue
        ozgarishlar.append((maydon, _qiymat_matn(eski), _qiymat_matn(yangi)))

    olchov_ozgargan_maydonlar = []
    for maydon in ("namlik", "ifloslik"):
        if maydon not in payload:
            continue
        yangi_qiymat = payload[maydon]
        agar_ozgargan = any(
            _qiymat_normal(getattr(o, maydon)) != _qiymat_normal(yangi_qiymat)
            for o in olchovlar
        )
        if not agar_ozgargan:
            continue
        eski_matn = ", ".join(_qiymat_matn(getattr(o, maydon)) or "—" for o in olchovlar)
        ozgarishlar.append((maydon, eski_matn, _qiymat_matn(yangi_qiymat)))
        olchov_ozgargan_maydonlar.append(maydon)

    if ozgarishlar and not (sabab_umumiy or sabab_bekor):
        raise HTTPException(
            status_code=400,
            detail="O'zgartirish sababi ko'rsatilishi shart!"
        )

    for key, value in payload.items():
        if key in ("sabab", "namlik", "ifloslik"):
            continue
        setattr(hujjat, key, value)

    if olchov_ozgargan_maydonlar:
        for maydon in olchov_ozgargan_maydonlar:
            yangi_qiymat = payload[maydon]
            for o in olchovlar:
                setattr(o, maydon, yangi_qiymat)
        for o in olchovlar:
            if o.netto and o.namlik and o.ifloslik:
                o.konditsion = konditsion_hisobla(o.netto, o.namlik, o.ifloslik)

    for maydon, eski_matn, yangi_matn in ozgarishlar:
        qator_sababi = (sabab_bekor or sabab_umumiy) if maydon in ("holat", "bekor_sabab") \
            else (sabab_umumiy or sabab_bekor)
        db.add(TahrirTarixi(
            hujjat_id=hujjat_id,
            maydon=maydon,
            eski_qiymat=eski_matn,
            yangi_qiymat=yangi_matn,
            sabab=qator_sababi,
            ozgartirgan_user_id=current_user.get("id"),
            ozgartirgan_username=current_user.get("sub"),
        ))

    db.commit()
    db.refresh(hujjat)
    return hujjat

# ============ TAHRIR TARIXI ============

def _tahrir_yozuv_dict(y: TahrirTarixi, hujjat_raqam: str = None):
    natija = {
        "id": y.id,
        "hujjat_id": y.hujjat_id,
        "maydon": y.maydon,
        "eski_qiymat": y.eski_qiymat,
        "yangi_qiymat": y.yangi_qiymat,
        "sabab": y.sabab,
        "ozgartirgan_user_id": y.ozgartirgan_user_id,
        "ozgartirgan_username": y.ozgartirgan_username,
        "vaqt": str(y.created_at) if y.created_at else None,
    }
    if hujjat_raqam is not None:
        natija["hujjat_raqam"] = hujjat_raqam
    return natija

@app.get("/tahrirlar-tarixi")
def barcha_tahrirlar_tarixi(limit: int = 100, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user.get("role") not in ("admin", "hisobchi"):
        raise HTTPException(status_code=403, detail="Bu amal uchun sizda ruxsat yo'q!")
    limit = min(max(limit, 1), 500)
    yozuvlar = db.query(TahrirTarixi, Hujjat.raqam).join(
        Hujjat, TahrirTarixi.hujjat_id == Hujjat.id
    ).order_by(TahrirTarixi.created_at.desc()).limit(limit).all()
    return [_tahrir_yozuv_dict(y, raqam) for y, raqam in yozuvlar]

@app.get("/tahrirlar-tarixi/{hujjat_id}")
def hujjat_tahrir_tarixi(hujjat_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user.get("role") not in ("admin", "hisobchi"):
        raise HTTPException(status_code=403, detail="Bu amal uchun sizda ruxsat yo'q!")
    hujjat = db.query(Hujjat).filter(Hujjat.id == hujjat_id).first()
    if not hujjat:
        raise HTTPException(status_code=404, detail="Hujjat topilmadi!")
    yozuvlar = db.query(TahrirTarixi).filter(
        TahrirTarixi.hujjat_id == hujjat_id
    ).order_by(TahrirTarixi.created_at.desc()).all()
    return [_tahrir_yozuv_dict(y) for y in yozuvlar]

# ============ OLCHOVLAR ============

KONDITSION_KOEFFITSENT = 89.5

def konditsion_hisobla(netto: float, namlik: float, ifloslik: float) -> float:
    return netto * (100 - (namlik + ifloslik)) / KONDITSION_KOEFFITSENT

@app.post("/olchovlar")
def olchov_saqlash(olchov: OlchovCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    yangi = Olchov(**olchov.dict())
    if yangi.brutto and yangi.tara:
        yangi.netto = yangi.brutto - yangi.tara
        if yangi.namlik and yangi.ifloslik:
            yangi.konditsion = konditsion_hisobla(yangi.netto, yangi.namlik, yangi.ifloslik)
    db.add(yangi)
    db.commit()
    db.refresh(yangi)
    if yangi.brutto and yangi.tara:
        print(f"Excel ga yozilmoqda: hujjat_id={yangi.hujjat_id}")
        excel_qatorga_yoz(yangi.hujjat_id, db)
    return yangi

@app.get("/olchovlar/{hujjat_id}")
def olchovlar_royxati(hujjat_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(Olchov).filter(Olchov.hujjat_id == hujjat_id).all()

# ============ NAVBAT (PostgreSQL) ============
import json

@app.post("/navbat/qosh")
def navbat_qosh(data: dict, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
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
def navbat_get(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
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
def navbat_tugallandi(data: dict, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from models import Navbat
    navbat = db.query(Navbat).filter(Navbat.hujjat_id == data.get("hujjatId")).first()
    if navbat:
        navbat.tugallandi = True
        navbat.tugallangan_vaqt = datetime.now()
        navbat.aravalar_json = json.dumps(data.get("aravalar", {}))
        db.commit()
    return {"status": "ok"}

@app.get("/navbat/tugallanganlar")
def tugallanganlar_get(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
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
def navbat_bekor(data: dict, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from models import Navbat
    navbat = db.query(Navbat).filter(Navbat.hujjat_id == data.get("hujjatId")).first()
    if navbat:
        db.delete(navbat)
        db.commit()
    return {"status": "ok"}

@app.delete("/navbat/tozala")
def navbat_tozala(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from models import Navbat
    db.query(Navbat).delete()
    db.commit()
    return {"status": "ok"}

# ============ STATISTIKA ============

@app.get("/statistika/kunlik")
def kunlik_statistika(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date
    bugun = date.today()

    mashinalar_soni = db.query(Hujjat).filter(Hujjat.created_at >= bugun).count()

    from models import Navbat as NavbatModel
    navbat_soni = db.query(NavbatModel).filter(NavbatModel.tugallandi == False).count()
    tugallangan_soni = db.query(NavbatModel).filter(NavbatModel.tugallandi == True).count()

    natijalar = db.query(
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
    ).outerjoin(
        Olchov, Olchov.hujjat_id == Hujjat.id
    ).filter(
        Hujjat.created_at >= bugun
    ).group_by(Hujjat.mahsulot_id).all()

    natija = {}
    for row in natijalar:
        natija[row.mahsulot_id] = {
            "soni": row.soni,
            "tonnaj": round(row.jami_netto / 1000, 2),
            "konditsion": round(row.jami_konditsion / 1000, 2),
        }
    jami_tonnaj = round(sum(row.jami_netto for row in natijalar) / 1000, 2)

    bosh = {"soni": 0, "tonnaj": 0.0, "konditsion": 0.0}

    return {
        "sana": str(bugun),
        "mashinalar_soni": mashinalar_soni,
        "tugallanganlar_soni": tugallangan_soni,
        "navbat_soni": navbat_soni,
        "chigit": natija.get(1, bosh),
        "chiganoq": {"soni": natija.get(2, bosh)["soni"], "tonnaj": natija.get(2, bosh)["tonnaj"]},
        "pochog": {"soni": natija.get(3, bosh)["soni"], "tonnaj": natija.get(3, bosh)["tonnaj"]},
        "patoz": {"soni": natija.get(4, bosh)["soni"], "tonnaj": natija.get(4, bosh)["tonnaj"]},
        "jami_tonnaj": jami_tonnaj,
    }

@app.get("/statistika/haftalik")
def haftalik_statistika(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date, timedelta
    bugun = date.today()
    hafta_boshi = bugun - timedelta(days=7)

    mashinalar_soni = db.query(Hujjat).filter(Hujjat.created_at >= hafta_boshi).count()

    natijalar = db.query(
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
    ).outerjoin(
        Olchov, Olchov.hujjat_id == Hujjat.id
    ).filter(
        Hujjat.created_at >= hafta_boshi
    ).group_by(Hujjat.mahsulot_id).all()

    natija = {}
    for row in natijalar:
        natija[row.mahsulot_id] = {
            "soni": row.soni,
            "tonnaj": round(row.jami_netto / 1000, 2),
        }
    jami_tonnaj = round(sum(row.jami_netto for row in natijalar) / 1000, 2)

    bosh = {"soni": 0, "tonnaj": 0.0}

    return {
        "dan": str(hafta_boshi),
        "gacha": str(bugun),
        "mashinalar_soni": mashinalar_soni,
        "chigit": natija.get(1, bosh),
        "chiganoq": natija.get(2, bosh),
        "pochog": natija.get(3, bosh),
        "jami_tonnaj": jami_tonnaj,
    }

@app.get("/statistika/oylik")
def oylik_statistika(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date, timedelta
    bugun = date.today()
    oy_boshi = bugun.replace(day=1)

    mashinalar_soni = db.query(Hujjat).filter(Hujjat.created_at >= oy_boshi).count()

    natijalar = db.query(
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
    ).outerjoin(
        Olchov, Olchov.hujjat_id == Hujjat.id
    ).filter(
        Hujjat.created_at >= oy_boshi
    ).group_by(Hujjat.mahsulot_id).all()

    natija = {}
    for row in natijalar:
        natija[row.mahsulot_id] = {
            "soni": row.soni,
            "tonnaj": round(row.jami_netto / 1000, 2),
            "konditsion": round(row.jami_konditsion / 1000, 2),
        }
    jami_tonnaj = round(sum(row.jami_netto for row in natijalar) / 1000, 2)

    bosh = {"soni": 0, "tonnaj": 0.0, "konditsion": 0.0}

    return {
        "oy": str(oy_boshi),
        "mashinalar_soni": mashinalar_soni,
        "chigit": natija.get(1, bosh),
        "chiganoq": {"soni": natija.get(2, bosh)["soni"], "tonnaj": natija.get(2, bosh)["tonnaj"]},
        "pochog": {"soni": natija.get(3, bosh)["soni"], "tonnaj": natija.get(3, bosh)["tonnaj"]},
        "patoz": {"soni": natija.get(4, bosh)["soni"], "tonnaj": natija.get(4, bosh)["tonnaj"]},
        "jami_tonnaj": jami_tonnaj,
    }

@app.get("/statistika/mavsum")
def mavsum_statistika(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date
    bugun = date.today()
    # Mavsum: 1 Avgust dan 31 Iyul gacha
    if bugun.month >= 8:
        mavsum_boshi = date(bugun.year, 8, 1)
    else:
        mavsum_boshi = date(bugun.year - 1, 8, 1)

    mashinalar_soni = db.query(Hujjat).filter(Hujjat.created_at >= mavsum_boshi).count()

    natijalar = db.query(
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
    ).outerjoin(
        Olchov, Olchov.hujjat_id == Hujjat.id
    ).filter(
        Hujjat.created_at >= mavsum_boshi
    ).group_by(Hujjat.mahsulot_id).all()

    natija = {}
    for row in natijalar:
        natija[row.mahsulot_id] = {
            "soni": row.soni,
            "tonnaj": round(row.jami_netto / 1000, 2),
            "konditsion": round(row.jami_konditsion / 1000, 2),
        }
    jami_tonnaj = round(sum(row.jami_netto for row in natijalar) / 1000, 2)

    bosh = {"soni": 0, "tonnaj": 0.0, "konditsion": 0.0}

    return {
        "mavsum_boshi": str(mavsum_boshi),
        "mashinalar_soni": mashinalar_soni,
        "chigit": natija.get(1, bosh),
        "chiganoq": {"soni": natija.get(2, bosh)["soni"], "tonnaj": natija.get(2, bosh)["tonnaj"]},
        "pochog": {"soni": natija.get(3, bosh)["soni"], "tonnaj": natija.get(3, bosh)["tonnaj"]},
        "patoz": {"soni": natija.get(4, bosh)["soni"], "tonnaj": natija.get(4, bosh)["tonnaj"]},
        "jami_tonnaj": jami_tonnaj,
    }

    # ============ BACKUP ============

import os
import shutil
from datetime import datetime

@app.post("/backup")
def backup_qilish(current_user: dict = Depends(require_role("admin"))):
    try:
        backup_dir = r"C:\hazorasp_tarozi\backup"
        os.makedirs(backup_dir, exist_ok=True)
        
        sana = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        backup_fayl = os.path.join(backup_dir, f"backup_{sana}.sql")

        pg_dump = PG_DUMP_YOL

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
def backup_royxat(current_user: dict = Depends(require_role("admin"))):
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

TELEGRAM_SOZLAMA_KALIT = "oxirgi_telegram_hisobot_sanasi"

def avtomatik_telegram_hisobot():
    import time
    from datetime import date, timedelta
    from models import Sozlama
    while True:
        now = datetime.now()
        if (now.hour, now.minute) >= (8, 30):
            db = SessionLocal()
            try:
                bugun = date.today()
                kecha = bugun - timedelta(days=1)
                sozlama = db.query(Sozlama).filter(
                    Sozlama.kalit == TELEGRAM_SOZLAMA_KALIT).first()
                bugun_yuborilgan = sozlama is not None and sozlama.qiymat == str(bugun)
                if not bugun_yuborilgan:
                    mashinalar_soni = db.query(Hujjat).filter(
                        Hujjat.created_at >= kecha, Hujjat.created_at < bugun).count()

                    if kecha.month >= 8:
                        mavsum_boshi = datetime(kecha.year, 8, 1)
                    else:
                        mavsum_boshi = datetime(kecha.year - 1, 8, 1)

                    bosh3 = (0, 0.0, 0.0)

                    bugun_natijalar = db.query(
                        Hujjat.mahsulot_id,
                        func.count(func.distinct(Hujjat.id)).label('soni'),
                        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
                        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
                    ).outerjoin(Olchov, Olchov.hujjat_id == Hujjat.id).filter(
                        Hujjat.created_at >= kecha, Hujjat.created_at < bugun
                    ).group_by(Hujjat.mahsulot_id).all()
                    yb = {r.mahsulot_id: (r.soni, round(r.jami_netto/1000, 2), round(r.jami_konditsion/1000, 2)) for r in bugun_natijalar}
                    chigit_son, chigit_netto, chigit_kond = yb.get(1, bosh3)
                    chiganoq_son, chiganoq_netto, _ = yb.get(2, bosh3)
                    pochog_son, pochog_netto, _ = yb.get(3, bosh3)
                    patoz_son, patoz_netto, _ = yb.get(4, bosh3)

                    mavsum_natijalar = db.query(
                        Hujjat.mahsulot_id,
                        func.count(func.distinct(Hujjat.id)).label('soni'),
                        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
                        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
                    ).outerjoin(Olchov, Olchov.hujjat_id == Hujjat.id).filter(
                        Hujjat.created_at >= mavsum_boshi, Hujjat.created_at < bugun
                    ).group_by(Hujjat.mahsulot_id).all()
                    ym = {r.mahsulot_id: (r.soni, round(r.jami_netto/1000, 2), round(r.jami_konditsion/1000, 2)) for r in mavsum_natijalar}
                    mchigit_son, mchigit_netto, mchigit_kond = ym.get(1, bosh3)
                    mchiganoq_son, mchiganoq_netto, _ = ym.get(2, bosh3)
                    mpochog_son, mpochog_netto, _ = ym.get(3, bosh3)
                    mpatoz_son, mpatoz_netto, _ = ym.get(4, bosh3)

                    matn = f"""📊 <b>KUNLIK HISOBOT</b>
📅 Sana: {kecha}

🚛 Jami: <b>{mashinalar_soni} ta</b>

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
                    muvaffaqiyatli = telegram_xabar_yuborish(matn)
                    if muvaffaqiyatli:
                        if sozlama:
                            sozlama.qiymat = str(bugun)
                            sozlama.updated_at = datetime.now()
                        else:
                            db.add(Sozlama(kalit=TELEGRAM_SOZLAMA_KALIT, qiymat=str(bugun)))
                        db.commit()
                        print(f"Avtomatik hisobot yuborildi (kechagi kun: {kecha})")
                    else:
                        print("Hisobot yuborilmadi, keyingi urinishda qayta sinaladi")
            except Exception as e:
                print(f"Hisobot xato: {e}")
                tizim_xatosini_saqla("telegram_hisobot", str(e))
            finally:
                db.close()
        time.sleep(30)


BACKUP_SOZLAMA_KALIT = "oxirgi_backup_sanasi"

def avtomatik_backup():
    import time
    import subprocess
    from datetime import date
    from models import Sozlama
    while True:
        db = SessionLocal()
        try:
            bugun = date.today()
            sozlama = db.query(Sozlama).filter(
                Sozlama.kalit == BACKUP_SOZLAMA_KALIT).first()
            bugun_bajarilgan = sozlama is not None and sozlama.qiymat == str(bugun)
            if not bugun_bajarilgan:
                backup_dir = r"C:\hazorasp_tarozi\backup"
                os.makedirs(backup_dir, exist_ok=True)
                sana = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
                backup_fayl = os.path.join(backup_dir, f"backup_{sana}.sql")
                pg_dump = PG_DUMP_YOL
                natija = subprocess.run(
                    [pg_dump, "-U", "postgres", "-p", "5433", "-d", "hazorasp_tarozi", "-f", backup_fayl],
                    env={**os.environ, "PGPASSWORD": "Xorazm2026"}
                )
                if natija.returncode == 0:
                    if sozlama:
                        sozlama.qiymat = str(bugun)
                        sozlama.updated_at = datetime.now()
                    else:
                        db.add(Sozlama(kalit=BACKUP_SOZLAMA_KALIT, qiymat=str(bugun)))
                    db.commit()
                    print(f"Avtomatik backup: {backup_fayl}")
                else:
                    xato = f"pg_dump xato kod bilan tugadi: {natija.returncode}"
                    print(f"Backup xato: {xato}")
                    tizim_xatosini_saqla("backup", xato)
        except Exception as e:
            print(f"Backup xato: {e}")
            tizim_xatosini_saqla("backup", str(e))
        finally:
            db.close()
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
        print(f"Excel ga yozildi: {hujjat.raqam} ({mahsulot_nomi})")
    except Exception as e:
        print(f"Excel xato: {e}")
# ============ SOZLAMALAR ============
from models import Sozlama

@app.get("/sozlamalar")
def sozlamalar_olish(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    sozlamalar = db.query(Sozlama).all()
    natija = {}
    for s in sozlamalar:
        natija[s.kalit] = s.qiymat
    return natija

@app.post("/sozlamalar")
def sozlama_saqlash(data: dict, db: Session = Depends(get_db), current_user: dict = Depends(require_role("admin"))):
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

# ============ TIZIM XATOLARI RO'YXATI ============

@app.get("/tizim-xatolari")
def tizim_xatolari_royxati(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user.get("role") not in ("admin", "hisobchi"):
        raise HTTPException(status_code=403, detail="Bu amal uchun sizda ruxsat yo'q!")
    xatolar = db.query(TizimXatosi).order_by(
        TizimXatosi.created_at.desc()
    ).limit(50).all()
    return [
        {
            "id": x.id,
            "turi": x.turi,
            "xabar": x.xabar,
            "korilgan": x.korilgan,
            "vaqt": str(x.created_at),
        }
        for x in xatolar
    ]

@app.post("/tizim-xatolari/{xato_id}/korildi")
def tizim_xatosi_korildi(xato_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user.get("role") not in ("admin", "hisobchi"):
        raise HTTPException(status_code=403, detail="Bu amal uchun sizda ruxsat yo'q!")
    xato = db.query(TizimXatosi).filter(TizimXatosi.id == xato_id).first()
    if xato:
        xato.korilgan = True
        db.commit()
    return {"status": "ok"}

# ============ SERVER HOLATI ============
import psutil

@app.get("/server/holat")
def server_holat(current_user: dict = Depends(get_current_user)):
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

# ============ TIZIM XATOLARI ============

def tizim_xatosini_saqla(turi: str, xabar: str):
    db = SessionLocal()
    try:
        yangi = TizimXatosi(turi=turi, xabar=xabar)
        db.add(yangi)
        db.commit()
    except Exception as e:
        print(f"Tizim xatosini saqlashda xato: {e}")
    finally:
        db.close()

# ============ TELEGRAM BOT ============
import requests as req

def telegram_xabar_yuborish(matn: str) -> bool:
    try:
        from config import TELEGRAM_TOKEN, TELEGRAM_CHAT_ID
        if not TELEGRAM_TOKEN or not TELEGRAM_CHAT_ID:
            return False
        url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        javob = req.post(url, json={
            "chat_id": TELEGRAM_CHAT_ID,
            "text": matn,
            "parse_mode": "HTML"
        })
        javob.raise_for_status()
        return True
    except Exception as e:
        print(f"Telegram xato: {e}")
        tizim_xatosini_saqla("telegram", str(e))
        return False

hisobot_thread = threading.Thread(target=avtomatik_telegram_hisobot, daemon=True)
hisobot_thread.start()

@app.post("/telegram/test")
def telegram_test(current_user: dict = Depends(get_current_user)):
    telegram_xabar_yuborish("✅ Hazorasp Tekstil tarozi tizimi ulandi!")
    return {"status": "ok"}

@app.get("/telegram/kunlik")
def telegram_kunlik(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date
    bugun = date.today()
    mashinalar_soni = db.query(Hujjat).filter(Hujjat.created_at >= bugun).count()

    if bugun.month >= 8:
        mavsum_boshi = datetime(bugun.year, 8, 1)
    else:
        mavsum_boshi = datetime(bugun.year - 1, 8, 1)

    bosh3 = (0, 0.0, 0.0)

    bugun_natijalar = db.query(
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
    ).outerjoin(Olchov, Olchov.hujjat_id == Hujjat.id).filter(
        Hujjat.created_at >= bugun
    ).group_by(Hujjat.mahsulot_id).all()
    yb = {r.mahsulot_id: (r.soni, round(r.jami_netto/1000, 2), round(r.jami_konditsion/1000, 2)) for r in bugun_natijalar}
    chigit_son, chigit_netto, chigit_kond = yb.get(1, bosh3)
    chiganoq_son, chiganoq_netto, _ = yb.get(2, bosh3)
    pochog_son, pochog_netto, _ = yb.get(3, bosh3)
    patoz_son, patoz_netto, _ = yb.get(4, bosh3)

    mavsum_natijalar = db.query(
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
        func.coalesce(func.sum(Olchov.netto), 0).label('jami_netto'),
        func.coalesce(func.sum(Olchov.konditsion), 0).label('jami_konditsion'),
    ).outerjoin(Olchov, Olchov.hujjat_id == Hujjat.id).filter(
        Hujjat.created_at >= mavsum_boshi
    ).group_by(Hujjat.mahsulot_id).all()
    ym = {r.mahsulot_id: (r.soni, round(r.jami_netto/1000, 2), round(r.jami_konditsion/1000, 2)) for r in mavsum_natijalar}
    mchigit_son, mchigit_netto, mchigit_kond = ym.get(1, bosh3)
    mchiganoq_son, mchiganoq_netto, _ = ym.get(2, bosh3)
    mpochog_son, mpochog_netto, _ = ym.get(3, bosh3)
    mpatoz_son, mpatoz_netto, _ = ym.get(4, bosh3)

    matn = f"""📊 <b>KUNLIK HISOBOT</b>
📅 Sana: {bugun}

🚛 Jami: <b>{mashinalar_soni} ta</b>

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
async def nakladnoy_saqlash(request: Request, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
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
        wkhtmltopdf_yol = WKHTMLTOPDF_YOL
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
            xabar = f"Kamera {cam_ip} javob bermadi"
            tizim_xatosini_saqla("kamera", xabar)
            return {"status": "error", "message": xabar}
    except Exception as e:
        tizim_xatosini_saqla("kamera", str(e))
        return {"status": "error", "message": str(e)}

@app.post("/kamera/rasm")
def rasm_ol(data: dict, current_user: dict = Depends(get_current_user)):
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
            future1 = executor.submit(bir_kameradan_rasm_ol, KAMERA_1_IP, fayl1)
            future2 = executor.submit(bir_kameradan_rasm_ol, KAMERA_2_IP, fayl2)
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
def grafik_kunlik(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date, timedelta
    kun_boshi = date.today() - timedelta(days=6)
    oxirgi_kun = date.today() + timedelta(days=1)

    qatorlar = db.query(
        cast(Hujjat.created_at, Date).label('kun'),
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
    ).filter(
        Hujjat.created_at >= kun_boshi,
        Hujjat.created_at < oxirgi_kun
    ).group_by(cast(Hujjat.created_at, Date), Hujjat.mahsulot_id).all()

    mahsulot_dict = {}
    jami_dict = {}
    for row in qatorlar:
        kun_str = str(row.kun)
        mahsulot_dict[(kun_str, row.mahsulot_id)] = row.soni
        jami_dict[kun_str] = jami_dict.get(kun_str, 0) + row.soni

    natija = []
    for i in range(6, -1, -1):
        kun = date.today() - timedelta(days=i)
        kun_str = str(kun)
        natija.append({
            "kun": kun_str,
            "chigit": mahsulot_dict.get((kun_str, 1), 0),
            "chiganoq": mahsulot_dict.get((kun_str, 2), 0),
            "pochog": mahsulot_dict.get((kun_str, 3), 0),
            "jami": jami_dict.get(kun_str, 0),
        })
    return natija

@app.get("/statistika/grafik/haftalik")
def grafik_haftalik(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date, timedelta
    bugun = date.today()
    joriy_hafta_boshi = bugun - timedelta(days=bugun.weekday())
    hafta_boshi_8 = joriy_hafta_boshi - timedelta(weeks=7)
    oxirgi_chegara = bugun + timedelta(days=1)

    qatorlar = db.query(
        func.date_trunc('week', Hujjat.created_at).label('hafta'),
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
    ).filter(
        Hujjat.created_at >= hafta_boshi_8,
        Hujjat.created_at < oxirgi_chegara
    ).group_by(func.date_trunc('week', Hujjat.created_at), Hujjat.mahsulot_id).all()

    mahsulot_dict = {}
    jami_dict = {}
    for row in qatorlar:
        hafta_str = str(row.hafta.date())
        mahsulot_dict[(hafta_str, row.mahsulot_id)] = row.soni
        jami_dict[hafta_str] = jami_dict.get(hafta_str, 0) + row.soni

    natija = []
    for i in range(7, -1, -1):
        hafta = joriy_hafta_boshi - timedelta(weeks=i)
        hafta_str = str(hafta)
        natija.append({
            "hafta_boshi": hafta_str,
            "chigit": mahsulot_dict.get((hafta_str, 1), 0),
            "chiganoq": mahsulot_dict.get((hafta_str, 2), 0),
            "pochog": mahsulot_dict.get((hafta_str, 3), 0),
            "jami": jami_dict.get(hafta_str, 0),
        })
    return natija

@app.get("/statistika/grafik/oylik")
def grafik_oylik(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date, timedelta
    bugun = date.today()
    oy_boshi = bugun.replace(day=1)
    oxirgi_kun = bugun + timedelta(days=1)

    qatorlar = db.query(
        cast(Hujjat.created_at, Date).label('kun'),
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
    ).filter(
        Hujjat.created_at >= oy_boshi,
        Hujjat.created_at < oxirgi_kun
    ).group_by(cast(Hujjat.created_at, Date), Hujjat.mahsulot_id).all()

    mahsulot_dict = {}
    jami_dict = {}
    for row in qatorlar:
        kun_str = str(row.kun)
        mahsulot_dict[(kun_str, row.mahsulot_id)] = row.soni
        jami_dict[kun_str] = jami_dict.get(kun_str, 0) + row.soni

    natija = []
    kun = oy_boshi
    while kun <= bugun:
        kun_str = str(kun)
        natija.append({
            "kun": kun_str,
            "chigit": mahsulot_dict.get((kun_str, 1), 0),
            "chiganoq": mahsulot_dict.get((kun_str, 2), 0),
            "pochog": mahsulot_dict.get((kun_str, 3), 0),
            "jami": jami_dict.get(kun_str, 0),
        })
        kun = kun + timedelta(days=1)
    return natija

@app.get("/statistika/grafik/mavsum")
def grafik_mavsum(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    from datetime import date, timedelta
    bugun = date.today()
    if bugun.month >= 8:
        mavsum_boshi = date(bugun.year, 8, 1)
    else:
        mavsum_boshi = date(bugun.year - 1, 8, 1)
    oxirgi_oy = date(bugun.year + (bugun.month // 12), (bugun.month % 12) + 1, 1)

    qatorlar = db.query(
        func.date_trunc('month', Hujjat.created_at).label('oy'),
        Hujjat.mahsulot_id,
        func.count(func.distinct(Hujjat.id)).label('soni'),
    ).filter(
        Hujjat.created_at >= mavsum_boshi,
        Hujjat.created_at < oxirgi_oy
    ).group_by(func.date_trunc('month', Hujjat.created_at), Hujjat.mahsulot_id).all()

    mahsulot_dict = {}
    jami_dict = {}
    for row in qatorlar:
        oy_str = row.oy.strftime("%Y-%m")
        mahsulot_dict[(oy_str, row.mahsulot_id)] = row.soni
        jami_dict[oy_str] = jami_dict.get(oy_str, 0) + row.soni

    natija = []
    oy = mavsum_boshi
    while oy <= bugun:
        oy_str = f"{oy.year}-{oy.month:02d}"
        natija.append({
            "oy": oy_str,
            "chigit": mahsulot_dict.get((oy_str, 1), 0),
            "chiganoq": mahsulot_dict.get((oy_str, 2), 0),
            "pochog": mahsulot_dict.get((oy_str, 3), 0),
            "jami": jami_dict.get(oy_str, 0),
        })
        oy = date(oy.year + (oy.month // 12), (oy.month % 12) + 1, 1)
    return natija