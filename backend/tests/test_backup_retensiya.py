"""eski_backuplarni_tozala() - BACKUP_RETENSIYA_KUN'dan eski .sql
fayllarni o'chirishini, yangilarini va .sql BO'LMAGAN fayllarni
tegmasligini tekshiradi. Avval bunday tozalash umuman yo'q edi -
backup papkasi cheksiz o'sardi.
"""
import os
import time


def test_eski_fayllar_ochiriladi_yangilari_qoladi(tmp_path):
    import main

    eski_fayl = tmp_path / "backup_eski.sql"
    yangi_fayl = tmp_path / "backup_yangi.sql"
    boshqa_fayl = tmp_path / "notes.txt"

    eski_fayl.write_text("eski")
    yangi_fayl.write_text("yangi")
    boshqa_fayl.write_text("tegilmasin")

    # eski_fayl'ni 40 kun oldin o'zgartirilgandek qilib belgilaymiz
    qirq_kun_oldin = time.time() - 40 * 86400
    os.utime(eski_fayl, (qirq_kun_oldin, qirq_kun_oldin))

    ochirilgan_soni = main.eski_backuplarni_tozala(str(tmp_path), kun_soni=30)

    assert ochirilgan_soni == 1
    assert not eski_fayl.exists(), "30 kundan eski .sql fayl o'chirilishi kerak edi"
    assert yangi_fayl.exists(), "yangi .sql fayl tegilmasligi kerak"
    assert boshqa_fayl.exists(), ".sql bo'lmagan fayl HECH QACHON o'chirilmasligi kerak"


def test_bosh_papkada_xato_bermaydi(tmp_path):
    import main
    natija = main.eski_backuplarni_tozala(str(tmp_path), kun_soni=30)
    assert natija == 0
