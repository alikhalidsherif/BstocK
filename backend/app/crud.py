from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, desc
from . import models, schemas
from datetime import datetime
from decimal import Decimal
from typing import Optional

# ============================================================================
# USER CRUD
# ============================================================================

def get_user_by_username(db: Session, username: str, organization_id: Optional[int] = None):
    query = db.query(models.User).filter(models.User.username == username)
    if organization_id is not None:
        query = query.filter(models.User.organization_id == organization_id)
    return query.first()


def get_user_by_id(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_users(db: Session, organization_id: int, skip: int = 0, limit: int = 100):
    """Get all users for a specific organization"""
    return db.query(models.User).filter(
        models.User.organization_id == organization_id
    ).offset(skip).limit(limit).all()


def create_user(db: Session, user: schemas.UserCreate, hashed_password: str):
    db_user = models.User(
        username=user.username,
        hashed_password=hashed_password,
        role=user.role,
        organization_id=user.organization_id
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user: models.User, user_in: schemas.UserUpdate):
    update_data = user_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def delete_user(db: Session, user: models.User):
    db.delete(user)
    db.commit()
    return user


# ============================================================================
# ORGANIZATION CRUD
# ============================================================================

def create_organization(db: Session, org: schemas.OrganizationCreate, owner_id: Optional[int] = None):
    """Create a new organization"""
    db_org = models.Organization(
        name=org.name,
        owner_id=owner_id
    )
    db.add(db_org)
    db.commit()
    db.refresh(db_org)
    return db_org


def get_organization_by_id(db: Session, org_id: int):
    return db.query(models.Organization).filter(models.Organization.id == org_id).first()


# ============================================================================
# PRODUCT & VARIANT CRUD
# ============================================================================

def get_products(db: Session, organization_id: int, skip: int = 0, limit: int = 100, include_archived: bool = False):
    """Get all products for an organization with their variants"""
    query = db.query(models.Product).options(
        joinedload(models.Product.variants)
    ).filter(models.Product.organization_id == organization_id)
    
    if not include_archived:
        query = query.filter(models.Product.is_archived == False)
    
    return query.offset(skip).limit(limit).all()


def get_product_by_id(db: Session, product_id: int, organization_id: int):
    """Get a product by ID, ensuring it belongs to the organization"""
    return db.query(models.Product).options(
        joinedload(models.Product.variants)
    ).filter(
        models.Product.id == product_id,
        models.Product.organization_id == organization_id
    ).first()


def create_product_with_variants(
    db: Session,
    product: schemas.ProductCreate,
    organization_id: int
) -> models.Product:
    """Create a product with its variants"""
    db_product = models.Product(
        name=product.name,
        description=product.description,
        category=product.category,
        organization_id=organization_id
    )
    db.add(db_product)
    db.flush()
    
    for variant_data in product.variants:
        db_variant = models.Variant(
            product_id=db_product.id,
            sku=variant_data.sku,
            barcode=variant_data.barcode,
            attributes=variant_data.attributes,
            purchase_price=variant_data.purchase_price,
            sale_price=variant_data.sale_price,
            quantity=variant_data.quantity,
            min_stock_level=variant_data.min_stock_level,
            unit_type=variant_data.unit_type,
            is_active=variant_data.is_active
        )
        db.add(db_variant)
    
    db.commit()
    db.refresh(db_product)
    return db_product


def update_product(db: Session, product: models.Product, product_in: schemas.ProductUpdate):
    """Update product details"""
    update_data = product_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


def get_product_categories(db: Session, organization_id: int):
    """Get distinct categories for an organization"""
    return db.query(models.Product.category).filter(
        models.Product.organization_id == organization_id,
        models.Product.category.isnot(None)
    ).distinct().all()


# ============================================================================
# VARIANT CRUD
# ============================================================================

def get_variant_by_id(db: Session, variant_id: int, organization_id: int):
    """Get a variant by ID, ensuring it belongs to the organization"""
    return db.query(models.Variant).join(models.Product).filter(
        models.Variant.id == variant_id,
        models.Product.organization_id == organization_id
    ).first()


def get_variant_by_barcode(db: Session, barcode: str, organization_id: int):
    """Get a variant by barcode, ensuring it belongs to the organization"""
    return db.query(models.Variant).join(models.Product).filter(
        models.Variant.barcode == barcode,
        models.Product.organization_id == organization_id
    ).first()


def get_variant_by_sku(db: Session, sku: str, organization_id: int):
    """Get a variant by SKU, ensuring it belongs to the organization"""
    return db.query(models.Variant).join(models.Product).filter(
        models.Variant.sku == sku,
        models.Product.organization_id == organization_id
    ).first()


def update_variant(db: Session, variant: models.Variant, variant_in: schemas.VariantUpdate):
    """Update variant details"""
    update_data = variant_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(variant, field, value)
    db.add(variant)
    db.commit()
    db.refresh(variant)
    return variant


def create_variant(db: Session, variant: schemas.VariantCreate, product_id: int):
    """Create a new variant for an existing product"""
    db_variant = models.Variant(
        product_id=product_id,
        sku=variant.sku,
        barcode=variant.barcode,
        attributes=variant.attributes,
        purchase_price=variant.purchase_price,
        sale_price=variant.sale_price,
        quantity=variant.quantity,
        min_stock_level=variant.min_stock_level,
        unit_type=variant.unit_type,
        is_active=variant.is_active
    )
    db.add(db_variant)
    db.commit()
    db.refresh(db_variant)
    return db_variant


def get_low_stock_variants(db: Session, organization_id: int):
    """Get variants that are below their minimum stock level"""
    return db.query(models.Variant).join(models.Product).filter(
        models.Product.organization_id == organization_id,
        models.Variant.quantity <= models.Variant.min_stock_level,
        models.Variant.is_active == True
    ).all()


# ============================================================================
# CUSTOMER CRUD
# ============================================================================

def get_customers(db: Session, organization_id: int, skip: int = 0, limit: int = 100):
    """Get all customers for an organization"""
    return db.query(models.Customer).filter(
        models.Customer.organization_id == organization_id
    ).offset(skip).limit(limit).all()


def get_customer_by_id(db: Session, customer_id: int, organization_id: int):
    """Get a customer by ID, ensuring it belongs to the organization"""
    return db.query(models.Customer).filter(
        models.Customer.id == customer_id,
        models.Customer.organization_id == organization_id
    ).first()


def create_customer(db: Session, customer: schemas.CustomerCreate, organization_id: int):
    """Create a new customer"""
    db_customer = models.Customer(
        name=customer.name,
        phone=customer.phone,
        email=customer.email,
        address=customer.address,
        organization_id=organization_id
    )
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer


# ============================================================================
# VENDOR CRUD
# ============================================================================

def get_vendors(db: Session, organization_id: int, skip: int = 0, limit: int = 100):
    """Get all vendors for an organization"""
    return db.query(models.Vendor).filter(
        models.Vendor.organization_id == organization_id
    ).offset(skip).limit(limit).all()


def create_vendor(db: Session, vendor: schemas.VendorCreate, organization_id: int):
    """Create a new vendor"""
    db_vendor = models.Vendor(
        name=vendor.name,
        contact_person=vendor.contact_person,
        phone=vendor.phone,
        email=vendor.email,
        address=vendor.address,
        organization_id=organization_id
    )
    db.add(db_vendor)
    db.commit()
    db.refresh(db_vendor)
    return db_vendor


# ============================================================================
# SALES CRUD
# ============================================================================

def create_sale(
    db: Session,
    sale_data: schemas.SaleCreate,
    organization_id: int,
    cashier_id: int
) -> models.Sale:
    """
    Create a new sale transaction atomically.
    Verifies stock, calculates totals, creates sale and items, and updates inventory.
    """
    items_data = []
    subtotal = Decimal('0')
    total_profit = Decimal('0')
    
    for item_input in sale_data.items:
        variant = db.query(models.Variant).join(models.Product).filter(
            models.Variant.id == item_input.variant_id,
            models.Product.organization_id == organization_id
        ).first()
        
        if not variant:
            raise ValueError(f"Variant {item_input.variant_id} not found")
        
        if variant.quantity < item_input.quantity:
            raise ValueError(
                f"Insufficient stock for {variant.sku}. "
                f"Available: {variant.quantity}, Requested: {item_input.quantity}"
            )
        
        item_total = variant.sale_price * item_input.quantity
        item_profit = (variant.sale_price - variant.purchase_price) * item_input.quantity
        
        items_data.append({
            'variant': variant,
            'quantity': item_input.quantity,
            'price_at_sale': variant.sale_price,
            'purchase_price_at_sale': variant.purchase_price,
            'item_total': item_total,
            'item_profit': item_profit
        })
        
        subtotal += item_total
        total_profit += item_profit
    
    total_amount = subtotal + sale_data.tax - sale_data.discount
    
    db_sale = models.Sale(
        organization_id=organization_id,
        cashier_id=cashier_id,
        customer_id=sale_data.customer_id,
        subtotal=subtotal,
        tax=sale_data.tax,
        discount=sale_data.discount,
        total_amount=total_amount,
        profit=total_profit,
        payment_method=sale_data.payment_method,
        notes=sale_data.notes,
        synced=True
    )
    db.add(db_sale)
    db.flush()
    
    for item_data in items_data:
        db_sale_item = models.SaleItem(
            sale_id=db_sale.id,
            variant_id=item_data['variant'].id,
            quantity=item_data['quantity'],
            price_at_sale=item_data['price_at_sale'],
            purchase_price_at_sale=item_data['purchase_price_at_sale']
        )
        db.add(db_sale_item)
        
        item_data['variant'].quantity -= item_data['quantity']
        db.add(item_data['variant'])
    
    db.commit()
    db.refresh(db_sale)
    return db_sale


def get_sales(
    db: Session,
    organization_id: int,
    skip: int = 0,
    limit: int = 100,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
):
    """Get sales for an organization with optional date filtering"""
    query = db.query(models.Sale).options(
        joinedload(models.Sale.items).joinedload(models.SaleItem.variant),
        joinedload(models.Sale.cashier),
        joinedload(models.Sale.customer)
    ).filter(models.Sale.organization_id == organization_id)
    
    if start_date:
        query = query.filter(models.Sale.created_at >= start_date)
    if end_date:
        query = query.filter(models.Sale.created_at <= end_date)
    
    return query.order_by(desc(models.Sale.created_at)).offset(skip).limit(limit).all()


def get_sale_by_id(db: Session, sale_id: int, organization_id: int):
    """Get a sale by ID with all details"""
    return db.query(models.Sale).options(
        joinedload(models.Sale.items).joinedload(models.SaleItem.variant).joinedload(models.Variant.product),
        joinedload(models.Sale.cashier),
        joinedload(models.Sale.customer)
    ).filter(
        models.Sale.id == sale_id,
        models.Sale.organization_id == organization_id
    ).first()


def get_sales_analytics(
    db: Session,
    organization_id: int,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
):
    """Get sales analytics for an organization"""
    query = db.query(
        func.sum(models.Sale.total_amount).label('total_revenue'),
        func.sum(models.Sale.profit).label('total_profit'),
        func.count(models.Sale.id).label('total_sales')
    ).filter(models.Sale.organization_id == organization_id)
    
    if start_date:
        query = query.filter(models.Sale.created_at >= start_date)
    if end_date:
        query = query.filter(models.Sale.created_at <= end_date)
    
    result = query.first()
    
    best_sellers = db.query(
        models.Variant.id,
        models.Variant.sku,
        models.Product.name,
        func.sum(models.SaleItem.quantity).label('total_quantity'),
        func.sum(models.SaleItem.price_at_sale * models.SaleItem.quantity).label('total_revenue')
    ).join(
        models.SaleItem, models.SaleItem.variant_id == models.Variant.id
    ).join(
        models.Sale, models.Sale.id == models.SaleItem.sale_id
    ).join(
        models.Product, models.Product.id == models.Variant.product_id
    ).filter(
        models.Sale.organization_id == organization_id
    )
    
    if start_date:
        best_sellers = best_sellers.filter(models.Sale.created_at >= start_date)
    if end_date:
        best_sellers = best_sellers.filter(models.Sale.created_at <= end_date)
    
    best_sellers = best_sellers.group_by(
        models.Variant.id,
        models.Variant.sku,
        models.Product.name
    ).order_by(
        desc('total_quantity')
    ).limit(10).all()
    
    return {
        'total_revenue': result.total_revenue or Decimal('0'),
        'total_profit': result.total_profit or Decimal('0'),
        'total_sales_count': result.total_sales or 0,
        'best_sellers': best_sellers
    }
