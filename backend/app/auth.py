from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status, Query
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext

from .config import settings
from . import schemas, crud
from .database import get_db
from sqlalchemy.orm import Session

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/token")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def _get_user_from_token(token: str, db: Session):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = crud.get_user_by_username(db, username=username)
    if user is None:
        raise credentials_exception
    return user

# Dependency for standard header-based auth
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    return _get_user_from_token(token=token, db=db)

# Dependency for query-param-based auth (for downloads)
def get_current_user_for_export(token: str = Query(None), db: Session = Depends(get_db)):
    if token is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    return _get_user_from_token(token=token, db=db)

# Dependency to check if the user is active
def get_current_active_user(current_user: schemas.User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# Dependency to check if the user is an admin
def get_current_active_admin(current_user: schemas.User = Depends(get_current_active_user)):
    if current_user.role != schemas.UserRole.admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user

# Dependency to check if the user is an admin or supervisor
def get_current_active_admin_or_supervisor(current_user: schemas.User = Depends(get_current_active_user)):
    if current_user.role not in (schemas.UserRole.admin, schemas.UserRole.supervisor):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user

# Dependency for query-param-based auth requiring admin or supervisor (for downloads)
def get_current_admin_or_supervisor_for_export(token: str = Query(None), db: Session = Depends(get_db)):
    if token is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    user = _get_user_from_token(token=token, db=db)
    if user.role not in (schemas.UserRole.admin, schemas.UserRole.supervisor):
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return user