from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session, joinedload
from typing import List
import pandas as pd
import io

from .. import crud, schemas, models, auth
from ..database import get_db

router = APIRouter(
    prefix="/api/history",
    tags=["history"],
)

@router.get("/", response_model=List[schemas.ChangeHistory])
def read_change_history(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin_or_supervisor),
):
    history = crud.get_change_history(db, skip=skip, limit=limit)
    return history 

@router.get("/sales", response_model=List[schemas.ChangeHistory])
def read_sales_history(
    skip: int = 0,
    limit: int = 1000,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin_or_supervisor),
):
    """Get only sales transactions from history"""
    sales_history = crud.get_sales_history(db, skip=skip, limit=limit)
    return sales_history

@router.get("/unpaid", response_model=List[schemas.ChangeHistory])
def read_unpaid_sales(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin_or_supervisor),
):
    """Get all sales with an 'unpaid' status."""
    unpaid_sales = db.query(models.ChangeHistory).options(
        joinedload(models.ChangeHistory.product),
        joinedload(models.ChangeHistory.requester),
        joinedload(models.ChangeHistory.reviewer)
    ).filter(
        models.ChangeHistory.action == models.ChangeRequestAction.sell,
        models.ChangeHistory.payment_status == models.PaymentStatus.unpaid,
        models.ChangeHistory.product_id.isnot(None)
    ).order_by(models.ChangeHistory.timestamp.desc()).offset(skip).limit(limit).all()
    return unpaid_sales


@router.get("/sales/export", response_class=StreamingResponse)
def export_sales_to_excel(
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(auth.get_current_admin_or_supervisor_for_export)
):
    """Export sales data to Excel file"""
    sales_only = crud.get_sales_history(db, skip=0, limit=10000) # Use the new function
    
    if not sales_only:
        raise HTTPException(status_code=404, detail="No sales found to export.")
    
    sales_data = []
    for sale in sales_only:
        sales_data.append({
            "Date": sale.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            "Product_Name": sale.product.name if sale.product else "N/A",
            "Barcode": sale.product.barcode if sale.product else "N/A",
            "Quantity_Sold": abs(sale.quantity_change) if sale.quantity_change else 0,
            "Price_Per_Unit": sale.product.price if sale.product else 0,
            "Total_Amount": (abs(sale.quantity_change) * sale.product.price) if (sale.quantity_change and sale.product) else 0,
            "Buyer_Name": sale.buyer_name or "N/A",
            "Payment_Status": sale.payment_status.value if sale.payment_status else "N/A",
            "Seller": sale.requester.username,
            "Approved_By": sale.reviewer.username,
        })
    
    df = pd.DataFrame(sales_data)
    
    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='Sales')
    output.seek(0)
    
    return StreamingResponse(
        output,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=BstocK_Sales.xlsx"}
    ) 