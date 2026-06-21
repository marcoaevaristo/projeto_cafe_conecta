from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql://cafe:cafe123@localhost:5432/cafe_conecta"
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    cors_origins: str = "*"
    scraper_interval_hours: int = 6
    admin_token: str = "change-me-in-production"


settings = Settings()
