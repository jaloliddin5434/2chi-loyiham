"""POST /backup (qo'lda backup) va avtomatik_backup() fon oqimidagi
pg_dump chaqiruvi timeout bilan himoyalanganini tasdiqlaydi - aks
holda pg_dump osilib qolsa, tegishli so'rov/thread abadiy to'xtab
qolar edi (kunlik avtomatik backup uchun bu BUTUN kelajakdagi
zaxiralashni to'xtatib qo'yishi mumkin edi).
"""
import subprocess
from unittest.mock import patch, MagicMock


def test_qolda_backup_timeout_parametri_bor(client, admin_headers):
    sohta_natija = MagicMock(returncode=0)
    with patch("subprocess.run", return_value=sohta_natija) as mock_run, \
         patch("main.os.path.getsize", return_value=1024):
        javob = client.post("/backup", headers=admin_headers)

    assert javob.status_code == 200
    assert javob.json()["status"] == "ok"
    assert mock_run.called
    _, kwargs = mock_run.call_args
    assert "timeout" in kwargs, "pg_dump chaqiruvida timeout yo'q!"
    assert kwargs["timeout"] > 0


def test_qolda_backup_pgdump_osilib_qolsa_500_qaytaradi_osilib_qolmaydi(client, admin_headers):
    """pg_dump vaqt tugashi bilan ishlamay qolsa (subprocess.TimeoutExpired),
    so'rov abadiy osilib qolmasligi, aksincha aniq xato javobi bilan
    tugashi kerak."""
    with patch("subprocess.run",
               side_effect=subprocess.TimeoutExpired(cmd="pg_dump", timeout=300)):
        javob = client.post("/backup", headers=admin_headers)

    assert javob.status_code == 200  # bu endpoint xatoni body'da qaytaradi
    natija = javob.json()
    assert natija["status"] == "error"
    assert "timed out" in natija["message"].lower() or "timeout" in natija["message"].lower()
