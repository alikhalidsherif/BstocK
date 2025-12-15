from pydantic import computed_field, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="allow"
    )

    # --- Part 1: Define fields with a '_raw' suffix ---
    # Pydantic will accept these names (no leading underscores).
    
    DATABASE_URL_raw: str = Field("sqlite:///./stock_dev.db", alias='DATABASE_URL')
    SECRET_KEY_raw: str = Field("change_me_in_production", alias='SECRET_KEY')
    MASTER_USERNAME_raw: str = Field("bstock_master", alias='MASTER_USERNAME')
    MASTER_PASSWORD_raw: str = Field("change_me_master", alias='MASTER_PASSWORD')
    ENVIRONMENT_raw: str = Field("development", alias='ENVIRONMENT')
    JWT_ALGORITHM_raw: str = Field("HS256", alias='JWT_ALGORITHM')
    ACCESS_TOKEN_EXPIRE_MINUTES_raw: int = Field(30, alias='ACCESS_TOKEN_EXPIRE_MINUTES')
    
    # These are the problematic fields that caused parsing errors
    CORS_ALLOW_ORIGINS_raw: str = Field("", alias='CORS_ALLOW_ORIGINS')
    CORS_ALLOW_ORIGIN_REGEX_raw: str | None = Field(r"http://(localhost|127\.0\.0\.1):\d+", alias='CORS_ALLOW_ORIGIN_REGEX')
    CORS_ALLOW_METHODS_raw: str = Field("GET,POST,PUT,DELETE,OPTIONS,PATCH", alias='CORS_ALLOW_METHODS')
    CORS_ALLOW_HEADERS_raw: str = Field("Content-Type,Authorization,Accept,Origin,User-Agent", alias='CORS_ALLOW_HEADERS')
    CORS_ALLOW_CREDENTIALS_raw: bool = Field(False, alias='CORS_ALLOW_CREDENTIALS')
    
    # API Documentation Configuration
    DISABLE_OPENAPI_raw: bool = Field(False, alias='DISABLE_OPENAPI')
    
    # Database Migration Configuration
    AUTO_CREATE_TABLES_raw: bool = Field(True, alias='AUTO_CREATE_TABLES')
    
    # Server Configuration
    HOST_raw: str = Field("0.0.0.0", alias='HOST')
    PORT_raw: int = Field(8000, alias='PORT')

    # --- Part 2: Create computed properties that the rest of your app will use ---
    # These have the clean, public names that your app expects.
    
    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        return self.DATABASE_URL_raw

    @computed_field
    @property
    def SECRET_KEY(self) -> str:
        return self.SECRET_KEY_raw

    @computed_field
    @property
    def MASTER_USERNAME(self) -> str:
        return self.MASTER_USERNAME_raw

    @computed_field
    @property
    def MASTER_PASSWORD(self) -> str:
        return self.MASTER_PASSWORD_raw

    @computed_field
    @property
    def ENVIRONMENT(self) -> str:
        return self.ENVIRONMENT_raw

    @computed_field
    @property
    def JWT_ALGORITHM(self) -> str:
        return self.JWT_ALGORITHM_raw

    @computed_field
    @property
    def ACCESS_TOKEN_EXPIRE_MINUTES(self) -> int:
        return self.ACCESS_TOKEN_EXPIRE_MINUTES_raw
        
    @computed_field
    @property
    def CORS_ALLOW_CREDENTIALS(self) -> bool:
        return self.CORS_ALLOW_CREDENTIALS_raw

    @computed_field
    @property
    def CORS_ALLOW_ORIGIN_REGEX(self) -> str | None:
        return self.CORS_ALLOW_ORIGIN_REGEX_raw

    @computed_field
    @property
    def CORS_ALLOW_ORIGINS(self) -> list[str]:
        if not self.CORS_ALLOW_ORIGINS_raw:
            return []
        def _normalize(origin: str) -> str:
            cleaned = origin.strip()
            # Trailing slashes break exact origin matching in CORS checks.
            return cleaned.rstrip("/")

        return [
            _normalize(item)
            for item in self.CORS_ALLOW_ORIGINS_raw.split(',')
            if item.strip()
        ]

    @computed_field
    @property
    def CORS_ALLOW_METHODS(self) -> list[str]:
        if not self.CORS_ALLOW_METHODS_raw:
            return []
        return [item.strip() for item in self.CORS_ALLOW_METHODS_raw.split(',') if item.strip()]

    @computed_field
    @property
    def CORS_ALLOW_HEADERS(self) -> list[str]:
        if not self.CORS_ALLOW_HEADERS_raw:
            return []
        return [item.strip() for item in self.CORS_ALLOW_HEADERS_raw.split(',') if item.strip()]

    @computed_field
    @property
    def DISABLE_OPENAPI(self) -> bool:
        return self.DISABLE_OPENAPI_raw

    @computed_field
    @property
    def AUTO_CREATE_TABLES(self) -> bool:
        return self.AUTO_CREATE_TABLES_raw

    @computed_field
    @property
    def HOST(self) -> str:
        return self.HOST_raw

    @computed_field
    @property
    def PORT(self) -> int:
        return self.PORT_raw


settings = Settings()
