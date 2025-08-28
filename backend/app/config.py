from pydantic import computed_field, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="allow"
    )

    # --- Part 1: Define fields to accept RAW string input from Render ---
    # We use an alias to connect the environment variable (e.g., 'DATABASE_URL')
    # to our internal, private variable (e.g., '_DATABASE_URL')
    
    _DATABASE_URL: str = Field("sqlite:///./stock_dev.db", alias='DATABASE_URL')
    _SECRET_KEY: str = Field("change_me_in_production", alias='SECRET_KEY')
    _ENVIRONMENT: str = Field("development", alias='ENVIRONMENT')
    _JWT_ALGORITHM: str = Field("HS256", alias='JWT_ALGORITHM')
    _ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(30, alias='ACCESS_TOKEN_EXPIRE_MINUTES')
    
    # These are the ones causing the error. We will read them as simple strings.
    _CORS_ALLOW_ORIGINS: str = Field("", alias='CORS_ALLOW_ORIGINS')
    _CORS_ALLOW_ORIGIN_REGEX: str | None = Field(r"http://(localhost|127\.0\.0\.1):\d+", alias='CORS_ALLOW_ORIGIN_REGEX')
    _CORS_ALLOW_METHODS: str = Field("GET,POST,PUT,DELETE,OPTIONS,PATCH", alias='CORS_ALLOW_METHODS')
    _CORS_ALLOW_HEADERS: str = Field("Content-Type,Authorization,Accept,Origin,User-Agent", alias='CORS_ALLOW_HEADERS')
    _CORS_ALLOW_CREDENTIALS: bool = Field(False, alias='CORS_ALLOW_CREDENTIALS')
    
    # API Documentation Configuration
    _DISABLE_OPENAPI: bool = Field(False, alias='DISABLE_OPENAPI')
    
    # Database Migration Configuration
    _AUTO_CREATE_TABLES: bool = Field(True, alias='AUTO_CREATE_TABLES')
    
    # Server Configuration
    _HOST: str = Field("0.0.0.0", alias='HOST')
    _PORT: int = Field(8000, alias='PORT')

    # --- Part 2: Create computed properties that the rest of your app will use ---
    # These are clean, correctly typed, and safe to use everywhere else.
    
    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        return self._DATABASE_URL

    @computed_field
    @property
    def SECRET_KEY(self) -> str:
        return self._SECRET_KEY

    @computed_field
    @property
    def ENVIRONMENT(self) -> str:
        return self._ENVIRONMENT

    @computed_field
    @property
    def JWT_ALGORITHM(self) -> str:
        return self._JWT_ALGORITHM

    @computed_field
    @property
    def ACCESS_TOKEN_EXPIRE_MINUTES(self) -> int:
        return self._ACCESS_TOKEN_EXPIRE_MINUTES
        
    @computed_field
    @property
    def CORS_ALLOW_CREDENTIALS(self) -> bool:
        return self._CORS_ALLOW_CREDENTIALS

    @computed_field
    @property
    def CORS_ALLOW_ORIGIN_REGEX(self) -> str | None:
        return self._CORS_ALLOW_ORIGIN_REGEX

    @computed_field
    @property
    def CORS_ALLOW_ORIGINS(self) -> list[str]:
        if not self._CORS_ALLOW_ORIGINS:
            return []
        return [item.strip() for item in self._CORS_ALLOW_ORIGINS.split(',') if item.strip()]

    @computed_field
    @property
    def CORS_ALLOW_METHODS(self) -> list[str]:
        if not self._CORS_ALLOW_METHODS:
            return []
        return [item.strip() for item in self._CORS_ALLOW_METHODS.split(',') if item.strip()]

    @computed_field
    @property
    def CORS_ALLOW_HEADERS(self) -> list[str]:
        if not self._CORS_ALLOW_HEADERS:
            return []
        return [item.strip() for item in self._CORS_ALLOW_HEADERS.split(',') if item.strip()]

    @computed_field
    @property
    def DISABLE_OPENAPI(self) -> bool:
        return self._DISABLE_OPENAPI

    @computed_field
    @property
    def AUTO_CREATE_TABLES(self) -> bool:
        return self._AUTO_CREATE_TABLES

    @computed_field
    @property
    def HOST(self) -> str:
        return self._HOST

    @computed_field
    @property
    def PORT(self) -> int:
        return self._PORT


settings = Settings()
