KONDITSION_KOEFFITSENT = 89.5


def konditsion_hisobla(netto: float, namlik: float, ifloslik: float) -> float:
    return netto * (100 - (namlik + ifloslik)) / KONDITSION_KOEFFITSENT
