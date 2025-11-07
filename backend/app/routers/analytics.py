from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

from .. import crud, models, schemas, auth
from ..database import get_db

router = APIRouter(
    prefix="/api/analytics",
    tags=["analytics"],
)


@router.get("/summary", response_model=schemas.AnalyticsSummary)
def get_analytics_summary(
    start_date: Optional[datetime] = Query(None, description="Start date for analytics period"),
    end_date: Optional[datetime] = Query(None, description="End date for analytics period"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Get sales analytics summary for the organization.
    Takes start_date and end_date as query parameters.
    Returns total_revenue, total_profit, and a list of best_selling_variants.
    """
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    analytics = crud.get_sales_analytics(
        db=db,
        organization_id=current_user.organization_id,
        start_date=start_date,
        end_date=end_date
    )
    
    best_selling_variants = [
        schemas.BestSellingVariant(
            variant_id=item.id,
            sku=item.sku,
            product_name=item.name,
            total_quantity_sold=item.total_quantity,
            total_revenue=item.total_revenue
        )
        for item in analytics['best_sellers']
    ]
    
    return schemas.AnalyticsSummary(
        total_revenue=analytics['total_revenue'],
        total_profit=analytics['total_profit'],
        total_sales_count=analytics['total_sales_count'],
        best_selling_variants=best_selling_variants
    )
