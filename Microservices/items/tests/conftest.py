import sys
import os

# Ajoute la racine du microservice (Microservices/items) au PYTHONPATH
sys.path.insert(
    0,
    os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
)

