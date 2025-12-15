from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from . import models, auth
from .routers import users, inventory, products, history
from .routers import realtime
from .config import settings
from .migrations_runner import run_database_migrations
from .master_account import ensure_master_account

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

# CORS Middleware Configuration
# Prefer explicit origins from environment (Render provides these); fall back to regex for local dev.
cors_allow_origins = settings.CORS_ALLOW_ORIGINS
cors_allow_origin_regex = None
if not cors_allow_origins:
    cors_allow_origin_regex = settings.CORS_ALLOW_ORIGIN_REGEX

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_allow_origins,
    allow_origin_regex=cors_allow_origin_regex,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=settings.CORS_ALLOW_METHODS or ["*"],
    allow_headers=settings.CORS_ALLOW_HEADERS or ["*"],
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

def _health_payload():
    return {"status": "ok", "env": settings.ENVIRONMENT}


@app.get("/healthz")
def health_check():
    return _health_payload()


@app.get("/health")
def health_check_short():
    return _health_payload()

# Basic startup validation
@app.on_event("startup")
def validate_settings_on_startup():
    if settings.ENVIRONMENT.lower() == "production":
        if settings.SECRET_KEY == "change_me_in_production":
            raise RuntimeError("SECURITY: SECRET_KEY must be set in production")
        if settings.MASTER_USERNAME == "bstock_master" or settings.MASTER_PASSWORD == "change_me_master":
            raise RuntimeError("SECURITY: Configure MASTER_USERNAME and MASTER_PASSWORD in production.")

    run_database_migrations()
    ensure_master_account()
