"""GET /tizim-xatolari - vaqt maydonining formati.

Real production'da (2026-08-11) `str(x.created_at)` orqali mikrosekund
bilan chiqarilgan vaqt tamg'asi ("2026-08-10 08:07:09.897079") xato
matni ("...kod bilan tugadi: 16") bilan yonma-yon ko'rinib, operatorni
mikrosekund qismini ("897079") xato kodining bir qismi deb noto'g'ri
o'ylashiga olib kelgan edi. Endi vaqt mikrosekundsiz chiqariladi."""
import re
from datetime import datetime


def test_vaqt_mikrosekundsiz_chiqariladi(client, db_session, admin_headers):
    from models import TizimXatosi
    yozuv = TizimXatosi(turi="tarmoq_backup", xabar="robocopy xato kod bilan tugadi: 16")
    db_session.add(yozuv)
    db_session.commit()

    javob = client.get("/tizim-xatolari", headers=admin_headers)
    assert javob.status_code == 200
    mos = next(x for x in javob.json() if x["turi"] == "tarmoq_backup"
               and x["xabar"] == "robocopy xato kod bilan tugadi: 16")

    assert "." not in mos["vaqt"], f"Vaqt mikrosekund bilan chiqmoqda: {mos['vaqt']!r}"
    # To'g'ri formatga mos kelishi ("YYYY-MM-DD HH:MM:SS") - shu bilan
    # datetime.strptime orqali qayta parse qilib bo'lishi tasdiqlanadi.
    datetime.strptime(mos["vaqt"], "%Y-%m-%d %H:%M:%S")
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}", mos["vaqt"])
