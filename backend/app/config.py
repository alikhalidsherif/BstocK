import os
from pydantic import field_validator, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # This nested class is the configuration for Pydantic itself
    model_config = SettingsConfigDict(
        env_file=".env", 
        env_file_encoding="utf-8", 
        extra="allow"  # This tells Pydantic to ignore extra fields instead of crashing
    )

    # Database Configuration
    DATABASE_URL: str = "sqlite:///./stock_dev.db"
    
    # Security Configuration
    SECRET_KEY: str = "change_me_in_production"
    JWT_ALGORITHM: str = "HS256"  # Standardized field name
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Environment / Runtime Configuration
    ENVIRONMENT: str = "development"  # Standardized field name
    
    # CORS Configuration
    # For production, set specific allowed origins. For development, use regex pattern
    CORS_ALLOW_ORIGINS: list[str] = []  # Default value
    CORS_ALLOW_ORIGIN_REGEX: str | None = r"http://(localhost|127\.0\.0\.1):\d+"
    
    # CORS Additional Settings
    CORS_ALLOW_CREDENTIALS: bool = False
    CORS_ALLOW_METHODS: str | list[str] = "GET,POST,PUT,DELETE,OPTIONS,PATCH"
    CORS_ALLOW_HEADERS: str | list[str] = "Content-Type,Authorization,Accept,Origin,User-Agent"

    @field_validator("CORS_ALLOW_METHODS", "CORS_ALLOW_HEADERS", mode='before')
    @classmethod
    def assemble_cors_list(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str) and not v.startswith('['):
            return [item.strip() for item in v.split(',')]
        return v

    # SPECIAL VALIDATOR FOR ORIGINS - Handles Render's weird list behavior
    @field_validator("CORS_ALLOW_ORIGINS", mode='before')
    @classmethod
    def assemble_origins_list(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, list) and len(v) > 0 and isinstance(v[0], str):
            # This handles the case where Render provides ['https://...']
            # It splits any comma-separated strings within the list
            return [origin.strip() for item in v for origin in item.split(',') if origin.strip()]
        if isinstance(v, str) and v.strip():
            # This handles the normal case of a comma-separated string
            return [item.strip() for item in v.split(',') if item.strip()]
        return []
    
    # API Documentation Configuration
    DISABLE_OPENAPI: bool = False
    
    # Database Migration Configuration
    AUTO_CREATE_TABLES: bool = True
    
    # Server Configuration
    HOST: str = "0.0.0.0"
    PORT: int = 8000


settings = Settings()
