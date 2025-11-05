from io import BytesIO
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm

from .. import crud, models, auth
from ..database import get_db

router = APIRouter(
    prefix="/api/receipts",
    tags=["receipts"],
)


def _format_currency(value) -> str:
    return f"₦{value:,.2f}" if value is not None else "₦0.00"


def _draw_header(pdf: canvas.Canvas, organization: models.Organization, sale: models.Sale, y_position: float):
    pdf.setFont("Helvetica-Bold", 16)
    pdf.drawString(20 * mm, y_position, organization.name if organization else "Sale Receipt")
    
    pdf.setFont("Helvetica", 10)
    y_position -= 8 * mm
    pdf.drawString(20 * mm, y_position, f"Receipt ID: POS-{sale.id:06d}")
    y_position -= 6 * mm
    pdf.drawString(20 * mm, y_position, f"Date: {sale.created_at.strftime('%Y-%m-%d %H:%M')}" )
    y_position -= 6 * mm
    pdf.drawString(20 * mm, y_position, f"Cashier: {sale.cashier.username if sale.cashier else 'N/A'}")
    
    if sale.customer:
        y_position -= 6 * mm
        pdf.drawString(20 * mm, y_position, f"Customer: {sale.customer.name}")
        if sale.customer.phone:
            y_position -= 6 * mm
            pdf.drawString(20 * mm, y_position, f"Phone: {sale.customer.phone}")
    
    return y_position - 10 * mm


def _draw_table(pdf: canvas.Canvas, sale: models.Sale, y_position: float):
    pdf.setFont("Helvetica-Bold", 11)
    pdf.drawString(20 * mm, y_position, "Item")
    pdf.drawString(90 * mm, y_position, "Qty")
    pdf.drawString(110 * mm, y_position, "Price")
    pdf.drawString(140 * mm, y_position, "Total")
    
    y_position -= 7 * mm
    pdf.line(20 * mm, y_position + 2 * mm, 190 * mm, y_position + 2 * mm)
    
    pdf.setFont("Helvetica", 10)
    for item in sale.items:
        product_name = item.variant.product.name if item.variant and item.variant.product else "Item"
        attributes = item.variant.attributes if item.variant else None
        attribute_text = ", ".join(f"{k}: {v}" for k, v in attributes.items()) if attributes else ""
        line_text = f"{product_name} ({attribute_text})" if attribute_text else product_name
        
        pdf.drawString(20 * mm, y_position, line_text[:60])
        pdf.drawString(90 * mm, y_position, str(item.quantity))
        pdf.drawString(110 * mm, y_position, _format_currency(item.price_at_sale))
        pdf.drawString(140 * mm, y_position, _format_currency(item.price_at_sale * item.quantity))
        y_position -= 6 * mm
        
        if y_position < 40 * mm:
            pdf.showPage()
            y_position = 270
            pdf.setFont("Helvetica", 10)
    
    return y_position - 5 * mm


def _draw_totals(pdf: canvas.Canvas, sale: models.Sale, y_position: float):
    pdf.setFont("Helvetica-Bold", 11)
    pdf.drawString(20 * mm, y_position, "Summary")
    y_position -= 7 * mm
    pdf.setFont("Helvetica", 10)
    
    pdf.drawString(20 * mm, y_position, "Subtotal:")
    pdf.drawRightString(190 * mm, y_position, _format_currency(sale.subtotal))
    y_position -= 6 * mm
    
    if sale.tax and sale.tax > 0:
        pdf.drawString(20 * mm, y_position, "Tax:")
        pdf.drawRightString(190 * mm, y_position, _format_currency(sale.tax))
        y_position -= 6 * mm
    
    if sale.discount and sale.discount > 0:
        pdf.drawString(20 * mm, y_position, "Discount:")
        pdf.drawRightString(190 * mm, y_position, _format_currency(sale.discount))
        y_position -= 6 * mm
    
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(20 * mm, y_position, "Total:")
    pdf.drawRightString(190 * mm, y_position, _format_currency(sale.total_amount))
    
    y_position -= 10 * mm
    pdf.setFont("Helvetica", 10)
    pdf.drawString(20 * mm, y_position, f"Payment Method: {sale.payment_method.value.title()}")
    
    if sale.notes:
        y_position -= 6 * mm
        pdf.drawString(20 * mm, y_position, f"Notes: {sale.notes}")
    
    return y_position


@router.get("/{sale_id}/pdf")
def download_receipt(
    sale_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Generate a PDF receipt for the given sale.
    Fetches sale details, formats them into a clean layout, and returns a PDF file.
    """
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
    
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4)
    pdf.setTitle(f"POS Receipt {sale.id}")
    
    y_position = 280
    organization = sale.organization if hasattr(sale, 'organization') else None
    y_position = _draw_header(pdf, organization, sale, y_position)
    y_position = _draw_table(pdf, sale, y_position)
    _draw_totals(pdf, sale, y_position)
    
    pdf.showPage()
    pdf.save()
    buffer.seek(0)
    
    filename = f"receipt_{sale.id}.pdf"
    headers = {
        "Content-Disposition": f"inline; filename={filename}"
    }
    return StreamingResponse(buffer, media_type="application/pdf", headers=headers)
