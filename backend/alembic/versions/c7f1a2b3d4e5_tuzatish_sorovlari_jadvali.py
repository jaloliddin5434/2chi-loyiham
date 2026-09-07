"""Tuzatish so'rovlari jadvali

Revision ID: c7f1a2b3d4e5
Revises: 53511474c2bd
Create Date: 2026-09-07 00:00:00.000000

Operator hujjat maydonini to'g'ridan-to'g'ri o'zgartira olmaydi -
"tuzatish so'rovi" qoldiradi, admin tasdiqlaydi yoki rad etadi.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c7f1a2b3d4e5'
down_revision: Union[str, Sequence[str], None] = '53511474c2bd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Bu loyihada sxema tarixan `Base.metadata.create_all()` orqali ham
    # yaratiladi - backend qayta ishga tushganda jadval allaqachon paydo
    # bo'lishi mumkin. Shu sabab avval mavjudligini tekshiramiz.
    bind = op.get_bind()
    insp = sa.inspect(bind)
    if 'tuzatish_sorovlari' in insp.get_table_names():
        return

    op.create_table(
        'tuzatish_sorovlari',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('hujjat_id', sa.Integer(), nullable=True),
        sa.Column('operator_login', sa.String(), nullable=True),
        sa.Column('maydon_nomi', sa.String(), nullable=True),
        sa.Column('eski_qiymat', sa.Text(), nullable=True),
        sa.Column('yangi_qiymat', sa.Text(), nullable=True),
        sa.Column('sabab', sa.Text(), nullable=True),
        sa.Column('holat', sa.String(), nullable=True),
        sa.Column('yaratilgan_vaqt', sa.DateTime(), nullable=True),
        sa.Column('hal_qilingan_vaqt', sa.DateTime(), nullable=True),
        sa.Column('admin_login', sa.String(), nullable=True),
        sa.ForeignKeyConstraint(['hujjat_id'], ['hujjatlar.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_tuzatish_sorovlari_id'), 'tuzatish_sorovlari', ['id'], unique=False)
    op.create_index(op.f('ix_tuzatish_sorovlari_hujjat_id'), 'tuzatish_sorovlari', ['hujjat_id'], unique=False)
    op.create_index(op.f('ix_tuzatish_sorovlari_operator_login'), 'tuzatish_sorovlari', ['operator_login'], unique=False)
    op.create_index(op.f('ix_tuzatish_sorovlari_holat'), 'tuzatish_sorovlari', ['holat'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_tuzatish_sorovlari_holat'), table_name='tuzatish_sorovlari')
    op.drop_index(op.f('ix_tuzatish_sorovlari_operator_login'), table_name='tuzatish_sorovlari')
    op.drop_index(op.f('ix_tuzatish_sorovlari_hujjat_id'), table_name='tuzatish_sorovlari')
    op.drop_index(op.f('ix_tuzatish_sorovlari_id'), table_name='tuzatish_sorovlari')
    op.drop_table('tuzatish_sorovlari')
