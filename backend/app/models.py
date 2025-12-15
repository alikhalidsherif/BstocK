import enum
from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    DateTime,
    Boolean,
    ForeignKey,
    Enum,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
from .config import settings
import datetime

class UserRole(enum.Enum):
    clerk = "clerk"
    admin = "admin"
    supervisor = "supervisor"

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.clerk, nullable=False)
    is_active = Column(Boolean, default=True)

    # This relationship links a user to the change requests they have submitted.
    change_requests = relationship(
        "ChangeRequest",
        foreign_keys="[ChangeRequest.requester_id]",
        back_populates="requester",
        passive_deletes=True,
    )

    @property
    def is_master(self) -> bool:
        return self.username == settings.MASTER_USERNAME

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    barcode = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    price = Column(Float, nullable=False)
    quantity = Column(Integer, nullable=False)
    category = Column(String, index=True)
    is_archived = Column(Boolean, default=False, nullable=False)

    change_requests = relationship("ChangeRequest", back_populates="product")
    history_entries = relationship("ChangeHistory", back_populates="product")


class ChangeRequestStatus(enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"

class ChangeRequestAction(enum.Enum):
    add = "add"
    update = "update"
    sell = "sell"
    create = "create"
    archive = "archive"
    restore = "restore"
    delete = "delete"
    mark_paid = "mark_paid"

class PaymentStatus(enum.Enum):
    paid = "paid"
    unpaid = "unpaid"

class ChangeRequest(Base):
    __tablename__ = "change_requests"
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=True) # Can be null for 'create'
    requester_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    approver_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    action = Column(Enum(ChangeRequestAction), nullable=False)
    quantity_change = Column(Integer, nullable=True) # Now nullable
    # Optional link to a specific history entry (used for mark_paid workflow)
    history_id = Column(Integer, nullable=True)
    
    # Fields specific to 'sell' actions
    buyer_name = Column(String, nullable=True)
    payment_status = Column(Enum(PaymentStatus), nullable=True)
    
    # Fields for create/update requests
    new_product_name = Column(String, nullable=True)
    new_product_barcode = Column(String, nullable=True)
    new_product_price = Column(Float, nullable=True)
    new_product_quantity = Column(Integer, nullable=True)
    new_product_category = Column(String, nullable=True)
    
    status = Column(
        Enum(ChangeRequestStatus), default=ChangeRequestStatus.pending, nullable=False
    )
    request_date = Column(DateTime(timezone=True), server_default=func.now())
    approval_date = Column(DateTime(timezone=True), nullable=True)

    product = relationship("Product", back_populates="change_requests")
    requester = relationship(
        "User",
        back_populates="change_requests",
        foreign_keys=[requester_id],
        passive_deletes=True,
    )
    approver = relationship(
        "User",
        foreign_keys=[approver_id],
        passive_deletes=True,
    )

class ChangeHistory(Base):
    __tablename__ = "change_history"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    quantity_change = Column(Integer, nullable=True) # Now nullable
    action = Column(Enum(ChangeRequestAction), nullable=False)
    status = Column(Enum(ChangeRequestStatus), nullable=False) # approved or rejected
    requester_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    reviewer_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    timestamp = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # Fields to store details from the original request
    buyer_name = Column(String, nullable=True)
    payment_status = Column(Enum(PaymentStatus), nullable=True)

    product = relationship("Product", back_populates="history_entries")
    requester = relationship(
        "User",
        foreign_keys=[requester_id],
        passive_deletes=True,
    )
    reviewer = relationship(
        "User",
        foreign_keys=[reviewer_id],
        passive_deletes=True,
    )
