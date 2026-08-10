"""Mashina.davlat_raqami uchun unique constraint

Revision ID: 800816102139
Revises: be4513d4facd
Create Date: 2026-08-10 09:00:43.613834

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '800816102139'
down_revision: Union[str, Sequence[str], None] = 'be4513d4facd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # DIQQAT: autogenerate `nakladnoy_token` ustunidagi ESKI, zararsiz
    # tarixiy farqni (alohida unique constraint vs unique index nomlanishi
    # - funksional jihatdan bir xil) ham qo'shib yubordi. Bu QASDDAN olib
    # tashlandi - bu migratsiya FAQAT Mashina.davlat_raqami uchun.
    op.drop_index(op.f('ix_mashinalar_davlat_raqami'), table_name='mashinalar')
    op.create_index(op.f('ix_mashinalar_davlat_raqami'), 'mashinalar', ['davlat_raqami'], unique=True)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_mashinalar_davlat_raqami'), table_name='mashinalar')
    op.create_index(op.f('ix_mashinalar_davlat_raqami'), 'mashinalar', ['davlat_raqami'], unique=False)
