from sqlalchemy.orm import Session, joinedload
from . import models, schemas, auth
from datetime import datetime, timezone

# User CRUD
def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(username=user.username, hashed_password=hashed_password, role=user.role)
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

# Product CRUD
def get_product_by_barcode(db: Session, barcode: str):
    return db.query(models.Product).filter(models.Product.barcode == barcode).first()

def get_product_by_id(db: Session, product_id: int):
    return db.query(models.Product).filter(models.Product.id == product_id).first()

def get_products(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Product).offset(skip).limit(limit).all()

def get_product_categories(db: Session):
    return db.query(models.Product.category).distinct().all()

def create_product(db: Session, product: schemas.ProductCreate) -> models.Product:
    db_product = models.Product(**product.model_dump())
    db.add(db_product)
    # The commit is now handled by the endpoint after the loop.
    return db_product

def update_product(db: Session, product: models.Product, product_in: schemas.ProductCreate) -> models.Product:
    update_data = product_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

def delete_product(db: Session, product: models.Product):
    db.delete(product)
    db.commit()
    return product

# Change Request CRUD
def create_change_request(db: Session, request: schemas.ChangeRequestCreate, user_id: int):
    db_request = models.ChangeRequest(
        product_id=request.product_id,
        action=request.action,
        quantity_change=request.quantity_change,
        buyer_name=request.buyer_name,
        payment_status=request.payment_status,
        requester_id=user_id,
        new_product_name=request.new_product_name,
        new_product_barcode=request.new_product_barcode,
        new_product_price=request.new_product_price,
        new_product_quantity=request.new_product_quantity,
        new_product_category=request.new_product_category,
    )
    db.add(db_request)
    db.commit()
    db.refresh(db_request)
    return db_request

def get_pending_change_requests(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.ChangeRequest).options(
        joinedload(models.ChangeRequest.product),
        joinedload(models.ChangeRequest.requester)
    ).filter(models.ChangeRequest.status == models.ChangeRequestStatus.pending).offset(skip).limit(limit).all()

def has_pending_product_creation_request(db: Session, barcode: str):
    """Check if there's already a pending request to create a product with the given barcode"""
    return db.query(models.ChangeRequest).filter(
        models.ChangeRequest.action == models.ChangeRequestAction.create,
        models.ChangeRequest.new_product_barcode == barcode,
        models.ChangeRequest.status == models.ChangeRequestStatus.pending
    ).first() is not None

def get_change_history(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.ChangeHistory).options(
        joinedload(models.ChangeHistory.product),
        joinedload(models.ChangeHistory.requester),
        joinedload(models.ChangeHistory.reviewer)
    ).order_by(models.ChangeHistory.timestamp.desc()).offset(skip).limit(limit).all()

def get_sales_history(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.ChangeHistory).options(
        joinedload(models.ChangeHistory.product),
        joinedload(models.ChangeHistory.requester),
        joinedload(models.ChangeHistory.reviewer)
    ).filter(
        models.ChangeHistory.action == models.ChangeRequestAction.sell,
        models.ChangeHistory.product_id.isnot(None) # Ensure product exists
    ).order_by(models.ChangeHistory.timestamp.desc()).offset(skip).limit(limit).all()

def approve_change_request(db: Session, request_id: int, reviewer_id: int):
    db_request = db.query(models.ChangeRequest).filter(models.ChangeRequest.id == request_id).first()
    if not db_request or db_request.status != models.ChangeRequestStatus.pending:
        return None

    db_product = None
    if db_request.product_id:
        db_product = db.query(models.Product).filter(models.Product.id == db_request.product_id).first()

    if db_request.action == models.ChangeRequestAction.add:
        if db_product:
            db_product.quantity += db_request.quantity_change
    elif db_request.action == models.ChangeRequestAction.sell:
        if db_product:
            if db_product.quantity < db_request.quantity_change:
                raise ValueError("Not enough stock to sell.")
            db_product.quantity -= db_request.quantity_change
    elif db_request.action == models.ChangeRequestAction.create:
        # Check if a product with this barcode already exists
        existing_product = db.query(models.Product).filter(models.Product.barcode == db_request.new_product_barcode).first()
        if existing_product:
            raise ValueError(f"A product with barcode '{db_request.new_product_barcode}' already exists.")
        
        new_product_schema = schemas.ProductCreate(
            name=db_request.new_product_name,
            barcode=db_request.new_product_barcode,
            price=db_request.new_product_price,
            quantity=db_request.new_product_quantity,
            category=db_request.new_product_category,
        )
        db_product = create_product(db, new_product_schema)
        db.commit() # Commit the new product to get an ID
        db.refresh(db_product)
    elif db_request.action == models.ChangeRequestAction.delete:
        # The product will be deleted after logging to history.
        pass
    elif db_request.action == models.ChangeRequestAction.mark_paid:
        # For mark_paid, find the specific history entry and update it
        # The product_id contains the history entry's product_id, we need to get the history ID from the request
        history_entry = None
        if db_request.product_id:
            # Find the unpaid history entry for this product
            history_entry = db.query(models.ChangeHistory).filter(
                models.ChangeHistory.product_id == db_request.product_id,
                models.ChangeHistory.payment_status == models.PaymentStatus.unpaid
            ).first()
        
        if history_entry:
            history_entry.payment_status = models.PaymentStatus.paid
            db.commit()
            db.refresh(history_entry)

    # Log to history before deleting the product
    # For create actions, use the new_product_quantity instead of quantity_change
    quantity_for_history = db_request.quantity_change
    if db_request.action == models.ChangeRequestAction.create:
        quantity_for_history = db_request.new_product_quantity
    
    history_entry = models.ChangeHistory(
        product_id=db_product.id if db_product else None,
        quantity_change=quantity_for_history,
        action=db_request.action,
        status=models.ChangeRequestStatus.approved,
        requester_id=db_request.requester_id,
        reviewer_id=reviewer_id,
        buyer_name=db_request.buyer_name,
        payment_status=db_request.payment_status
    )
    db.add(history_entry)

    # Now, if the action was 'delete', delete the product
    if db_request.action == models.ChangeRequestAction.delete:
        if db_product:
            delete_product(db, db_product)

    # Delete the original request
    db.delete(db_request)
    db.commit()
    return history_entry


def reject_change_request(db: Session, request_id: int, reviewer_id: int):
    db_request = db.query(models.ChangeRequest).filter(models.ChangeRequest.id == request_id).first()
    if not db_request or db_request.status != models.ChangeRequestStatus.pending:
        return None

    # Log to history
    history_entry = models.ChangeHistory(
        product_id=db_request.product_id,
        quantity_change=db_request.quantity_change,
        action=db_request.action,
        status=models.ChangeRequestStatus.rejected,
        requester_id=db_request.requester_id,
        reviewer_id=reviewer_id,
        buyer_name=db_request.buyer_name,
        payment_status=db_request.payment_status
    )
    db.add(history_entry)

    # Delete the original request
    db.delete(db_request)
    db.commit()
    return history_entry
