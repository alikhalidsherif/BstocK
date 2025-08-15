import pandas as pd
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
import io
from typing import List, Union

from .. import crud, models, schemas
from ..events import hub
from ..database import get_db
from .. import auth

router = APIRouter(
    prefix="/api/products",
    tags=["products"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=List[schemas.Product], status_code=201)
def create_products(
    products: Union[schemas.ProductCreate, List[schemas.ProductCreate]], 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(auth.get_current_active_user)
):
    if not isinstance(products, list):
        products = [products]

    created_products_models = []
    for product_data in products:
        db_product = crud.get_product_by_barcode(db, barcode=product_data.barcode)
        if db_product:
            raise HTTPException(
                status_code=409, 
                detail=f"Product with barcode {product_data.barcode} already registered."
            )
        created_product = crud.create_product(db=db, product=product_data)
        created_products_models.append(created_product)

    db.commit()
    for model in created_products_models:
        db.refresh(model)
        
    return created_products_models

@router.get("/", response_model=List[schemas.Product])
def read_products(
    skip: int = 0, 
    limit: int = 100, 
    include_archived: bool = False,
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(auth.get_current_active_user)
):
    products = crud.get_products(db, skip=skip, limit=limit, include_archived=include_archived)
    return products

@router.get("/categories", response_model=List[str])
def read_product_categories(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    categories = crud.get_product_categories(db)
    return [category[0] for category in categories]

@router.get("/export", response_class=StreamingResponse)
def export_products_to_excel(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_admin_or_supervisor_for_export)):
    """
    Export all products to an Excel file.
    """
    products = crud.get_products(db, skip=0, limit=10000)
    if not products:
        raise HTTPException(status_code=404, detail="No products found to export.")

    products_data = [{"ID": p.id, "Barcode": p.barcode, "Name": p.name, "Price": p.price, "Quantity": p.quantity, "Category": p.category} for p in products]
    df = pd.DataFrame(products_data)

    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='Products')
    output.seek(0)

    return StreamingResponse(
        output,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=BstocK_Products.xlsx"}
    )

@router.get("/{barcode}", response_model=schemas.Product)
def read_product(
    barcode: str, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(auth.get_current_active_user)
):
    db_product = crud.get_product_by_barcode(db, barcode=barcode)
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return db_product

@router.post("/import", response_model=dict)
def import_products_from_excel(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin)
):
    """
    Import products from Excel file. Auto-detects column headers.
    Supports columns: Barcode, Name, Price, Quantity, Category (case-insensitive)
    """
    if not file.filename.endswith(('.xlsx', '.xls')):
        raise HTTPException(status_code=400, detail="File must be Excel format (.xlsx or .xls)")
    
    try:
        # Read Excel file
        contents = file.file.read()
        df = pd.read_excel(io.BytesIO(contents))
        
        # Normalize column names (case-insensitive matching)
        df.columns = df.columns.str.strip().str.lower()
        
        # Column mapping - flexible header detection
        column_mapping = {}
        required_fields = ['barcode', 'name', 'price', 'quantity', 'category']
        
        for col in df.columns:
            if 'barcode' in col or 'code' in col:
                column_mapping['barcode'] = col
            elif 'name' in col or 'product' in col or 'title' in col:
                column_mapping['name'] = col
            elif 'price' in col or 'cost' in col:
                column_mapping['price'] = col
            elif 'quantity' in col or 'qty' in col or 'stock' in col:
                column_mapping['quantity'] = col
            elif 'category' in col or 'type' in col or 'group' in col:
                column_mapping['category'] = col
        
        # Check if we found all required columns
        missing_fields = [field for field in required_fields if field not in column_mapping]
        if missing_fields:
            available_cols = list(df.columns)
            raise HTTPException(
                status_code=400, 
                detail=f"Could not detect columns for: {missing_fields}. Available columns: {available_cols}"
            )
        
        # Process rows
        created_count = 0
        updated_count = 0
        errors = []
        
        for index, row in df.iterrows():
            try:
                barcode = str(row[column_mapping['barcode']])
                name = str(row[column_mapping['name']])
                price = float(row[column_mapping['price']])
                quantity = int(row[column_mapping['quantity']])
                category = str(row[column_mapping['category']])
                
                # Check if product exists
                existing_product = crud.get_product_by_barcode(db, barcode=barcode)
                
                if existing_product:
                    # Update existing product
                    product_update = schemas.ProductCreate(
                        barcode=barcode, name=name, price=price, 
                        quantity=quantity, category=category
                    )
                    crud.update_product(db=db, product=existing_product, product_in=product_update)
                    updated_count += 1
                else:
                    # Create new product
                    product_create = schemas.ProductCreate(
                        barcode=barcode, name=name, price=price,
                        quantity=quantity, category=category
                    )
                    crud.create_product(db=db, product=product_create)
                    created_count += 1
                    
            except Exception as e:
                errors.append(f"Row {index + 2}: {str(e)}")
        
        db.commit()
        
        return {
            "message": "Import completed",
            "created": created_count,
            "updated": updated_count,
            "errors": errors,
            "detected_columns": column_mapping
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to process Excel file: {str(e)}")

@router.put("/{product_id}", response_model=schemas.Product)
def update_product_details(
    product_id: int,
    product_in: schemas.ProductCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    if product_in.barcode != product.barcode:
        existing_product = crud.get_product_by_barcode(db, barcode=product_in.barcode)
        if existing_product:
            raise HTTPException(
                status_code=409,
                detail=f"Another product with barcode {product_in.barcode} already exists."
            )

    product = crud.update_product(db=db, product=product, product_in=product_in)
    return product

@router.delete("/{product_id}", response_model=schemas.Product)
def remove_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    # Log to history as an approved admin delete before removing the product
    history_entry = models.ChangeHistory(
        product_id=product.id,
        quantity_change=None,
        action=models.ChangeRequestAction.delete,
        status=models.ChangeRequestStatus.approved,
        requester_id=current_user.id,
        reviewer_id=current_user.id,
    )
    db.add(history_entry)
    db.commit()

    crud.delete_product(db=db, product=product)
    # Broadcast so clients refresh
    hub.publish_from_thread({"type": "product.updated", "product_id": product_id})
    hub.publish_from_thread({"type": "history.updated"})
    return product

@router.post("/{product_id}/archive", response_model=schemas.Product)
def archive_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return crud.archive_product(db=db, product=product)

@router.post("/{product_id}/unarchive", response_model=schemas.Product)
def unarchive_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_admin)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return crud.unarchive_product(db=db, product=product)
