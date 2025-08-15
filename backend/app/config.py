from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./stock_dev.db"  # Default to local SQLite for ease of development
    # Provide a safe development default to avoid startup failure when .env is missing.
    # Replace in production via environment variable.
    SECRET_KEY: str = "change_me_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Environment / Runtime config
    ENV: str = "development"
    # Prefer explicit list of allowed origins in production. Example: ["https://app.example.com"]
    CORS_ALLOW_ORIGINS: list[str] = []
    # Fallback regex for dev: allow any localhost:port
    CORS_ALLOW_ORIGIN_REGEX: str | None = r"http://(localhost|127\.0\.0\.1):\d+"
    # Disable OpenAPI/Docs in strict production if desired
    DISABLE_OPENAPI: bool = False
    # Auto-create tables on startup. Keep true until migrations are set up.
    AUTO_CREATE_TABLES: bool = True

    class Config:
        env_file = ".env"


settings = Settings()
