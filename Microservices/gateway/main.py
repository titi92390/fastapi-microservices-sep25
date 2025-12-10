from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import httpx

app = FastAPI(title="API Gateway", version="1.0.0")

# URLs internes Docker (NOMS DES SERVICES)
AUTH_URL = "http://auth:8002"
USERS_URL = "http://users:8001"
ITEMS_URL = "http://items:8003"


@app.get("/gateway")
@app.get("/gateway/")
def gateway_root():
    return {"gateway": "OK"}


# -------- USERS ----------
@app.get("/gateway/users")
async def get_users():
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{USERS_URL}/users")
        return r.json()


# -------- ITEMS ----------
@app.get("/gateway/items")
async def get_items():
    async with httpx.AsyncClient() as client:
        r = await client.get(f"{ITEMS_URL}/items")
        return r.json()


# -------- LOGIN ----------
@app.post("/gateway/login")
async def login(request: Request):
    data = await request.json()

    async with httpx.AsyncClient() as client:
        r = await client.post(f"{AUTH_URL}/login", json=data)

    return JSONResponse(r.json())
