"""avtomatik_telegram_hisobot() tuzatishlari:

1. _kunlik_hisobot_matni() endi FAQAT holat='tugallandi' + netto>0 qatorlarni
   sanaydi (avval faqat GET /telegram/kunlik endpointiga qo'shilgan edi,
   avtomatik 08:30 hisobotiga qo'shilmagan edi).
2. telegram_hisobot_yuborish() timeout=15 (avval 5); commit xatosidan keyin
   db.rollback().
3. Mavsum boshi oy/kuni `sozlamalar` jadvalidan (mavsum_boshi_oy /
   mavsum_boshi_kun), yo'q bo'lsa standart 1-Avgust.
4. Avtomatik hisobot faqat 08:30-08:34 oralig'ida yuboriladi (avval butun
   kun >= 08:30 edi -> tarmoq muammosida takroriy hisobot).
"""
from datetime import date, datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest

import main
from models import Sozlama, Mahsulot, Hujjat, Olchov, HujjatHolati


# ---------- 4-band: yuborish vaqti oynasi ----------

def test_hisobot_yuborish_vaqti_faqat_8_30_8_35_oraligida():
    v = main._hisobot_yuborish_vaqtimi
    assert v(datetime(2026, 9, 7, 8, 29)) is False
    assert v(datetime(2026, 9, 7, 8, 30)) is True
    assert v(datetime(2026, 9, 7, 8, 32)) is True
    assert v(datetime(2026, 9, 7, 8, 34)) is True
    assert v(datetime(2026, 9, 7, 8, 35)) is False
    assert v(datetime(2026, 9, 7, 12, 0)) is False   # avval bu True edi
    assert v(datetime(2026, 9, 7, 23, 59)) is False  # avval bu True edi
    assert v(datetime(2026, 9, 7, 0, 5)) is False


# ---------- 2-band: hisobot boti timeout=15 ----------

def test_hisobot_boti_timeout_15():
    javob = MagicMock()
    javob.raise_for_status.return_value = None
    with patch("main.req.post", return_value=javob) as mock_post, \
         patch("config.TELEGRAM_HISOBOT_TOKEN", "t"), \
         patch("config.TELEGRAM_HISOBOT_CHAT_ID", "c"):
        assert main.telegram_hisobot_yuborish("x") is True
    assert mock_post.call_args.kwargs["timeout"] == 15


# ---------- 3-band: mavsum boshi sozlanadigan ----------

def test_mavsum_boshi_sozlama_yoq_bolsa_1_avgust(db_session):
    b = main._mavsum_boshi_sanasi
    assert b(date(2026, 9, 7), db_session) == date(2026, 8, 1)
    assert b(date(2026, 8, 1), db_session) == date(2026, 8, 1)
    assert b(date(2026, 7, 31), db_session) == date(2025, 8, 1)  # mavsumdan oldin


def test_mavsum_boshi_sozlamadan_oqiladi(db_session):
    db_session.add(Sozlama(kalit="mavsum_boshi_oy", qiymat="9"))
    db_session.add(Sozlama(kalit="mavsum_boshi_kun", qiymat="15"))
    db_session.commit()
    b = main._mavsum_boshi_sanasi
    assert b(date(2026, 9, 20), db_session) == date(2026, 9, 15)
    assert b(date(2026, 9, 15), db_session) == date(2026, 9, 15)
    assert b(date(2026, 9, 10), db_session) == date(2025, 9, 15)  # 09-15 dan oldin


def test_mavsum_boshi_yaroqsiz_sozlama_defaultga_qaytadi(db_session):
    db_session.add(Sozlama(kalit="mavsum_boshi_oy", qiymat="abc"))
    db_session.add(Sozlama(kalit="mavsum_boshi_kun", qiymat="99"))
    db_session.commit()
    assert main._mavsum_boshi_sanasi(date(2026, 9, 7), db_session) == date(2026, 8, 1)


def test_mavsum_statistika_sozlamaga_amal_qiladi(client, admin_headers, db_session):
    db_session.add(Sozlama(kalit="mavsum_boshi_oy", qiymat="9"))
    db_session.add(Sozlama(kalit="mavsum_boshi_kun", qiymat="1"))
    db_session.commit()
    j = client.get("/statistika/mavsum", headers=admin_headers).json()
    assert j["mavsum_boshi"] == str(date(date.today().year, 9, 1)
                                    if (date.today().month, date.today().day) >= (9, 1)
                                    else date(date.today().year - 1, 9, 1))


# ---------- 1-band: avtomatik hisobot filtri ----------

def _hj(db, mahsulot_id, holat, netto, raqam, vaqt):
    h = Hujjat(mahsulot_id=mahsulot_id, raqam=raqam, holat=holat, created_at=vaqt)
    db.add(h)
    db.flush()
    db.add(Olchov(hujjat_id=h.id, arava_raqam=1, tara=1000,
                  brutto=1000 + (netto or 0), netto=netto))
    db.commit()
    return h.id


def test_kunlik_hisobot_matni_faqat_tugallandi_va_netto(db_session):
    db_session.add(Mahsulot(id=1, nom="Chigit", konditsiya_bor=True, is_active=True))
    db_session.commit()
    bugun = date.today()
    kecha = bugun - timedelta(days=1)
    kv = datetime.combine(kecha, datetime.min.time()) + timedelta(hours=10)

    _hj(db_session, 1, HujjatHolati.TUGALLANDI, 5000, "T1", kv)   # sanaladi -> 5.0 t
    _hj(db_session, 1, HujjatHolati.JARAYON, 9000, "J1", kv)      # jarayon -> yo'q
    _hj(db_session, 1, HujjatHolati.TUGALLANDI, 0, "Z1", kv)      # netto=0 -> yo'q

    matn = main._kunlik_hisobot_matni(db_session, kecha, bugun)

    assert "Netto: <b>5.0 t</b>" in matn        # faqat T1
    assert "9.0 t" not in matn                  # jarayondagi kirmadi
    assert "14.0 t" not in matn                 # ikkalasi qo'shilib ketmadi
    assert f"Sana: {kecha}" in matn
    # mashinalar_soni endpoint kabi HAMMASINI sanaydi
    assert "Jami: <b>3 ta</b>" in matn


# ---------- 2-band: idempotentlik + commit rollback ----------

def test_avtomatik_hisobot_bir_urinish_kuniga_bir_marta(db_session):
    with patch("main.telegram_hisobot_yuborish", return_value=True) as mock_send:
        r1 = main._avtomatik_hisobot_bir_urinish(db_session)
        r2 = main._avtomatik_hisobot_bir_urinish(db_session)
    assert r1 is True
    assert r2 is False                       # guard: bugun allaqachon yuborilgan
    assert mock_send.call_count == 1


def test_avtomatik_hisobot_commit_xatosida_rollback_qilinadi(db_session):
    haqiqiy_rollback = db_session.rollback
    with patch("main.telegram_hisobot_yuborish", return_value=True), \
         patch.object(db_session, "commit", side_effect=RuntimeError("commit yiqildi")), \
         patch.object(db_session, "rollback", wraps=haqiqiy_rollback) as spy_rollback:
        with pytest.raises(RuntimeError):
            main._avtomatik_hisobot_bir_urinish(db_session)
    spy_rollback.assert_called()   # buzuq tranzaksiya tozalandi


def test_avtomatik_hisobot_yuborilmasa_guard_saqlanmaydi(db_session):
    with patch("main.telegram_hisobot_yuborish", return_value=False):
        r = main._avtomatik_hisobot_bir_urinish(db_session)
    assert r is False
    qoldi = db_session.query(Sozlama).filter(
        Sozlama.kalit == main.TELEGRAM_SOZLAMA_KALIT).first()
    assert qoldi is None   # keyingi urinishda qayta sinaladi
