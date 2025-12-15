from sqlalchemy.orm import Session

from .config import settings
from .database import SessionLocal
from . import models, auth


def ensure_master_account() -> None:
    """
    Ensure the master account exists with the configured credentials.
    The master account is always active and has admin privileges.
    """
    username = settings.MASTER_USERNAME
    password = settings.MASTER_PASSWORD

    if not username or not password:
        raise RuntimeError(
            "MASTER_USERNAME and MASTER_PASSWORD must be configured before starting the API."
        )

    db: Session = SessionLocal()
    try:
        master_user = (
            db.query(models.User).filter(models.User.username == username).first()
        )
        hashed_password = auth.get_password_hash(password)

        if master_user is None:
            master_user = models.User(
                username=username,
                hashed_password=hashed_password,
                role=models.UserRole.admin,
                is_active=True,
            )
            db.add(master_user)
            db.commit()
            return

        # Ensure credentials and privileges stay in sync with configuration.
        mutated = False
        if not auth.verify_password(password, master_user.hashed_password):
            master_user.hashed_password = hashed_password
            mutated = True
        if master_user.role != models.UserRole.admin:
            master_user.role = models.UserRole.admin
            mutated = True
        if not master_user.is_active:
            master_user.is_active = True
            mutated = True

        if mutated:
            db.add(master_user)
            db.commit()
    finally:
        db.close()

