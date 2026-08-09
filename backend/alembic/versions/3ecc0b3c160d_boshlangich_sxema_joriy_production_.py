"""boshlangich sxema - joriy production bazasi

Bu migratsiya ATAYLAB bo'sh (no-op) - Alembic bu loyihaga endigina
qo'shildi, production bazasi esa allaqachon (Base.metadata.create_all()
va bir martalik migratsiya skriptlari orqali) to'liq sxemaga ega.
Bu revision faqat `alembic stamp head` orqali "hozirgi holat shu
nuqtadan boshlanadi" deb BELGILASH uchun, real DDL bajarmasdan
yaratilgan. Bundan keyingi HAR QANDAY sxema o'zgarishi (yangi ustun,
indeks va h.k.) `alembic revision --autogenerate` bilan, shu
revisiondan keyingi qadam sifatida yaratilishi kerak.

Revision ID: 3ecc0b3c160d
Revises:
Create Date: 2026-08-09 12:55:01.817796

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3ecc0b3c160d'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
