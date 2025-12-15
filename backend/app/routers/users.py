from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List
from sqlalchemy.exc import IntegrityError

from .. import auth, crud, models, schemas
from ..database import get_db
from ..config import settings

router = APIRouter()

def get_current_user(token: str = Depends(auth.oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = auth.jwt.decode(token, auth.settings.SECRET_KEY, algorithms=[auth.settings.JWT_ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=username)
    except auth.JWTError:
        raise credentials_exception
    user = crud.get_user_by_username(db, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user

def get_current_active_user(current_user: models.User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

def get_current_active_admin(current_user: models.User = Depends(get_current_active_user)):
    if current_user.role != models.UserRole.admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return current_user

@router.post("/users/", response_model=schemas.User, dependencies=[Depends(auth.get_current_active_admin)])
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    if user.username == settings.MASTER_USERNAME:
        raise HTTPException(status_code=400, detail="MASTER_USERNAME is reserved for the master account.")
    return crud.create_user(db=db, user=user)

@router.post("/token", response_model=schemas.Token)
def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = crud.get_user_by_username(db, username=form_data.username)
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/users/me/", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(get_current_active_user)):
    return current_user

@router.get("/users/", response_model=List[schemas.User], dependencies=[Depends(get_current_active_admin)])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = crud.get_users(db, skip=skip, limit=limit)
    return users

@router.put("/users/{user_id}", response_model=schemas.User, dependencies=[Depends(get_current_active_admin)])
def update_user_role(user_id: int, user_in: schemas.UserUpdate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    try:
        user = crud.update_user(db=db, user=user, user_in=user_in)
    except ValueError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    return user

@router.delete("/users/{user_id}", response_model=schemas.User, dependencies=[Depends(get_current_active_admin)])
def remove_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    try:
        user = crud.delete_user(db=db, user=user)
    except ValueError as exc:
        raise HTTPException(status_code=403, detail=str(exc))
    except IntegrityError:
        raise HTTPException(
            status_code=400,
            detail="Cannot delete user because they are referenced in change requests or history.",
        )
    return user
