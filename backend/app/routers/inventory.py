from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import crud, models, schemas, auth
from ..database import get_db
from .users import get_current_active_user

router = APIRouter()

def get_admin_user(current_user: models.User = Depends(get_current_active_user)):
    if current_user.role != models.UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user does not have enough privileges"
        )
    return current_user

# The user submits a request using a barcode (ChangeRequestSubmit). We convert it internally to
# ChangeRequestCreate once we have the product_id.
@router.post("/inventory/request", response_model=schemas.ChangeRequest)
def request_inventory_change(
    request: schemas.ChangeRequestSubmit,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user),
):
    # Ensure product exists
    product = crud.get_product_by_barcode(db, barcode=request.barcode)
    if not product:
        raise HTTPException(status_code=404, detail=f"Product with barcode {request.barcode} not found")
    
    # Convert to internal schema
    change_request_data = schemas.ChangeRequestCreate(
        product_id=product.id,
        action=request.action,
        quantity_change=request.quantity_change,
        buyer_name=request.buyer_name,
        payment_status=request.payment_status,
    )

    return crud.create_change_request(db, change_request_data, current_user.id)

@router.get("/inventory/requests/pending", response_model=List[schemas.ChangeRequest])
def get_pending_requests(db: Session = Depends(get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    return crud.get_pending_change_requests(db)

@router.put("/inventory/requests/{request_id}/approve", response_model=schemas.ChangeHistory)
def approve_request(request_id: int, db: Session = Depends(get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    # Simple authorization: only admins/supervisors can approve.
    if current_user.role not in [models.UserRole.admin, models.UserRole.supervisor]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    try:
        approved_request = crud.approve_change_request(db, request_id=request_id, reviewer_id=current_user.id)
        if approved_request is None:
            raise HTTPException(status_code=404, detail="Request not found or not pending")
        return approved_request
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/inventory/requests/{request_id}/reject", response_model=schemas.ChangeHistory)
def reject_request(request_id: int, db: Session = Depends(get_db), current_user: schemas.User = Depends(auth.get_current_user)):
    # Simple authorization: only admins/supervisors can reject.
    if current_user.role not in [models.UserRole.admin, models.UserRole.supervisor]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    rejected_request = crud.reject_change_request(db, request_id=request_id, reviewer_id=current_user.id)
    if rejected_request is None:
        raise HTTPException(status_code=404, detail="Request not found or not pending")
    return rejected_request
