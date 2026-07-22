import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

from utils import konditsion_hisobla, KONDITSION_KOEFFITSENT


def test_oddiy_hisoblash():
    natija = konditsion_hisobla(1000, 5, 3)
    kutilgan = 1000 * (100 - (5 + 3)) / KONDITSION_KOEFFITSENT
    assert natija == pytest.approx(kutilgan)


def test_namlik_va_ifloslik_nol():
    # Namlik va ifloslik 0 bo'lsa, hech narsa ayirilmaydi.
    natija = konditsion_hisobla(1000, 0, 0)
    kutilgan = 1000 * 100 / KONDITSION_KOEFFITSENT
    assert natija == pytest.approx(kutilgan)


def test_namlik_va_ifloslik_yigindisi_100():
    # Namlik+ifloslik=100 bo'lsa, (100-100)=0, natija 0 bo'lishi kerak.
    natija = konditsion_hisobla(1000, 60, 40)
    assert natija == pytest.approx(0.0)


def test_netto_nol():
    # Netto 0 bo'lsa, natija har doim 0 bo'lishi kerak.
    natija = konditsion_hisobla(0, 5, 3)
    assert natija == pytest.approx(0.0)


def test_real_hujjat_regression():
    """
    Bazadagi haqiqiy yozuv asosida regression test (SQL orqali topilgan):
    olchovlar.id=515, hujjat_id=219 -> netto=1000.0, namlik=5.0, ifloslik=3.0,
    konditsion=1027.9329608938547 (bazada saqlangan qiymat).

    Bu test konditsion_hisobla() natijasi bazadagi haqiqiy qiymat bilan
    mos kelishini tasdiqlaydi - agar formula yoki koeffitsent kelajakda
    o'zgartirilsa, bu test buzilib, e'tibor tortadi.
    """
    real_netto = 1000.0
    real_namlik = 5.0
    real_ifloslik = 3.0
    real_konditsion_bazada = 1027.9329608938547

    natija = konditsion_hisobla(real_netto, real_namlik, real_ifloslik)
    assert natija == pytest.approx(real_konditsion_bazada)
