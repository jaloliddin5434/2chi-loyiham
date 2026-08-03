"""
Hujjat holati o'tish qoidalari (holat_otishi_ruxsatmi) - eng muhim
biznes-qoidalardan biri: JARAYON dan TUGALLANDI/BEKOR ga o'tish mumkin,
lekin TUGALLANDI/BEKOR - yakuniy holatlar, ulardan (hatto orqaga ham)
hech qayerga o'tib bo'lmaydi.
"""
import pytest

import main
from models import HujjatHolati

J = HujjatHolati.JARAYON
T = HujjatHolati.TUGALLANDI
B = HujjatHolati.BEKOR_QILINDI


@pytest.mark.parametrize("eski,yangi,kutilgan", [
    # JARAYON dan - ikkalasiga ham, o'ziga ham ruxsat
    (J, T, True),
    (J, B, True),
    (J, J, True),
    # TUGALLANDI - yakuniy, faqat o'ziga (no-op) ruxsat
    (T, J, False),
    (T, B, False),
    (T, T, True),
    # BEKOR_QILINDI - yakuniy, faqat o'ziga (no-op) ruxsat
    (B, J, False),
    (B, T, False),
    (B, B, True),
])
def test_holat_otishlari(eski, yangi, kutilgan):
    assert main.holat_otishi_ruxsatmi(eski, yangi) == kutilgan
