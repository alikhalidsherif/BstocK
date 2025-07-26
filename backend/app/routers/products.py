from typing import List, Union
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import crud, models, schemas
from ..database import get_db
from .users import get_current_active_user, get_current_active_admin

router = APIRouter()

@router.get("/products/categories", response_model=List[str])
def read_product_categories(db: Session = Depends(get_db)):
    categories = crud.get_product_categories(db)
    # The query returns a list of tuples, so we extract the first element of each tuple
    return [category[0] for category in categories]

@router.post("/products/", response_model=List[schemas.Product], status_code=status.HTTP_201_CREATED)
def create_products(
    products: Union[schemas.ProductCreate, List[schemas.ProductCreate]], 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_active_user)
):
    if not isinstance(products, list):
        products = [products]

    created_products_models = []
    for product_data in products:
        db_product = crud.get_product_by_barcode(db, barcode=product_data.barcode)
        if db_product:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, 
                detail=f"Product with barcode {product_data.barcode} already registered."
            )
        # Create the model instance but don't commit yet
        created_product = crud.create_product(db=db, product=product_data)
        created_products_models.append(created_product)

    # Now, commit all the new products to the database in one transaction
    db.commit()

    # Refresh each model to get the data from the DB (like the new ID)
    for model in created_products_models:
        db.refresh(model)
        
    return created_products_models

@router.get("/products/", response_model=List[schemas.Product])
def read_products(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_active_user)
):
    products = crud.get_products(db, skip=skip, limit=limit)
    return products

@router.get("/products/{barcode}", response_model=schemas.Product)
def read_product(
    barcode: str, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_active_user)
):
    db_product = crud.get_product_by_barcode(db, barcode=barcode)
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return db_product

@router.put("/products/{product_id}", response_model=schemas.Product)
def update_product_details(
    product_id: int,
    product_in: schemas.ProductCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_admin)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check if the updated barcode already exists in another product
    if product_in.barcode != product.barcode:
        existing_product = crud.get_product_by_barcode(db, barcode=product_in.barcode)
        if existing_product:
            raise HTTPException(
                status_code=409,
                detail=f"Another product with barcode {product_in.barcode} already exists."
            )

    product = crud.update_product(db=db, product=product, product_in=product_in)
    return product

@router.delete("/products/{product_id}", response_model=schemas.Product)
def remove_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_active_admin)
):
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    crud.delete_product(db=db, product=product)
    return product
