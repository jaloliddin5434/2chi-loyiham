"""Hujjat.mahsulot_id va Navbat.tugallandi indekslari

Revision ID: be4513d4facd
Revises: 3ecc0b3c160d
Create Date: 2026-08-09 13:28:54.265179

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'be4513d4facd'
down_revision: Union[str, Sequence[str], None] = '3ecc0b3c160d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # DIQQAT: autogenerate `nakladnoy_token` ustunidagi ESKI, zararsiz
    # tarixiy farqni (alohida unique constraint vs unique index nomlanishi
    # - funksional jihatdan bir xil) ham qo'shib yubordi. Bu QASDDAN olib
    # tashlandi - bu migratsiya FAQAT ikkita yangi indeks uchun.
    op.create_index(op.f('ix_hujjatlar_mahsulot_id'), 'hujjatlar', ['mahsulot_id'], unique=False)
    op.create_index(op.f('ix_navbat_tugallandi'), 'navbat', ['tugallandi'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_navbat_tugallandi'), table_name='navbat')
    op.drop_index(op.f('ix_hujjatlar_mahsulot_id'), table_name='hujjatlar')
