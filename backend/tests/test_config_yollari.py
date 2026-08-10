"""3-band: backup/RASMLAR yo'llari avval main.py ichida qattiq yozilgan
edi (C:\\hazorasp_tarozi\\backup, C:\\RASMLAR) - endi config.py (.env)
orqali sozlanadi. Bu test main.py haqiqatan BACKUP_DIR/RASMLAR_DIR
o'zgaruvchilarini (qattiq yozilgan satr emas) ishlatishini tasdiqlaydi -
main.BACKUP_DIR'ni sinov qiymatiga almashtirib, endpoint xuddi shu
(o'zgartirilgan) yo'lni ishlatishini tekshiradi."""
from unittest.mock import patch


def test_backup_royxat_configdagi_yolni_ishlatadi(client, admin_headers, tmp_path):
    sinov_papka = str(tmp_path / "sinov_backup_papkasi")
    with patch("main.BACKUP_DIR", sinov_papka):
        javob = client.get("/backup/royxat", headers=admin_headers)
    assert javob.status_code == 200
    assert javob.json()["fayllar"] == []
    # Endpoint aynan SHU (sinov) papkani yaratgan bo'lishi kerak -
    # qattiq yozilgan "C:\\hazorasp_tarozi\\backup" emas.
    import os
    assert os.path.isdir(sinov_papka)


def test_config_backup_va_rasmlar_dir_mavjud():
    import config
    assert config.BACKUP_DIR
    assert config.RASMLAR_DIR
    import main
    assert main.BACKUP_DIR == config.BACKUP_DIR
    assert main.RASMLAR_DIR == config.RASMLAR_DIR
