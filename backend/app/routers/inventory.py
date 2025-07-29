from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import crud, models, schemas
from ..schemas import ChangeRequestAction
from ..database import get_db
from ..auth import get_current_active_user, get_current_active_admin

router = APIRouter(
    prefix="/api/inventory",
    tags=["inventory"],
)

# The user submits a request using a barcode (ChangeRequestSubmit). We convert it internally to
# ChangeRequestCreate once we have the product_id.
@router.post("/request", response_model=schemas.ChangeRequest)
def request_inventory_change(
    request: schemas.ChangeRequestSubmit,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user),
):
    product_id: int | None = None
    if request.action not in [ChangeRequestAction.create, ChangeRequestAction.mark_paid]:
        if not request.barcode:
            raise HTTPException(status_code=400, detail="Barcode is required for this action")
        
        product = None
        if request.action == ChangeRequestAction.delete:
            # For delete, the barcode field actually contains the product ID
            product = crud.get_product_by_id(db, product_id=int(request.barcode))
        else:
            product = crud.get_product_by_barcode(db, barcode=request.barcode)

        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        product_id = product.id
    elif request.action == ChangeRequestAction.create:
        # For create action, validate that barcode doesn't already exist and no pending request exists
        if request.new_product_barcode:
            existing_product = crud.get_product_by_barcode(db, barcode=request.new_product_barcode)
            if existing_product:
                raise HTTPException(status_code=400, detail="A product with this barcode already exists")
            
            has_pending = crud.has_pending_product_creation_request(db, barcode=request.new_product_barcode)
            if has_pending:
                raise HTTPException(status_code=400, detail="A request to create a product with this barcode is already pending")
    elif request.action == ChangeRequestAction.mark_paid:
        # For markPaid, the barcode field contains the history entry ID
        if not request.barcode:
            raise HTTPException(status_code=400, detail="History ID is required for mark paid action")
        
        try:
            history_id = int(request.barcode)
            history_entry = db.query(models.ChangeHistory).filter(models.ChangeHistory.id == history_id).first()
            if not history_entry:
                raise HTTPException(status_code=404, detail="Transaction not found")
            if history_entry.payment_status == models.PaymentStatus.paid:
                raise HTTPException(status_code=400, detail="Transaction is already marked as paid")
            
            product_id = history_entry.product_id
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid history ID")
    
    # Convert to internal schema
    change_request_data = schemas.ChangeRequestCreate(
        product_id=product_id,
        action=request.action,
        quantity_change=request.quantity_change,
        buyer_name=request.buyer_name,
        payment_status=request.payment_status,
        new_product_name=request.new_product_name,
        new_product_barcode=request.new_product_barcode,
        new_product_price=request.new_product_price,
        new_product_quantity=request.new_product_quantity,
        new_product_category=request.new_product_category,
    )

    return crud.create_change_request(db, change_request_data, current_user.id)

@router.get("/requests/pending", response_model=List[schemas.ChangeRequest])
def get_pending_requests(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_user),
):
    return crud.get_pending_change_requests(db)

@router.put("/requests/{request_id}/approve", response_model=schemas.ChangeHistory)
def approve_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_admin),
):
    # authorization now via get_current_active_admin
    try:
        approved_request = crud.approve_change_request(db, request_id=request_id, reviewer_id=current_user.id)
        if approved_request is None:
            raise HTTPException(status_code=404, detail="Request not found or not pending")
        return approved_request
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/requests/{request_id}/reject", response_model=schemas.ChangeHistory)
def reject_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_admin),
):
    # authorization now via get_current_active_admin
    rejected_request = crud.reject_change_request(db, request_id=request_id, reviewer_id=current_user.id)
    if rejected_request is None:
        raise HTTPException(status_code=404, detail="Request not found or not pending")
    return rejected_request
