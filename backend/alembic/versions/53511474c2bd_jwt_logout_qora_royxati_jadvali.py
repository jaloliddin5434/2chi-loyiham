"""JWT logout qora royxati jadvali

Revision ID: 53511474c2bd
Revises: 800816102139
Create Date: 2026-08-10 09:26:04.643762

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '53511474c2bd'
down_revision: Union[str, Sequence[str], None] = '800816102139'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # DIQQAT: autogenerate `nakladnoy_token` ustunidagi ESKI, zararsiz
    # tarixiy farqni ham qo'shib yubordi (qarang: avvalgi migratsiyalar).
    # Bu QASDDAN olib tashlandi - bu migratsiya FAQAT yangi jadval uchun.
    op.create_table('qora_royxat_tokenlar',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('jti', sa.String(), nullable=False),
    sa.Column('amal_qilish_muddati', sa.DateTime(), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_qora_royxat_tokenlar_amal_qilish_muddati'), 'qora_royxat_tokenlar', ['amal_qilish_muddati'], unique=False)
    op.create_index(op.f('ix_qora_royxat_tokenlar_id'), 'qora_royxat_tokenlar', ['id'], unique=False)
    op.create_index(op.f('ix_qora_royxat_tokenlar_jti'), 'qora_royxat_tokenlar', ['jti'], unique=True)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_qora_royxat_tokenlar_jti'), table_name='qora_royxat_tokenlar')
    op.drop_index(op.f('ix_qora_royxat_tokenlar_id'), table_name='qora_royxat_tokenlar')
    op.drop_index(op.f('ix_qora_royxat_tokenlar_amal_qilish_muddati'), table_name='qora_royxat_tokenlar')
    op.drop_table('qora_royxat_tokenlar')
