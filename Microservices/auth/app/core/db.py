import os
from sqlmodel import create_engine
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/app")
engine = create_engine(DATABASE_URL, echo=True)
