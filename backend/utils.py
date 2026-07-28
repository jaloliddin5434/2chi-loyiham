import re
from datetime import datetime

KONDITSION_KOEFFITSENT = 89.5


def konditsion_hisobla(netto: float, namlik: float, ifloslik: float) -> float:
    return netto * (100 - (namlik + ifloslik)) / KONDITSION_KOEFFITSENT


_XAVFSIZ_EMAS_BELGILAR = re.compile(r'[\\/:*?"<>|\x00-\x1f]')


def xavfsiz_papka_nomi(matn: str, standart: str = "Nomalum", uzunlik: int = 100) -> str:
    """Fayl/papka nomi sifatida ishlatiladigan (mahsulot nomi, mashina
    raqami kabi) matnni xavfsizlashtiradi - yo'l-o'tish (path traversal)
    hujumining oldini oladi. Yo'l ajratuvchilarini ('/', '\\') va
    Windows'da fayl nomida taqiqlangan boshqa belgilarni olib tashlaydi,
    shu sabab natija HECH QACHON yangi '/' bilan ajratilgan segment
    qo'sha olmaydi (masalan "../../x" -> ".._.._x" - papka nomining bir
    qismi, ota-papkaga chiqish EMAS).
    """
    if not matn:
        return standart
    tozalangan = _XAVFSIZ_EMAS_BELGILAR.sub("_", matn.strip())
    tozalangan = tozalangan.strip(". ")[:uzunlik].strip()
    return tozalangan or standart


def xavfsiz_sana(sana_matn) -> str:
    """So'rovdan kelgan sana matnini tekshiradi - agar haqiqiy
    YYYY-MM-DD formatida bo'lmasa (masalan path-traversal urinishi yoki
    shunchaki xato format), fayl yo'liga xavfsiz standart (bugungi
    sana) bilan almashtiradi."""
    try:
        datetime.strptime(str(sana_matn), "%Y-%m-%d")
        return sana_matn
    except (ValueError, TypeError):
        return datetime.now().strftime("%Y-%m-%d")
