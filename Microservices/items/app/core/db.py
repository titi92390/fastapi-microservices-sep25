import os
from sqlmodel import create_engine

# In Docker dev: use 'pg' if using a user-defined network with Postgres container named 'pg'
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@pg:5432/postgres")

engine = create_engine(DATABASE_URL, echo=True)
