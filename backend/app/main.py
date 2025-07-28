from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from . import models, auth
from .routers import users, inventory, products, history

# This will create the database tables if they don't exist
# on application startup. For production, you might want to handle
# migrations with something like Alembic.
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="BstocK API",
    description="API for the BstocK inventory management system.",
    version="0.1.0",
)

# CORS Middleware
origins = [
    "*",  # Allow all origins for development
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include inventory, products, and history routers first to avoid prefix clash
app.include_router(inventory.router)
app.include_router(products.router)
app.include_router(history.router)
# Users router handles user endpoints (including /api/token and /api/users/*)
app.include_router(users.router, prefix="/api", tags=["Users"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the BstocK API"}
