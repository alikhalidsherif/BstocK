from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from .. import crud, schemas, auth, models
from ..database import get_db

router = APIRouter()

@router.get("/history/", response_model=List[schemas.ChangeHistory])
def read_change_history(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    if current_user.role not in [models.UserRole.admin, models.UserRole.supervisor]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    history = crud.get_change_history(db, skip=skip, limit=limit)
    return history 