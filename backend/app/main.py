from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from . import models, auth
from .routers import users, inventory, products, history
from .routers import realtime
from .config import settings

# In dev with SQLite, auto-create tables for convenience. In production,
# use proper migrations (e.g., Alembic) and a managed database.
if settings.AUTO_CREATE_TABLES:
    Base.metadata.create_all(bind=engine)

openapi_url = None if settings.DISABLE_OPENAPI else "/openapi.json"
docs_url = None if settings.DISABLE_OPENAPI else "/docs"
redoc_url = None if settings.DISABLE_OPENAPI else "/redoc"

app = FastAPI(
    title="BstocK API",
    description="API for the BstocK inventory management system.",
    version="0.1.0",
    openapi_url=openapi_url,
    docs_url=docs_url,
    redoc_url=redoc_url,
)

# CORS Middleware Configuration - Permissive for testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
app.include_router(realtime.router)

@app.get("/")
def read_root():
    return {"status": "ok"}

@app.get("/healthz")
def health_check():
    return {"status": "ok", "env": settings.ENVIRONMENT}

# Basic startup validation
@app.on_event("startup")
def validate_settings_on_startup():
    if settings.ENVIRONMENT.lower() == "production" and settings.SECRET_KEY == "change_me_in_production":
        raise RuntimeError("SECURITY: SECRET_KEY must be set in production")
