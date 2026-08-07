from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    except Exception:
        # Aniq (explicit) rollback - db.close() committed bo'lmagan ishni
        # baribir bekor qiladi, lekin bunga yashirin ravishda tayanish
        # o'rniga shu yerda ATAYLAB ko'rsatib qo'yamiz.
        db.rollback()
        raise
    finally:
        db.close()