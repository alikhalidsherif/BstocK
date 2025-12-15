import os
from alembic import command
from alembic.config import Config

from .config import settings


def run_database_migrations() -> None:
    """
    Programmatically run Alembic migrations. Skips when using the in-memory SQLite dev DB.
    """
    database_url = settings.DATABASE_URL

    # Skip auto-migrations for SQLite to avoid unsupported ALTER operations.
    if database_url.startswith("sqlite"):
        return

    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    alembic_ini_path = os.path.join(root_dir, "alembic.ini")

    if not os.path.exists(alembic_ini_path):
        # Nothing to run if Alembic is not configured.
        return

    config = Config(alembic_ini_path)
    config.set_main_option("script_location", os.path.join(root_dir, "alembic"))
    config.set_main_option("sqlalchemy.url", database_url)

    command.upgrade(config, "head")

