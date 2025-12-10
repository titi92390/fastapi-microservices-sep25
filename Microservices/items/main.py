from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Items Service", version="1.0.0")

class Item(BaseModel):
    id: int
    name: str
    price: float

fake_db = [
    {"id": 1, "name": "Laptop", "price": 1200.0},
    {"id": 2, "name": "Mouse", "price": 25.5},
]

@app.get("/")
def root():
    return {"message": "Items service OK"}

@app.get("/items")
def get_items():
    return fake_db

@app.get("/items/{item_id}")
def get_item(item_id: int):
    for item in fake_db:
        if item["id"] == item_id:
            return item
    return {"error": "Item not found"}

@app.post("/items")
def add_item(item: Item):
    fake_db.append(item.dict())
    return {"message": "Item added", "item": item}

# Prometheus endpoint
@app.get("/metrics")
def metrics():
    return {"status": "metrics OK"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8003, reload=False)
