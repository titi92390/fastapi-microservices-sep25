from fastapi import FastAPI
from sqlmodel import SQLModel
from app.api.routes import login
from app.core.db import engine

app = FastAPI(title="Auth Service")

# ROUTES
app.include_router(login.router)


# --- DATABASE INIT ---
@app.on_event("startup")
def on_startup():
    print("Initializing database...")
    SQLModel.metadata.create_all(engine)
