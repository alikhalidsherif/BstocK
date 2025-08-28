import os
from pydantic import field_validator
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
    CORS_ALLOW_CREDENTIALS: bool = False
    CORS_ALLOW_METHODS: str | list[str] = "GET,POST,PUT,DELETE,OPTIONS,PATCH"  # Default value
    CORS_ALLOW_HEADERS: str | list[str] = "Content-Type,Authorization,Accept,Origin,User-Agent"  # Default value

    @field_validator("CORS_ALLOW_METHODS", "CORS_ALLOW_HEADERS", mode='before')
    @classmethod
    def assemble_cors_list(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str) and not v.startswith('['):
            return [item.strip() for item in v.split(',')]
        return v
    
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
