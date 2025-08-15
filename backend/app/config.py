from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./stock_dev.db"  # Default to local SQLite for ease of development
    # Provide a safe development default to avoid startup failure when .env is missing.
    # Replace in production via environment variable.
    SECRET_KEY: str = "change_me_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    class Config:
        env_file = ".env"


settings = Settings()
