from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import crud, models, schemas, auth
from ..database import get_db

router = APIRouter(
    prefix="/api/pos",
    tags=["pos"],
)


@router.post("/sales", response_model=schemas.Sale, status_code=201)
def create_sale(
    sale_data: schemas.SaleCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Create a new sale transaction.
    This endpoint performs the entire transaction atomically:
    - Verifies sufficient stock for all items
    - Calculates total sale amount and profit
    - Creates a new record in the Sales table
    - Creates corresponding records in the SaleItems table
    - Decrements the quantity for each Variant sold
    - Returns the final sale details, including a sale_id
    """
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    try:
        db_sale = crud.create_sale(
            db=db,
            sale_data=sale_data,
            organization_id=current_user.organization_id,
            cashier_id=current_user.id
        )
        return db_sale
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/sales", response_model=List[schemas.Sale])
def get_sales(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get all sales for the current organization"""
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    sales = crud.get_sales(
        db=db,
        organization_id=current_user.organization_id,
        skip=skip,
        limit=limit
    )
    return sales


@router.get("/sales/{sale_id}", response_model=schemas.SaleWithDetails)
def get_sale(
    sale_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get a specific sale with full details"""
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    sale = crud.get_sale_by_id(
        db=db,
        sale_id=sale_id,
        organization_id=current_user.organization_id
    )
    
    if not sale:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sale not found"
        )
    
    return sale
