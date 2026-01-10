from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel
from app.api.routes import login, verify
from app.core.db import engine

app = FastAPI(
    title="Auth Service",
    root_path="/api/auth"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(login.router, prefix="/login", tags=["login"])
app.include_router(verify.router, prefix="/verify", tags=["verify"])

# DB init
@app.on_event("startup")
def on_startup() -> None:
    SQLModel.metadata.create_all(engine)
