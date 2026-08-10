"""GET /nakladnoy-korish/{token} - LOGIN TALAB QILMAYDIGAN ochiq sahifa.

Regressiya: bazadagi (operator kiritgan) matn maydonlari (shofyor, firma
va h.k.) avval XOM holda HTML'ga qo'yilardi - agar ulardan biri
<script>...</script> kabi matn bo'lsa, hech qanday autentifikatsiyasiz
ochiladigan shu sahifada bajarilishi mumkin edi (XSS). Endi barchasi
html.escape() orqali chiqariladi - qarang: main.py, nakladnoy_korish()."""
import secrets


def _hujjat_yarat(db_session, mashina, mahsulot_chigit, **override):
    from models import Hujjat, HujjatHolati
    qiymatlar = dict(
        raqam=f"TEST-{secrets.token_hex(4)}",
        mashina_id=mashina.id,
        mahsulot_id=mahsulot_chigit.id,
        holat=HujjatHolati.TUGALLANDI,
        nakladnoy_token=secrets.token_urlsafe(24),
        shofyor="Oddiy Shofyor",
        firma="Oddiy Firma",
    )
    qiymatlar.update(override)
    hujjat = Hujjat(**qiymatlar)
    db_session.add(hujjat)
    db_session.commit()
    db_session.refresh(hujjat)
    return hujjat


def test_zararli_skript_html_sifatida_bajarilmaydi_balki_matn_sifatida_korinadi(
        client, db_session, mashina, mahsulot_chigit):
    zararli_matn = "<script>alert(1)</script>"
    hujjat = _hujjat_yarat(
        db_session, mashina, mahsulot_chigit,
        shofyor=zararli_matn, firma=zararli_matn,
    )

    javob = client.get(f"/nakladnoy-korish/{hujjat.nakladnoy_token}")

    assert javob.status_code == 200
    # Asosiy tekshiruv: XOM <script> tegi javob tanasida UMUMAN
    # bo'lmasligi kerak - aks holda brauzer buni bajarardi.
    assert "<script>alert(1)</script>" not in javob.text
    # Escape qilingan shakli esa matn sifatida ko'rinishi kerak.
    assert "&lt;script&gt;alert(1)&lt;/script&gt;" in javob.text


def test_login_talab_qilinmaydi(client, db_session, mashina, mahsulot_chigit):
    """Sahifa ATAYLAB autentifikatsiyasiz ochilishi kerak (QR kod orqali) -
    bu autentifikatsiya sarlavhasi yubormasdan sinaladi."""
    hujjat = _hujjat_yarat(db_session, mashina, mahsulot_chigit)

    javob = client.get(f"/nakladnoy-korish/{hujjat.nakladnoy_token}")

    assert javob.status_code == 200
    assert "Oddiy Shofyor" in javob.text
    assert "Oddiy Firma" in javob.text


def test_mavjud_bolmagan_token_404_qaytaradi(client, db_session):
    javob = client.get("/nakladnoy-korish/mavjud-bolmagan-token")
    assert javob.status_code == 404
