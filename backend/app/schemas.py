from pydantic import BaseModel, Field
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

    class Config:
        orm_mode = True

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

    class Config:
        orm_mode = True

# Change Request Schemas
class ChangeRequestBase(BaseModel):
    product_id: int
    action: ChangeRequestAction
    quantity_change: int

# This schema is used by the API when the user scans a barcode and wants to submit a request.
class ChangeRequestSubmit(BaseModel):
    barcode: str
    action: ChangeRequestAction
    quantity_change: int
    buyer_name: Optional[str] = None
    payment_status: Optional[str] = None

class ChangeRequestCreate(ChangeRequestBase):
    """Internal schema used when we already resolved the product_id."""
    buyer_name: Optional[str] = None
    payment_status: Optional[str] = None

class ChangeRequest(ChangeRequestCreate):
    id: int
    requester: User
    product: Product

    class Config:
        orm_mode = True

class ChangeHistory(BaseModel):
    id: int
    product: Product
    quantity_change: int
    action: ChangeRequestAction
    status: ChangeRequestStatus
    requester: User
    reviewer: User
    timestamp: datetime

    class Config:
        orm_mode = True
