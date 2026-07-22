import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from pydantic import ValidationError

from schemas import OlchovCreate


def test_togri_qiymatlar_qabul_qilinadi():
    olchov = OlchovCreate(
        hujjat_id=1, arava_raqam=1, tara=1000, brutto=3000, namlik=5.0, ifloslik=3.0
    )
    assert olchov.namlik == 5.0
    assert olchov.ifloslik == 3.0


def test_manfiy_namlik_rad_etiladi():
    with pytest.raises(ValidationError):
        OlchovCreate(hujjat_id=1, arava_raqam=1, namlik=-1.0)


def test_100dan_katta_ifloslik_rad_etiladi():
    with pytest.raises(ValidationError):
        OlchovCreate(hujjat_id=1, arava_raqam=1, ifloslik=101.0)


def test_yigindisi_100dan_oshsa_rad_etiladi():
    with pytest.raises(ValidationError):
        OlchovCreate(hujjat_id=1, arava_raqam=1, namlik=60.0, ifloslik=45.0)
