from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from datetime import datetime
from .models import UserRole, ChangeRequestStatus, ChangeRequestAction, PaymentStatus

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# User Schemas
class UserBase(BaseModel):
    username: str
    role: UserRole

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)

class UserUpdate(BaseModel):
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None

# Product Schemas
class ProductBase(BaseModel):
    barcode: str
    name: str
    price: float
    quantity: int
    category: str

class ProductCreate(ProductBase):
    pass

class Product(ProductBase):
    id: int
    is_archived: bool

    model_config = ConfigDict(from_attributes=True)

# Change Request Schemas
class ChangeRequestBase(BaseModel):
    product_id: Optional[int] = None
    action: ChangeRequestAction
    quantity_change: Optional[int] = None

# This schema is used by the API when the user scans a barcode and wants to submit a request.
class ChangeRequestSubmit(BaseModel):
    barcode: Optional[str] = None
    action: ChangeRequestAction
    quantity_change: Optional[int] = None
    buyer_name: Optional[str] = None
    payment_status: Optional[PaymentStatus] = None
    new_product_name: Optional[str] = None
    new_product_barcode: Optional[str] = None
    new_product_price: Optional[float] = None
    new_product_quantity: Optional[int] = None
    new_product_category: Optional[str] = None

class ChangeRequestCreate(ChangeRequestBase):
    """Internal schema used when we already resolved the product_id."""
    buyer_name: Optional[str] = None
    payment_status: Optional[PaymentStatus] = None
    new_product_name: Optional[str] = None
    new_product_barcode: Optional[str] = None
    new_product_price: Optional[float] = None
    new_product_quantity: Optional[int] = None
    new_product_category: Optional[str] = None
    history_id: Optional[int] = None

class ChangeRequest(ChangeRequestCreate):
    id: int
    requester: User
    product: Optional[Product] = None
    history_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)

class ChangeHistory(BaseModel):
    id: int
    product: Optional[Product] = None
    quantity_change: Optional[int] = None
    action: ChangeRequestAction
    status: ChangeRequestStatus
    requester: User
    reviewer: User
    timestamp: datetime
    buyer_name: Optional[str] = None
    payment_status: Optional[PaymentStatus] = None

    model_config = ConfigDict(from_attributes=True)
