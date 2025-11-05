import enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Boolean,
    ForeignKey,
    Enum,
    DECIMAL,
    Text,
    JSON,
    UniqueConstraint,
    Index,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base


# ============================================================================
# ENUMS
# ============================================================================

class UserRole(enum.Enum):
    """User roles scoped to an organization"""
    owner = "owner"
    cashier = "cashier"


class PaymentMethod(enum.Enum):
    """Payment methods for sales"""
    cash = "cash"
    card = "card"
    mobile = "mobile"
    bank_transfer = "bank_transfer"


# ============================================================================
# MULTI-TENANT MODELS
# ============================================================================

class Organization(Base):
    """
    Multi-tenant organization/business entity.
    Each organization represents a separate business with isolated data.
    """
    __tablename__ = "organizations"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    owner = relationship("User", back_populates="owned_organizations", foreign_keys=[owner_id])
    users = relationship("User", back_populates="organization", foreign_keys="User.organization_id")
    products = relationship("Product", back_populates="organization", cascade="all, delete-orphan")
    vendors = relationship("Vendor", back_populates="organization", cascade="all, delete-orphan")
    customers = relationship("Customer", back_populates="organization", cascade="all, delete-orphan")
    sales = relationship("Sale", back_populates="organization", cascade="all, delete-orphan")


class User(Base):
    """
    User model with multi-tenant support.
    A user's role is scoped to their organization.
    """
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True)
    role = Column(Enum(UserRole), default=UserRole.cashier, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    organization = relationship("Organization", back_populates="users", foreign_keys=[organization_id])
    owned_organizations = relationship("Organization", back_populates="owner", foreign_keys="Organization.owner_id")
    sales = relationship("Sale", back_populates="cashier")


# ============================================================================
# PRODUCT & INVENTORY MODELS
# ============================================================================

class Product(Base):
    """
    Base product model representing a product category.
    A product can have multiple variants (e.g., T-Shirt with different sizes/colors).
    """
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(100), index=True, nullable=True)
    is_archived = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    organization = relationship("Organization", back_populates="products")
    variants = relationship("Variant", back_populates="product", cascade="all, delete-orphan")
    
    # Index for organization-scoped queries
    __table_args__ = (
        Index('idx_products_org_id', 'organization_id'),
        Index('idx_products_org_category', 'organization_id', 'category'),
    )


class Variant(Base):
    """
    Product variant model representing a specific sellable item.
    Each variant has its own SKU, pricing, and inventory.
    """
    __tablename__ = "variants"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    sku = Column(String(100), unique=True, index=True, nullable=False)
    barcode = Column(String(100), unique=True, index=True, nullable=True)
    
    # Variant attributes stored as JSON (e.g., {"Size": "L", "Color": "Red"})
    attributes = Column(JSON, nullable=True)
    
    # Pricing
    purchase_price = Column(DECIMAL(10, 2), nullable=False, default=0)
    sale_price = Column(DECIMAL(10, 2), nullable=False)
    
    # Inventory
    quantity = Column(Integer, nullable=False, default=0)
    min_stock_level = Column(Integer, nullable=False, default=0)
    unit_type = Column(String(20), nullable=False, default='pcs')  # pcs, kg, L, etc.
    
    # Flags
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    product = relationship("Product", back_populates="variants")
    sale_items = relationship("SaleItem", back_populates="variant")
    
    # Indexes
    __table_args__ = (
        Index('idx_variants_product_id', 'product_id'),
        Index('idx_variants_barcode', 'barcode'),
        Index('idx_variants_sku', 'sku'),
    )


# ============================================================================
# VENDORS & CUSTOMERS
# ============================================================================

class Vendor(Base):
    """Vendor/Supplier model for tracking product sources"""
    __tablename__ = "vendors"
    
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False)
    name = Column(String(255), nullable=False)
    contact_person = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    organization = relationship("Organization", back_populates="vendors")
    
    __table_args__ = (
        Index('idx_vendors_org_id', 'organization_id'),
    )


class Customer(Base):
    """Customer model for tracking sales and customer relationships"""
    __tablename__ = "customers"
    
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False)
    name = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True, index=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    organization = relationship("Organization", back_populates="customers")
    sales = relationship("Sale", back_populates="customer")
    
    __table_args__ = (
        Index('idx_customers_org_id', 'organization_id'),
        Index('idx_customers_phone', 'phone'),
    )


# ============================================================================
# SALES MODELS
# ============================================================================

class Sale(Base):
    """
    Sales transaction model.
    Records a complete sale with payment details.
    """
    __tablename__ = "sales"
    
    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False)
    cashier_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    
    # Financial details
    subtotal = Column(DECIMAL(10, 2), nullable=False)
    tax = Column(DECIMAL(10, 2), nullable=False, default=0)
    discount = Column(DECIMAL(10, 2), nullable=False, default=0)
    total_amount = Column(DECIMAL(10, 2), nullable=False)
    profit = Column(DECIMAL(10, 2), nullable=False)
    
    # Payment details
    payment_method = Column(Enum(PaymentMethod), nullable=False)
    payment_proof_url = Column(String(500), nullable=True)
    
    # Metadata
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Syncing for offline sales
    synced = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    organization = relationship("Organization", back_populates="sales")
    cashier = relationship("User", back_populates="sales")
    customer = relationship("Customer", back_populates="sales")
    items = relationship("SaleItem", back_populates="sale", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_sales_org_id', 'organization_id'),
        Index('idx_sales_created_at', 'created_at'),
        Index('idx_sales_org_date', 'organization_id', 'created_at'),
    )


class SaleItem(Base):
    """
    Individual items in a sale.
    Captures the price at the time of sale for historical accuracy.
    """
    __tablename__ = "sale_items"
    
    id = Column(Integer, primary_key=True, index=True)
    sale_id = Column(Integer, ForeignKey("sales.id"), nullable=False)
    variant_id = Column(Integer, ForeignKey("variants.id"), nullable=False)
    
    quantity = Column(Integer, nullable=False)
    price_at_sale = Column(DECIMAL(10, 2), nullable=False)  # Sale price at time of transaction
    purchase_price_at_sale = Column(DECIMAL(10, 2), nullable=False)  # For profit calculation
    
    # Relationships
    sale = relationship("Sale", back_populates="items")
    variant = relationship("Variant", back_populates="sale_items")
    
    __table_args__ = (
        Index('idx_sale_items_sale_id', 'sale_id'),
        Index('idx_sale_items_variant_id', 'variant_id'),
    )
