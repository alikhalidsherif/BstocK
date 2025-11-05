from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import crud, models, schemas, auth
from ..database import get_db

router = APIRouter(
    prefix="/api/products",
    tags=["products"],
)


@router.post("/", response_model=schemas.Product, status_code=201)
def create_product(
    product: schemas.ProductCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """
    Create a new product with multiple variants in a single request.
    Only organization owners can create new products.
    """
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    # Ensure SKU uniqueness within the organization
    for variant in product.variants:
        existing_variant = crud.get_variant_by_sku(
            db=db,
            sku=variant.sku,
            organization_id=current_user.organization_id
        )
        if existing_variant:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Variant with SKU {variant.sku} already exists"
            )
        if variant.barcode:
            existing_barcode = crud.get_variant_by_barcode(
                db=db,
                barcode=variant.barcode,
                organization_id=current_user.organization_id
            )
            if existing_barcode:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Variant with barcode {variant.barcode} already exists"
                )
    
    db_product = crud.create_product_with_variants(
        db=db,
        product=product,
        organization_id=current_user.organization_id
    )
    return db_product


@router.get("/", response_model=List[schemas.Product])
def list_products(
    skip: int = 0,
    limit: int = 100,
    include_archived: bool = False,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """List products for the current organization."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    products = crud.get_products(
        db=db,
        organization_id=current_user.organization_id,
        skip=skip,
        limit=limit,
        include_archived=include_archived
    )
    return products


@router.get("/{product_id}", response_model=schemas.Product)
def get_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get a product by ID with all variants."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    product = crud.get_product_by_id(
        db=db,
        product_id=product_id,
        organization_id=current_user.organization_id
    )
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product


@router.put("/{product_id}", response_model=schemas.Product)
def update_product(
    product_id: int,
    product_in: schemas.ProductUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """
    Update a product's details.
    Only owners can update products.
    """
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    product = crud.get_product_by_id(
        db=db,
        product_id=product_id,
        organization_id=current_user.organization_id
    )
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    updated_product = crud.update_product(db=db, product=product, product_in=product_in)
    return updated_product


@router.post("/{product_id}/variants", response_model=schemas.Variant, status_code=201)
def create_variant(
    product_id: int,
    variant: schemas.VariantCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """
    Add a new variant to an existing product.
    Only owners can add variants.
    """
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    product = crud.get_product_by_id(
        db=db,
        product_id=product_id,
        organization_id=current_user.organization_id
    )
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    
    existing_variant = crud.get_variant_by_sku(
        db=db,
        sku=variant.sku,
        organization_id=current_user.organization_id
    )
    if existing_variant:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Variant with this SKU already exists")
    
    if variant.barcode:
        existing_barcode = crud.get_variant_by_barcode(
            db=db,
            barcode=variant.barcode,
            organization_id=current_user.organization_id
        )
        if existing_barcode:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Variant with this barcode already exists")
    
    db_variant = crud.create_variant(db=db, variant=variant, product_id=product.id)
    return db_variant


@router.put("/variants/{variant_id}", response_model=schemas.Variant)
def update_variant(
    variant_id: int,
    variant_in: schemas.VariantUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_owner)
):
    """
    Update a variant's details.
    Only owners can update variants.
    """
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    variant = crud.get_variant_by_id(
        db=db,
        variant_id=variant_id,
        organization_id=current_user.organization_id
    )
    if not variant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Variant not found")
    
    if variant_in.sku and variant_in.sku != variant.sku:
        existing_variant = crud.get_variant_by_sku(
            db=db,
            sku=variant_in.sku,
            organization_id=current_user.organization_id
        )
        if existing_variant:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Variant with this SKU already exists")
    
    if variant_in.barcode and variant_in.barcode != variant.barcode:
        existing_barcode = crud.get_variant_by_barcode(
            db=db,
            barcode=variant_in.barcode,
            organization_id=current_user.organization_id
        )
        if existing_barcode:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Variant with this barcode already exists")
    
    updated_variant = crud.update_variant(db=db, variant=variant, variant_in=variant_in)
    return updated_variant


@router.get("/categories", response_model=List[str])
def get_categories(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get distinct product categories for the current organization."""
    if not current_user.organization_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User not associated with any organization")
    categories = crud.get_product_categories(db=db, organization_id=current_user.organization_id)
    return [category[0] for category in categories if category[0]]
