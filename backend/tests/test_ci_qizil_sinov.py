"""VAQTINCHALIK - CI'ning haqiqatan xatoni ushlashini tasdiqlash uchun.
Tasdiqlangach darhol olib tashlanadi."""


def test_ci_atayin_muvaffaqiyatsiz():
    assert False, "CI qizil (failed) belgi qo'yishini tekshirish uchun ataylab buzilgan test"
