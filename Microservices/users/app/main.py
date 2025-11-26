from fastapi import FastAPI
from sqlmodel import SQLModel
from app.api.routes import users
from app.core.db import engine

app = FastAPI(title="Users Service")

# include routes
app.include_router(users.router)

# initialize database (safe if already created)
@app.on_event("startup")
def on_startup() -> None:
    SQLModel.metadata.create_all(engine)
