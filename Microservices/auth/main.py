from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Auth Service", version="1.0.0")

# Modèle pour login
class LoginRequest(BaseModel):
    username: str
    password: str

@app.get("/")
def root():
    return {"message": "Auth service OK"}

@app.post("/login")
def login(data: LoginRequest):
    # Credentials autorisés
    if data.username == "test" and data.password == "123":
        return {"token": "valid-test-token"}

    if data.username == "admin" and data.password == "password":
        return {"token": "admin-token"}

    return {"error": "Invalid credentials"}

# Prometheus
@app.get("/metrics")
def metrics():
    return {"status": "metrics OK"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=False)
