import os
from sqlmodel import create_engine

# Kubernetes: use the service name
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://postgres:postgres@postgres-postgresql.dev.svc.cluster.local:5432/postgres"
)

engine = create_engine(DATABASE_URL, echo=True)