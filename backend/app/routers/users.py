from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import auth, crud, models, schemas
from ..database import get_db

router = APIRouter(
    prefix="/api/users",
    tags=["users"],
)


@router.get("/", response_model=List[schemas.User])
def list_users(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """List all users in the current organization (owner only)."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    users = crud.get_users(
        db=db,
        organization_id=current_user.organization_id
    )
    return users


@router.post("/", response_model=schemas.User, status_code=201)
def create_user(
    user_in: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """Create a new user (cashier or owner) within the current organization."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    
    if user_in.organization_id and user_in.organization_id != current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot create users for another organization")
    
    existing_user = crud.get_user_by_username(
        db=db,
        username=user_in.username,
        organization_id=current_user.organization_id
    )
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already exists in this organization")
    
    hashed_password = auth.get_password_hash(user_in.password)
    db_user = crud.create_user(
        db=db,
        user=schemas.UserCreate(
            username=user_in.username,
            password=user_in.password,
            role=user_in.role,
            organization_id=current_user.organization_id
        ),
        hashed_password=hashed_password
    )
    return db_user


@router.patch("/{user_id}", response_model=schemas.User)
def update_user(
    user_id: int,
    user_update: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """Update a user's role or active status (owner only)."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    
    user = crud.get_user_by_id(db=db, user_id=user_id)
    if not user or user.organization_id != current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    if user.id == current_user.id and user_update.role and user_update.role != user.role:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot change your own role")
    
    updated_user = crud.update_user(db=db, user=user, user_in=user_update)
    return updated_user


@router.delete("/{user_id}", response_model=schemas.User)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """Delete a user from the organization (owner only)."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    
    user = crud.get_user_by_id(db=db, user_id=user_id)
    if not user or user.organization_id != current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    if user.id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot delete yourself")
    
    deleted_user = crud.delete_user(db=db, user=user)
    return deleted_user
