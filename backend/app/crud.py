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
        requester_id=user_id
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

def get_change_history(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.ChangeHistory).options(
        joinedload(models.ChangeHistory.product),
        joinedload(models.ChangeHistory.requester),
        joinedload(models.ChangeHistory.reviewer)
    ).order_by(models.ChangeHistory.timestamp.desc()).offset(skip).limit(limit).all()

def approve_change_request(db: Session, request_id: int, reviewer_id: int):
    db_request = db.query(models.ChangeRequest).filter(models.ChangeRequest.id == request_id).first()
    if not db_request or db_request.status != models.ChangeRequestStatus.pending:
        return None

    # Update product quantity
    db_product = db.query(models.Product).filter(models.Product.id == db_request.product_id).first()
    if db_request.action == models.ChangeRequestAction.add:
        db_product.quantity += db_request.quantity_change
    elif db_request.action == models.ChangeRequestAction.sell:
        if db_product.quantity < db_request.quantity_change:
            raise ValueError("Not enough stock to sell.")
        db_product.quantity -= db_request.quantity_change

    # Log to history
    history_entry = models.ChangeHistory(
        product_id=db_request.product_id,
        quantity_change=db_request.quantity_change,
        action=db_request.action,
        status=models.ChangeRequestStatus.approved,
        requester_id=db_request.requester_id,
        reviewer_id=reviewer_id
    )
    db.add(history_entry)

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
        reviewer_id=reviewer_id
    )
    db.add(history_entry)

    # Delete the original request
    db.delete(db_request)
    db.commit()
    return history_entry
