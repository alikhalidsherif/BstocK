from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import crud, models, schemas, auth
from ..database import get_db

router = APIRouter(
    prefix="/api/vendors",
    tags=["vendors"],
)


@router.get("/", response_model=List[schemas.Vendor])
def list_vendors(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """List all vendors for the current organization."""
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    vendors = crud.get_vendors(
        db=db,
        organization_id=current_user.organization_id,
        skip=skip,
        limit=limit
    )
    return vendors


@router.post("/", response_model=schemas.Vendor, status_code=201)
def create_vendor(
    vendor: schemas.VendorCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """Create a new vendor (owner only)."""
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    db_vendor = crud.create_vendor(
        db=db,
        vendor=vendor,
        organization_id=current_user.organization_id
    )
    return db_vendor
