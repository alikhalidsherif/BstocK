import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database Configuration
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./stock_dev.db")
    
    # Security Configuration
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change_me_in_production")
    ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

    # Environment / Runtime Configuration
    ENV: str = os.getenv("ENVIRONMENT", "development")
    
    # CORS Configuration
    # For production, set specific allowed origins. For development, use regex pattern
    CORS_ALLOW_ORIGINS: list[str] = [
        origin.strip() for origin in os.getenv("CORS_ALLOW_ORIGINS", "").split(",") if origin.strip()
    ]
    CORS_ALLOW_ORIGIN_REGEX: str | None = os.getenv(
        "CORS_ALLOW_ORIGIN_REGEX", 
        r"http://(localhost|127\.0\.0\.1):\d+"
    )
    
    # CORS Additional Settings
    CORS_ALLOW_CREDENTIALS: bool = os.getenv("CORS_ALLOW_CREDENTIALS", "false").lower() == "true"
    CORS_ALLOW_METHODS: list[str] = [
        method.strip() for method in os.getenv("CORS_ALLOW_METHODS", "GET,POST,PUT,DELETE,OPTIONS,PATCH").split(",")
    ]
    CORS_ALLOW_HEADERS: list[str] = [
        header.strip() for header in os.getenv("CORS_ALLOW_HEADERS", "Content-Type,Authorization,Accept,Origin,User-Agent").split(",")
    ]
    
    # API Documentation Configuration
    DISABLE_OPENAPI: bool = os.getenv("DISABLE_OPENAPI", "false").lower() == "true"
    
    # Database Migration Configuration
    AUTO_CREATE_TABLES: bool = os.getenv("AUTO_CREATE_TABLES", "true").lower() == "true"
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))

    class Config:
        env_file = ".env"


settings = Settings()
