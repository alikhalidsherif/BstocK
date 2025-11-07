from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime
from decimal import Decimal
from .models import UserRole, PaymentMethod

# ============================================================================
# TOKEN SCHEMAS
# ============================================================================

class Token(BaseModel):
    access_token: str
    token_type: str
    organization_id: Optional[int] = None
    role: Optional[str] = None


class TokenData(BaseModel):
    username: Optional[str] = None
    organization_id: Optional[int] = None


# ============================================================================
# ORGANIZATION SCHEMAS
# ============================================================================

class OrganizationBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)


class OrganizationCreate(OrganizationBase):
    pass


class Organization(OrganizationBase):
    id: int
    owner_id: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# USER SCHEMAS
# ============================================================================

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=255)
    role: UserRole


class UserCreate(UserBase):
    password: str = Field(..., min_length=6)
    organization_id: Optional[int] = None


class User(UserBase):
    id: int
    organization_id: Optional[int]
    is_active: bool
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None
    organization_id: Optional[int] = None


# ============================================================================
# PRODUCT & VARIANT SCHEMAS
# ============================================================================

class VariantBase(BaseModel):
    sku: str = Field(..., min_length=1, max_length=100)
    barcode: Optional[str] = Field(None, max_length=100)
    attributes: Optional[Dict[str, Any]] = None
    purchase_price: Decimal = Field(..., ge=0)
    sale_price: Decimal = Field(..., ge=0)
    quantity: int = Field(..., ge=0)
    min_stock_level: int = Field(default=0, ge=0)
    unit_type: str = Field(default='pcs', max_length=20)
    is_active: bool = True


class VariantCreate(VariantBase):
    product_id: Optional[int] = None


class VariantUpdate(BaseModel):
    sku: Optional[str] = None
    barcode: Optional[str] = None
    attributes: Optional[Dict[str, Any]] = None
    purchase_price: Optional[Decimal] = None
    sale_price: Optional[Decimal] = None
    quantity: Optional[int] = None
    min_stock_level: Optional[int] = None
    unit_type: Optional[str] = None
    is_active: Optional[bool] = None


class Variant(VariantBase):
    id: int
    product_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    category: Optional[str] = Field(None, max_length=100)


class ProductCreate(ProductBase):
    variants: List[VariantCreate] = Field(default_factory=list)


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    is_archived: Optional[bool] = None


class Product(ProductBase):
    id: int
    organization_id: int
    is_archived: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    variants: List[Variant] = []
    
    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# VENDOR & CUSTOMER SCHEMAS
# ============================================================================

class VendorBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None


class VendorCreate(VendorBase):
    pass


class Vendor(VendorBase):
    id: int
    organization_id: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class CustomerBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None


class CustomerCreate(CustomerBase):
    pass


class Customer(CustomerBase):
    id: int
    organization_id: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# SALES SCHEMAS
# ============================================================================

class SaleItemInput(BaseModel):
    """Input schema for creating a sale item"""
    variant_id: int
    quantity: int = Field(..., gt=0)


class SaleItemBase(BaseModel):
    variant_id: int
    quantity: int
    price_at_sale: Decimal
    purchase_price_at_sale: Decimal


class SaleItem(SaleItemBase):
    id: int
    sale_id: int
    variant: Optional[Variant] = None
    
    model_config = ConfigDict(from_attributes=True)


class SaleBase(BaseModel):
    payment_method: PaymentMethod
    customer_id: Optional[int] = None
    notes: Optional[str] = None
    tax: Decimal = Field(default=Decimal('0'), ge=0)
    discount: Decimal = Field(default=Decimal('0'), ge=0)


class SaleCreate(SaleBase):
    """Schema for creating a new sale"""
    items: List[SaleItemInput] = Field(..., min_length=1)


class Sale(SaleBase):
    id: int
    organization_id: int
    cashier_id: int
    subtotal: Decimal
    total_amount: Decimal
    profit: Decimal
    payment_proof_url: Optional[str] = None
    synced: bool
    created_at: datetime
    items: List[SaleItem] = []
    
    model_config = ConfigDict(from_attributes=True)


class SaleWithDetails(Sale):
    """Extended sale schema with full details for receipts"""
    cashier: Optional[User] = None
    customer: Optional[Customer] = None


# ============================================================================
# ANALYTICS SCHEMAS
# ============================================================================

class BestSellingVariant(BaseModel):
    variant_id: int
    sku: str
    product_name: str
    total_quantity_sold: int
    total_revenue: Decimal


class AnalyticsSummary(BaseModel):
    total_revenue: Decimal
    total_profit: Decimal
    total_sales_count: int
    best_selling_variants: List[BestSellingVariant]


# ============================================================================
# ONBOARDING SCHEMAS
# ============================================================================

class OnboardingRequest(BaseModel):
    """Schema for initial organization and user setup"""
    organization_name: str = Field(..., min_length=1, max_length=255)
    username: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=6)


class OnboardingResponse(BaseModel):
    access_token: str
    token_type: str
    organization: Organization
    user: User
