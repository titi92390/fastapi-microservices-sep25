from fastapi import FastAPI
from sqlmodel import SQLModel
from app.api.routes import items
from app.core.db import engine

app = FastAPI(title="Items Service")

# include routes
app.include_router(items.router)

# initialize database (safe if already created)
@app.on_event("startup")
def on_startup() -> None:
    SQLModel.metadata.create_all(engine)
