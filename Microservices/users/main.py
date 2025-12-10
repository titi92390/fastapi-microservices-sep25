from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Users Service", version="1.0.0")

# Modèle utilisateur simple
class User(BaseModel):
    id: int
    name: str
    email: str

# Base de données "fake" (en mémoire)
users_db = [
    User(id=1, name="Alice", email="alice@example.com"),
    User(id=2, name="Bob", email="bob@example.com"),
]

@app.get("/")
def root():
    return {"message": "Users service OK"}

@app.get("/users")
def get_users():
    return users_db

@app.get("/users/{user_id}")
def get_user(user_id: int):
    for user in users_db:
        if user.id == user_id:
            return user
    return {"error": "User not found"}

# Export des métriques pour Prometheus
@app.get("/metrics")
def metrics():
    return {"status": "metrics OK"}

# Lancement Uvicorn
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=False)
